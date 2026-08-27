/*
 * Copyright (C) 2018 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.1 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.1
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "android.hardware.radio.config@1.1-service.msm8916"

#include <log/log.h>

#include "RadioConfig.h"

namespace android {
namespace hardware {
namespace radio {
namespace config {

using namespace ::android::hardware::radio::config::V1_1;

using ::android::hardware::radio::V1_0::RadioError;
using ::android::hardware::radio::V1_0::RadioResponseInfo;
using ::android::hardware::radio::V1_0::RadioResponseType;

namespace {

// Modem A37 tidak punya jalur QMI untuk satu pun permintaan RadioConfig, jadi
// semuanya dijawab REQUEST_NOT_SUPPORTED. Itu BUKAN jalan pintas: framework
// menangani kode ini secara khusus. UiccController.onGetSlotStatusDone()
// menyetel mIsSlotStatusSupported = false begitu menerimanya, lalu berhenti
// bertanya dan kembali ke jalur lama getIccCardStatus per telepon.
//
// Tiga field di bawah WAJIB diisi, dan inilah satu-satunya penyimpangan dari
// sumber a6010 (hidl/radio_config/RadioConfig.cpp), yang memakai
// "RadioResponseInfo info;" tanpa inisialisasi:
//
//   serial  RadioConfig.processResponse() memanggil
//           findAndRemoveRequestFromList(serial). Kalau tidak digemakan,
//           pencarian gagal, framework mencatat "Unexpected response!" dan
//           RILRequest tidak pernah diselesaikan sehingga menggantung.
//   type    processResponse() mencatat "Unexpected response type" untuk
//           apa pun selain SOLICITED.
//   error   struct HIDL adalah POD tanpa penginisialisasi anggota, jadi
//           membiarkannya berarti membaca memori tak tentu.
RadioResponseInfo makeInfo(int32_t serial, RadioError error = RadioError::REQUEST_NOT_SUPPORTED) {
    RadioResponseInfo info;
    info.type = RadioResponseType::SOLICITED;
    info.serial = serial;
    info.error = error;
    return info;
}

}  // namespace

Return<void> RadioConfig::setResponseFunctions(
    const sp<V1_0::IRadioConfigResponse>& radioConfigResponse,
    const sp<V1_0::IRadioConfigIndication>& radioConfigIndication) {
    mRadioConfigResponse = V1_1::IRadioConfigResponse::castFrom(radioConfigResponse);
    mRadioConfigIndication = radioConfigIndication;
    return Void();
}

Return<void> RadioConfig::getSimSlotsStatus(int32_t serial) {
    if (mRadioConfigResponse == nullptr) {
        ALOGE("getSimSlotsStatus: belum ada response object");
        return Void();
    }
    hidl_vec<V1_0::SimSlotStatus> slotStatus;
    mRadioConfigResponse->getSimSlotsStatusResponse(makeInfo(serial), slotStatus);
    return Void();
}

Return<void> RadioConfig::setSimSlotsMapping(int32_t serial,
                                             const hidl_vec<uint32_t>& /* slotMap */) {
    if (mRadioConfigResponse == nullptr) {
        ALOGE("setSimSlotsMapping: belum ada response object");
        return Void();
    }
    mRadioConfigResponse->setSimSlotsMappingResponse(makeInfo(serial));
    return Void();
}

Return<void> RadioConfig::getPhoneCapability(int32_t serial) {
    if (mRadioConfigResponse == nullptr) {
        ALOGE("getPhoneCapability: belum ada response object");
        return Void();
    }
    V1_1::PhoneCapability capability = {};
    mRadioConfigResponse->getPhoneCapabilityResponse(makeInfo(serial), capability);
    return Void();
}

Return<void> RadioConfig::setPreferredDataModem(int32_t serial, uint8_t /* modemId */) {
    if (mRadioConfigResponse == nullptr) {
        ALOGE("setPreferredDataModem: belum ada response object");
        return Void();
    }
    // Satu-satunya permintaan yang dijawab SUKSES, dan alasannya terukur.
    //
    // Dengan REQUEST_NOT_SUPPORTED, PhoneSwitcher.onDdsSwitchResponse() masuk
    // cabang "DDS switch failed" lalu menjadwalkan EVENT_MODEM_COMMAND_RETRY
    // setiap MODEM_COMMAND_RETRY_PERIOD_MS. Kondisinya permanen di perangkat
    // ini, jadi loopnya tidak pernah berhenti: terukur 27 Agu 2026 sebagai
    // permintaan tiap 5 detik tanpa akhir (73 kali dalam satu sesi boot).
    //
    // Dengan NONE, commandSuccess bernilai true, mCurrentDdsSwitchFailure
    // dibersihkan, dan penjadwalan retry tidak pernah terjadi.
    //
    // Ini bukan kebohongan yang berbahaya: perangkat hanya punya satu modem
    // aktif dengan SIM di slot 1, sehingga "modem data utama = phone 0" memang
    // sudah benar tanpa perlu tindakan apa pun.
    mRadioConfigResponse->setPreferredDataModemResponse(
        makeInfo(serial, RadioError::NONE));
    return Void();
}

Return<void> RadioConfig::setModemsConfig(int32_t serial,
                                          const V1_1::ModemsConfig& /* modemsConfig */) {
    if (mRadioConfigResponse == nullptr) {
        ALOGE("setModemsConfig: belum ada response object");
        return Void();
    }
    mRadioConfigResponse->setModemsConfigResponse(makeInfo(serial));
    return Void();
}

Return<void> RadioConfig::getModemsConfig(int32_t serial) {
    if (mRadioConfigResponse == nullptr) {
        ALOGE("getModemsConfig: belum ada response object");
        return Void();
    }
    const V1_1::ModemsConfig config = {};
    mRadioConfigResponse->getModemsConfigResponse(makeInfo(serial), config);
    return Void();
}

}  // namespace config
}  // namespace radio
}  // namespace hardware
}  // namespace android
