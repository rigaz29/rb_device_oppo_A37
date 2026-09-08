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

#pragma once

#include <aidl/android/hardware/light/BnLights.h>

#include <array>
#include <mutex>
#include <vector>

namespace aidl {
namespace android {
namespace hardware {
namespace light {

class Lights : public BnLights {
  public:
    Lights();

    ndk::ScopedAStatus setLightState(int32_t id, const HwLightState& state) override;
    ndk::ScopedAStatus getLights(std::vector<HwLight>* lights) override;

  private:
    // Indeks di mLightStates: 0 = ATTENTION, 1 = NOTIFICATIONS.
    // Dipertahankan persis dari implementasi HIDL supaya urutan prioritasnya
    // (attention lebih dulu, lalu notifications) tidak berubah.
    void handleWhiteLed(const HwLightState& state, size_t index);

    std::mutex mLock;
    std::array<HwLightState, 2> mLightStates;
};

}  // namespace light
}  // namespace hardware
}  // namespace android
}  // namespace aidl
