#!/usr/bin/env bash

cd openfhe

FILES=(
    "src/core/include/lattice/hal/default/dcrtpoly.h"
    "src/core/include/lattice/hal/default/ildcrtparams.h"
    "src/core/include/lattice/hal/default/dcrtpoly.h"
    "src/core/include/lattice/hal/default/poly.h"
    "src/core/include/lattice/hal/elemparams.h"
    "src/core/include/math/hal/intnat/mubintvecnat.h"
    "src/core/include/math/hal/intnat/ubintnat.h"
    "src/pke/include/ciphertext.h"
    "src/pke/include/cryptocontext.h"
    "src/pke/include/encoding/plaintext.h"
    "src/pke/include/key/evalkeyrelin.h"
    
    "src/pke/include/schemebase/base-cryptoparameters.h"
    "src/pke/include/schemerns/rns-cryptoparameters.h"
)

for file in "${FILES[@]}"; do
    if [ -f "${file}" ]; then
        sed -i 's/protected:/public:/' ${file}
        sed -i 's/private:/public:/' ${file}
    else
        echo "Warning: ${file} does not exist"
    fi
done

git diff > ../patches/private_protected_to_public.patch
