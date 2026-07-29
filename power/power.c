/*
 * Copyright (C) 2016 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#define LOG_TAG "PowerHAL"

#include <hardware/hardware.h>
#include <hardware/power.h>

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>

#include <utils/Log.h>

/*
 * CATATAN: dukungan double-tap-to-wake dibuang dari HAL ini.
 *
 * set_feature() dulu menulis state ke /sys/android_touch/doubletap2wake, tapi
 * node itu tidak pernah ada di perangkat ini: string "doubletap2wake" maupun
 * "android_touch" nol hasil di seluruh pohon kernel_oppo_msm8939. Driver touch
 * di kernel ini memang tidak punya dukungan DT2W sama sekali.
 *
 * Selain itu framework pun tidak pernah memanggilnya: overlay device ini tidak
 * menyetel config_supportsDoubleTapWake, jadi toggle-nya tidak muncul di
 * Settings dan setFeature tidak pernah dipicu.
 *
 * android.hardware.power@1.0-impl memeriksa pointer setFeature sebelum
 * memanggilnya, jadi membiarkannya NULL aman.
 *
 * Kalau suatu saat DT2W di-port ke driver touch kernel, kembalikan set_feature
 * beserta helper sysfs_write_str()/sysfs_write_int() yang ikut dibuang di sini
 * karena tidak ada lagi yang memakainya.
 */

static void power_init(__attribute__((unused)) struct power_module *module)
{
    ALOGI("%s", __func__);
}

static int power_open(const hw_module_t* module, const char* name,
                    hw_device_t** device)
{
    ALOGD("%s: enter; name=%s", __FUNCTION__, name);

    if (strcmp(name, POWER_HARDWARE_MODULE_ID)) {
        return -EINVAL;
    }

    power_module_t *dev = (power_module_t *)calloc(1,
            sizeof(power_module_t));

    if (!dev) {
        ALOGD("%s: failed to allocate memory", __FUNCTION__);
        return -ENOMEM;
    }

    dev->common.tag = HARDWARE_MODULE_TAG;
    dev->common.module_api_version = POWER_MODULE_API_VERSION_0_2;
    dev->common.hal_api_version = HARDWARE_HAL_API_VERSION;

    dev->init = power_init;
    *device = (hw_device_t*)dev;

    ALOGD("%s: exit", __FUNCTION__);

    return 0;
}

static struct hw_module_methods_t power_module_methods = {
    .open = power_open,
};

struct power_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = POWER_MODULE_API_VERSION_0_2,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = POWER_HARDWARE_MODULE_ID,
        .name = "msm8916 Power HAL",
        .author = "The LineageOS Project",
        .methods = &power_module_methods,
    },

    .init = power_init

};