/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <random>

#include <faiss/IndexFlat.h>
#include <faiss/IndexIDMap.h>
#include <faiss/impl/AuxIndexStructures.h>
#include <faiss/impl/IDSelector.h>

// 64-bit int
using idx_t = faiss::idx_t;

int main() {
    int d = 64;     // dimension
    int nb = 10000; // database size
    int nq = 5;     // nb of queries

    std::mt19937 rng;
    std::uniform_real_distribution<> distrib;

    float* xb = new float[d * nb];
    float* xq = new float[d * nq];

    for (int i = 0; i < nb; i++) {
        for (int j = 0; j < d; j++)
            xb[d * i + j] = distrib(rng);
        xb[d * i] += i / 1000.;
    }

    for (int i = 0; i < nq; i++) {
        for (int j = 0; j < d; j++)
            xq[d * i + j] = distrib(rng);
        xq[d * i] += i / 1000.;
    }

    faiss::IndexFlatL2 index(d);
    faiss::IndexIDMap2 index_id_map2(&index);

    idx_t* xids = new idx_t[nb]();
    for (int i = 0; i < nb; i++) {
        xids[i] = i + nb;
    }

    index_id_map2.add_with_ids(nb, xb, xids);

    faiss::SearchParameters params;

    std::vector<faiss::idx_t> ids;
    ids.reserve(nb / 2);
    for (faiss::idx_t i = 0; i < nb / 2; i++) {
        ids.push_back(i + nb);
    }

    faiss::IDSelectorArray id_selector_array(ids.size(), ids.data());

    params.sel = &id_selector_array;

    // range search with param
    {
        float radius = 7.0f;
        faiss::RangeSearchResult* result = new faiss::RangeSearchResult(nq);

        index_id_map2.range_search(nq, xb, radius, result, &params);

        size_t off = 0;
        for (size_t i = 0; i < result->nq; i++) {
            size_t n = (result->lims[i + 1] - result->lims[i]);
            std::cout << "i : " << i << std::endl;
            for (size_t j = 0; j < n; j++) {
                std::cout << "\t label : " << result->labels[off + j]
                          << " distance : " << result->distances[off + j]
                          << std::endl;
            }
            off += n;
        }

        delete result;
    }

    delete[] xb;
    delete[] xq;
    delete[] xids;

    return 0;
}
