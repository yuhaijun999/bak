#pragma once

#include <cstddef>

namespace hnswlib {

using FVEC_L2SQR_HOOK = float (*)(const float *, const float *, size_t);

using FVEC_INNER_PRODUCT_HOOK = float (*)(const float *, const float *, size_t);

#if __cplusplus >= 201703L
inline FVEC_L2SQR_HOOK fvec_L2sqr_hook = nullptr;
inline FVEC_INNER_PRODUCT_HOOK fvec_inner_product_hook = nullptr;

inline float fvec_L2sqr_hook_internal(const void *pVect1v, const void *pVect2v, const void *qty_ptr) {
    const float *pVect1 = reinterpret_cast<const float *>(pVect1v);
    const float *pVect2 = reinterpret_cast<const float *>(pVect2v);
    size_t qty = *(reinterpret_cast<size_t *>(const_cast<void *>(qty_ptr)));
    return fvec_L2sqr_hook(pVect1, pVect2, qty);
}

inline float fvec_inner_product_distance_hook_internal(const void *pVect1v, const void *pVect2v, const void *qty_ptr) {
    const float *pVect1 = reinterpret_cast<const float *>(pVect1v);
    const float *pVect2 = reinterpret_cast<const float *>(pVect2v);
    size_t qty = *(reinterpret_cast<size_t *>(const_cast<void *>(qty_ptr)));
    return 1.0f - fvec_inner_product_hook(pVect1, pVect2, qty);
}
#endif

#if __cplusplus < 201703L
#if defined(_WIN32) || defined(WIN32) || defined(_WIN64) || defined(WIN64)
#pragma message("hook set  ignore . C++17 or higher is required.")
#else
#warning hook set  ignore . C++17 or higher is required.
#endif
#endif

template <typename MTYPE>
using DISTFUNC = MTYPE (*)(const void *, const void *, const void *);

inline DISTFUNC<float> get_fvec_L2sqr_hook_internal() {
#if __cplusplus >= 201703L
    return fvec_L2sqr_hook_internal;
#else
    return nullptr;
#endif
}

inline DISTFUNC<float> get_fvec_inner_product_distance_hook_internal() {
#if __cplusplus >= 201703L
    return fvec_inner_product_distance_hook_internal;
#else
    return nullptr;
#endif
}
// The following external interface
inline void set_fvec_L2sqr_hook(FVEC_L2SQR_HOOK hook) {
#if __cplusplus >= 201703L
    if (nullptr != hook) fvec_L2sqr_hook = hook;
#endif
}

inline FVEC_L2SQR_HOOK get_fvec_L2sqr_hook() {
#if __cplusplus >= 201703L
    return fvec_L2sqr_hook;
#else
    return nullptr;
#endif
}

inline void set_fvec_inner_product_hook(FVEC_INNER_PRODUCT_HOOK hook) {
#if __cplusplus >= 201703L
    if (nullptr != hook) fvec_inner_product_hook = hook;
#endif
}

inline FVEC_INNER_PRODUCT_HOOK get_fvec_inner_product_hook() {
#if __cplusplus >= 201703L
    return fvec_inner_product_hook;
#else
    return nullptr;
#endif
}

}  // namespace hnswlib
