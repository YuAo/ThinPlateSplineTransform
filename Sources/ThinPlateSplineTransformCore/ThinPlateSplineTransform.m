//
//  ThinPlateSplineShapeTransformer.m
//
//  Created by YuAo on 2020/2/18.
//

#import "ThinPlateSplineTransform.h"
#import <memory.h>
#import <assert.h>
#import <Accelerate/Accelerate.h>

typedef struct _ThinPlateSplineTransform {
    simd_float2 *_sourcePoints;
    float *_tpsParameters;
    simd_float3x2 _affineTransform;
    size_t _pointCount;
    
    float *_tempDistanceBuffer;
    float *_tempPointBuffer;
} _ThinPlateSplineTransform;

static inline float tpsDistance(simd_float2 p, simd_float2 q) {
    simd_float2 diff = p - q;
    simd_float2 d = diff * diff;
    float norma = d.x + d.y;
    norma = norma * log(norma+FLT_EPSILON);
    return norma;
}

static inline simd_float2 tpsTransform(simd_float2 point, simd_float2 *sourcePoints, size_t pointCount, float *tpsParameters, simd_float3x2 affineTransform, float *distanceBuffer, float *pointBuffer) {
    simd_float2 output = simd_mul(affineTransform, simd_make_float3(point, 1)).xy;
    size_t tpsColumnStride = pointCount + 3;
    if (pointCount > 128 && distanceBuffer != NULL && pointBuffer != NULL) {
        // use vecLib
        float *distances = distanceBuffer;
        float *t = pointBuffer;
        float *source = (float *)sourcePoints;
        
        // diff = sourcePoint - point;
        float x = -point.x;
        vDSP_vsadd(source, 2, &x, t, 2, pointCount);
        float y = -point.y;
        vDSP_vsadd(&source[1], 2, &y, &t[1], 2, pointCount);
        
        // d = diff * diff
        vDSP_vmul(t, 1, t, 1, t, 1, pointCount * 2);
        
        // norma = d.x + d.y
        vDSP_vadd(t, 2, &t[1], 2, distances, 1, pointCount);
        
        // log(norma+FLT_EPSILON);
        float epsilon = FLT_EPSILON;
        vDSP_vsadd(distances, 1, &epsilon, distances, 1, pointCount);
        const int n = (int)pointCount;
        vvlogf(t, distances, &n);
        
        // norma = norma * log(norma+FLT_EPSILON);
        vDSP_vmul(t, 1, distances, 1, distances, 1, pointCount);
        
        float nonrigidX = 0;
        vDSP_dotpr(tpsParameters, 1, distances, 1, &nonrigidX, pointCount);
        float nonrigidY = 0;
        vDSP_dotpr(&tpsParameters[tpsColumnStride], 1, distances, 1, &nonrigidY, pointCount);
        
        output.x += nonrigidX;
        output.y += nonrigidY;
    } else {
        // use for loop
        for (size_t i = 0; i < pointCount; i += 1) {
            float d = tpsDistance(sourcePoints[i], point);
            output.x += tpsParameters[i] * d;
            output.y += tpsParameters[tpsColumnStride + i] * d;
        }
    }
    return output;
}

_Nullable ThinPlateSplineTransformRef ThinPlateSplineTransformCreate(const simd_float2 *sourcePoints, const simd_float2 *targetPoints, size_t count, float regularizationParameter) {
    assert(count > 0);
    
    // Using LAPACK here. Matrix is Column-Major.
    float * matL = calloc((count + 3) * (count + 3), sizeof(float));
    
    for (size_t i = 0; i < count; i += 1) {
        for (size_t j = 0; j < count; j += 1) {
            if (i == j) {
                matL[i * (count + 3) + j] = regularizationParameter;
            } else {
                matL[i * (count + 3) + j] = tpsDistance(sourcePoints[i], sourcePoints[j]);
            }
        }
        
        matL[i * (count + 3) + (count)] = 1;
        matL[i * (count + 3) + (count) + 1] = sourcePoints[i].x;
        matL[i * (count + 3) + (count) + 2] = sourcePoints[i].y;
        
        matL[(count + 0) * (count + 3) + i] = 1;
        matL[(count + 1) * (count + 3) + i] = sourcePoints[i].x;
        matL[(count + 2) * (count + 3) + i] = sourcePoints[i].y;
    }
    
    float * matB = calloc((count + 3) * 2, sizeof(float));
    for (size_t i = 0; i < count; i += 1) {
        matB[i] = targetPoints[i].x;
        matB[count + 3 + i] = targetPoints[i].y;
    }
    
    __CLPK_integer n = (__CLPK_integer)(count + 3);
    __CLPK_integer nrhs = 2;
    __CLPK_integer lda = n;
    __CLPK_integer ldb = n;
    __CLPK_integer *ipiv = malloc(sizeof(__CLPK_integer) * (unsigned long)n);
    __CLPK_integer info;
    __CLPK_real optimumWorkSizeFloat = 0;
    __CLPK_integer getOptimumWorkSize = -1;
    ssysv_("U", &n, &nrhs, matL, &lda, ipiv, matB, &ldb, &optimumWorkSizeFloat, &getOptimumWorkSize, &info);
    if (info != 0) {
        printf("ThinPlateSplineShapeTransform: Could not find optimum workspace size. Status is: %ld", (long)info);
        free(ipiv);
        free(matL);
        free(matB);
        return NULL;
    }
    
    __CLPK_integer optimumWorkSize = optimumWorkSizeFloat;
    __CLPK_real *workspace = malloc((unsigned long)optimumWorkSize * sizeof(__CLPK_real));
    ssysv_("U", &n, &nrhs, matL, &lda, ipiv, matB, &ldb, workspace, &optimumWorkSize, &info);
    if (info != 0) {
        printf("ThinPlateSplineShapeTransform: Could not solve for X. Status is: %ld", (long)info);
        free(workspace);
        free(ipiv);
        free(matL);
        free(matB);
        return NULL;
    }
    
    free(workspace);
    free(ipiv);
    free(matL);
    
    ThinPlateSplineTransformRef transform = malloc(sizeof(_ThinPlateSplineTransform));
    transform -> _pointCount = count;
    transform -> _sourcePoints = malloc(count * sizeof(simd_float2));
    memcpy(transform -> _sourcePoints, sourcePoints, count * sizeof(simd_float2));
    transform -> _tpsParameters = matB;
    transform -> _affineTransform = simd_matrix_from_rows(simd_make_float3(matB[count + 1],
                                                              matB[count + 2],
                                                              matB[count]),
                                             simd_make_float3(matB[count + 3 + count + 1],
                                                              matB[count + 3 + count + 2],
                                                              matB[count + 3 + count]));
    transform -> _tempDistanceBuffer = malloc(sizeof(float) * count);
    transform -> _tempPointBuffer = malloc(sizeof(float) * count * 2);
    return transform;
}

void ThinPlateSplineTransformRelease(ThinPlateSplineTransformRef transform) {
    free(transform -> _sourcePoints);
    free(transform -> _tpsParameters);
    free(transform -> _tempDistanceBuffer);
    free(transform -> _tempPointBuffer);
    free(transform);
}

simd_float2 ThinPlateSplineTransformApplyToPoint(ThinPlateSplineTransformRef transform, simd_float2 point) {
    return tpsTransform(point, transform -> _sourcePoints, transform -> _pointCount, transform -> _tpsParameters, transform -> _affineTransform, transform -> _tempDistanceBuffer, transform -> _tempPointBuffer);
}
