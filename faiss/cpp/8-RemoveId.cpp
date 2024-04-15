/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <cstdio>
#include <random>
#include <vector>
#include "faiss/impl/FaissAssert.h"

#include <faiss/IndexFlat.h>
#include <faiss/IndexIDMap.h>

// 64-bit int
using idx_t = faiss::idx_t;

int main() {
    int d = 8;   // dimension
    int nb = 10; // database size

    std::mt19937 rng;
    std::uniform_real_distribution<> distrib;

    float* xb = new float[d * nb];

    for (int i = 0; i < nb; i++) {
        for (int j = 0; j < d; j++)
            xb[d * i + j] = distrib(rng);
        xb[d * i] += i / 1000.;
    }

    faiss::IndexFlatL2 index(d);
    faiss::IndexIDMap2 index_id_map2(&index);
    idx_t* xids = new idx_t[nb]();

    // data map
    // [0,  1,  2,  3,  4,  5,  6,  7,  8,  9]
    // [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
    // [0->10,  1->11,  2->12,  3->13,  4->14,  5->15,  6->16,  7->17,  8->18,
    // 9->19]
    for (int i = 0; i < nb; i++) {
        xids[i] = nb + i;
    }

    // test 1  // delete head
    {
        index_id_map2.add_with_ids(nb, xb, xids);

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }
        printf("ntotal = %zd\n", index_id_map2.ntotal);

        // delete head
        {
            std::vector<idx_t> ids{10, 11};
            faiss::IDSelectorArray sel{ids.size(), ids.data()};
            index_id_map2.remove_ids(sel);
        }

        auto rev_map_1 = index_id_map2.rev_map;

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }

        // construct_rev_map
        { index_id_map2.construct_rev_map(); }

        auto rev_map_2 = index_id_map2.rev_map;

        FAISS_ASSERT(rev_map_1 == rev_map_2);
        printf("compare equal\n\n");

        index_id_map2.reset();
    }

    // test 2  // delete tail
    {
        index_id_map2.add_with_ids(nb, xb, xids);

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }
        printf("ntotal = %zd\n", index_id_map2.ntotal);

        // delete tail
        {
            std::vector<idx_t> ids{18, 19};
            faiss::IDSelectorArray sel{ids.size(), ids.data()};
            index_id_map2.remove_ids(sel);
        }

        auto rev_map_1 = index_id_map2.rev_map;

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }

        // construct_rev_map
        { index_id_map2.construct_rev_map(); }

        auto rev_map_2 = index_id_map2.rev_map;

        FAISS_ASSERT(rev_map_1 == rev_map_2);
        printf("compare equal\n\n");

        index_id_map2.reset();
    }

    // test 3  // delete middle  continuous
    {
        index_id_map2.add_with_ids(nb, xb, xids);

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }
        printf("ntotal = %zd\n", index_id_map2.ntotal);

        // delete middle  continuous
        {
            std::vector<idx_t> ids{15, 16, 17};
            faiss::IDSelectorArray sel{ids.size(), ids.data()};
            index_id_map2.remove_ids(sel);
        }

        auto rev_map_1 = index_id_map2.rev_map;

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }

        // construct_rev_map
        { index_id_map2.construct_rev_map(); }

        auto rev_map_2 = index_id_map2.rev_map;

        FAISS_ASSERT(rev_map_1 == rev_map_2);
        printf("compare equal\n\n");

        index_id_map2.reset();
    }

    // test 4  // delete middle  not continuous
    {
        index_id_map2.add_with_ids(nb, xb, xids);

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }
        printf("ntotal = %zd\n", index_id_map2.ntotal);

        // delete middle  not continuous
        {
            std::vector<idx_t> ids{12, 14, 17};
            faiss::IDSelectorArray sel{ids.size(), ids.data()};
            index_id_map2.remove_ids(sel);
        }

        auto rev_map_1 = index_id_map2.rev_map;

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }

        // construct_rev_map
        { index_id_map2.construct_rev_map(); }

        auto rev_map_2 = index_id_map2.rev_map;

        FAISS_ASSERT(rev_map_1 == rev_map_2);
        printf("compare equal\n\n");

        index_id_map2.reset();
    }

    // test 5  // delete head to tail
    {
        index_id_map2.add_with_ids(nb, xb, xids);

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }
        printf("ntotal = %zd\n", index_id_map2.ntotal);

        // delete head to tail
        {
            std::vector<idx_t> ids{10, 14, 19};
            faiss::IDSelectorArray sel{ids.size(), ids.data()};
            index_id_map2.remove_ids(sel);
        }

        auto rev_map_1 = index_id_map2.rev_map;

        for (const auto& [xid, index] : index_id_map2.rev_map) {
            printf("xid=%zd, index=%zd\n", xid, index);
        }

        // construct_rev_map
        { index_id_map2.construct_rev_map(); }

        auto rev_map_2 = index_id_map2.rev_map;

        FAISS_ASSERT(rev_map_1 == rev_map_2);
        printf("compare equal\n\n");

        index_id_map2.reset();
    }

    delete[] xids;
    delete[] xb;
    return 0;
}
