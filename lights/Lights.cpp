/*
 * Copyright (C) 2018 The LineageOS Project
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

#define LOG_TAG "android.hardware.light-service.oppo_msm8916"

#include "Lights.h"

#include <android-base/logging.h>
#include <android-base/stringprintf.h>

#include <fstream>

namespace aidl {
namespace android {
namespace hardware {
namespace light {

// id ini juga indeks di getLights(); dipakai langsung oleh setLightState.
enum LightId : int32_t {
    kIdBacklight = 0,
    kIdButtons = 1,
    kIdAttention = 2,
    kIdNotifications = 3,
};

/*
 * Tulis nilai ke path lalu tutup berkas.
 */
template <typename T>
static void set(const std::string& path, const T& value) {
    std::ofstream file(path);
    file << value;
}

static int rgbToBrightness(const HwLightState& state) {
    int color = state.color & 0x00ffffff;
    return ((77 * ((color >> 16) & 0x00ff)) + (150 * ((color >> 8) & 0x00ff)) +
            (29 * (color & 0x00ff))) >>
           8;
}

Lights::Lights() {
    for (auto& state : mLightStates) {
        state = HwLightState();
    }
}

void Lights::handleWhiteLed(const HwLightState& state, size_t index) {
    mLightStates.at(index) = state;

    HwLightState stateToUse = mLightStates.front();
    for (const auto& lightState : mLightStates) {
        if (lightState.color & 0xffffff) {
            stateToUse = lightState;
            break;
        }
    }

    int brightness = rgbToBrightness(stateToUse);
    static const char* const kLedFiles[] = {
            "/sys/class/leds/red/brightness",
            "/sys/class/leds/green/brightness",
            "/sys/class/leds/blue/brightness",
    };

    for (size_t i = 0; i < sizeof(kLedFiles) / sizeof(kLedFiles[0]); i++) {
        set(kLedFiles[i], brightness);
    }

    int onMs = stateToUse.flashMode == FlashMode::TIMED ? stateToUse.flashOnMs : 0;
    int offMs = stateToUse.flashMode == FlashMode::TIMED ? stateToUse.flashOffMs : 0;
    bool blink = onMs > 0 && offMs > 0;

    if (blink) {
        int totalMs = onMs + offMs;

        // LED berkedip kira-kira sekali per detik bila freq bernilai 20.
        // 1000ms / 20 = 50
        int freq = totalMs / 50;
        // pwm menentukan rasio ON terhadap OFF
        // pwm = 0   -> selalu mati
        // pwm = 255 -> selalu menyala
        int pwm = (onMs * 255) / totalMs;

        if (pwm > 0 && pwm < 16) {
            pwm = 16;
        }

        set("/sys/class/leds/red/device/grpfreq", freq);
        set("/sys/class/leds/red/device/grppwm", pwm);
    }
    set("/sys/class/leds/red/device/blink", blink ? 1 : 0);

    LOG(DEBUG) << ::android::base::StringPrintf(
            "handleWhiteLed: mode=%d, color=%08X, onMs=%d, offMs=%d",
            static_cast<int>(stateToUse.flashMode), stateToUse.color, onMs, offMs);
}

ndk::ScopedAStatus Lights::setLightState(int32_t id, const HwLightState& state) {
    // Kunci global sampai keadaan lampu selesai diperbarui.
    std::lock_guard<std::mutex> lock(mLock);

    switch (id) {
        case kIdBacklight:
            set("/sys/class/leds/lcd-backlight/brightness", rgbToBrightness(state));
            break;
        case kIdButtons:
            set("/sys/class/leds/button-backlight/brightness", rgbToBrightness(state));
            break;
        case kIdAttention:
            handleWhiteLed(state, 0);
            break;
        case kIdNotifications:
            handleWhiteLed(state, 1);
            break;
        default:
            return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
    }

    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Lights::getLights(std::vector<HwLight>* lights) {
    // Urutannya harus sejalan dengan LightId di atas: id = indeks.
    static const LightType kTypes[] = {
            LightType::BACKLIGHT,
            LightType::BUTTONS,
            LightType::ATTENTION,
            LightType::NOTIFICATIONS,
    };

    for (int32_t i = 0; i < static_cast<int32_t>(sizeof(kTypes) / sizeof(kTypes[0])); i++) {
        HwLight light;
        light.id = i;
        light.ordinal = 0;
        light.type = kTypes[i];
        lights->push_back(light);
    }

    return ndk::ScopedAStatus::ok();
}

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
