#!/bin/bash
#
# Copyright (C) 2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=X00QD
VENDOR=asus

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/dot/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction

# Load camera shim
CAMERA_SHIM="$COMMON_BLOB_ROOT"/vendor/lib/libmms_hal_vstab.so
patchelf --add-needed libmms_hal_vstab_shim.so "$CAMERA_SHIM"

function blob_fixup() {
    case "${1}" in

    lib64/libwfdnative.so)
        patchelf --add-needed "libshim_wfdservice.so" "${2}"
        ;;
    
    lib/libwfdcommonutils.so)
        patchelf --add-needed "libshim_wfdservice.so" "${2}"
        ;;
    
    lib/libwfdmmsrc.so)
        patchelf --add-needed "libshim_wfdservice.so" "${2}"
        ;;

    product/lib64/libdpmframework.so)
        patchelf --add-needed libcutils_shim.so "${2}"
        ;;

    esac
}

CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"

"$MY_DIR"/setup-makefiles.sh
