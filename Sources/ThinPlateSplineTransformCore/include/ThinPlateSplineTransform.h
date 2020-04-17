//
//  ThinPlateSplineShapeTransformer.h
//
//  Created by YuAo on 2020/2/18.
//
#import <simd/simd.h>

#if defined(__cplusplus)
#define THIN_PLATE_SPLINE_TRANSFORM_EXTERN extern "C"
#else
#define THIN_PLATE_SPLINE_TRANSFORM_EXTERN extern
#endif

typedef struct _ThinPlateSplineTransform * ThinPlateSplineTransformRef;

THIN_PLATE_SPLINE_TRANSFORM_EXTERN _Nullable ThinPlateSplineTransformRef ThinPlateSplineTransformCreate(const simd_float2 * _Nonnull sourcePoints, const simd_float2 * _Nonnull targetPoints, size_t count, float regularizationParameter);
THIN_PLATE_SPLINE_TRANSFORM_EXTERN void ThinPlateSplineTransformRelease(_Nonnull ThinPlateSplineTransformRef transform);
THIN_PLATE_SPLINE_TRANSFORM_EXTERN simd_float2 ThinPlateSplineTransformApplyToPoint(_Nonnull ThinPlateSplineTransformRef transform, simd_float2 point);
