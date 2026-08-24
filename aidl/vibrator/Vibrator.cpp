#define LOG_TAG "android.hardware.vibrator-service.msm8916"
#include <android-base/logging.h>

#include <cutils/properties.h>
#include <cinttypes>
#include <cmath>
#include <iostream>
#include <fstream>
#include <thread>

#include "Vibrator.h"

namespace aidl {
namespace android {
namespace hardware {
namespace vibrator {

static const char *VIBRATOR_AMPLITUDE_LIGTH_PROP = "ro.vibrator.hal.amplitude.light";
static const char *VIBRATOR_AMPLITUDE_MEDIUM_PROP = "ro.vibrator.hal.amplitude.medium";
static const char *VIBRATOR_AMPLITUDE_STRONG_PROP = "ro.vibrator.hal.amplitude.strong";

static const char *VIBRATOR_EFFECT_CLICK_DURATION_PROP = "ro.vibrator.hal.click.duration";
static const char *VIBRATOR_EFFECT_TICK_DURATION_PROP = "ro.vibrator.hal.tick.duration";

static int readIntFromFile(const std::string& path, int fallback) {
    std::ifstream in(path);
    int value;
    if (in && (in >> value)) return value;
    return fallback;
}

Vibrator::Vibrator(std::ofstream&& enable) : mEnable(std::move(enable)) {
    mVtgLevel.open(VIBRATOR_LEVEL_PATH);

    // Rentang vtg DIBACA dari perangkat, bukan dipatok. Sumber a6010 mematok
    // 18..31, sedangkan A37 melaporkan vtg_min=12 vtg_max=31 vtg_default=31.
    mVtgMin = (uint8_t)readIntFromFile(VIBRATOR_VTG_MIN_PATH, 18);
    mVtgMax = (uint8_t)readIntFromFile(VIBRATOR_VTG_MAX_PATH, 31);
    mVtgDefault = (uint8_t)readIntFromFile(VIBRATOR_VTG_DEFAULT_PATH, 25);
    if (mVtgMax <= mVtgMin) {
        LOG(WARNING) << "rentang vtg tidak masuk akal (" << (int)mVtgMin << ".."
                     << (int)mVtgMax << "), memakai 18..31";
        mVtgMin = 18;
        mVtgMax = 31;
    }
    LOG(INFO) << "vtg " << (int)mVtgMin << ".." << (int)mVtgMax
              << " default " << (int)mVtgDefault;

    mEffectClickDuration = (int32_t)property_get_int32(VIBRATOR_EFFECT_CLICK_DURATION_PROP, 40);
    mEffectTickDuration = (int32_t)property_get_int32(VIBRATOR_EFFECT_TICK_DURATION_PROP, 20);

    mAmplitudeLight = (uint8_t)property_get_int32(VIBRATOR_AMPLITUDE_LIGTH_PROP, 45);
    mAmplitudeMedium = (uint8_t)property_get_int32(VIBRATOR_AMPLITUDE_MEDIUM_PROP, 65);
    mAmplitudeStrong = (uint8_t)property_get_int32(VIBRATOR_AMPLITUDE_STRONG_PROP, 85);
}

ndk::ScopedAStatus Vibrator::getCapabilities(int32_t* _aidl_return) {
    *_aidl_return = IVibrator::CAP_ON_CALLBACK | IVibrator::CAP_PERFORM_CALLBACK;
    if (mVtgLevel.is_open()) {
        *_aidl_return |= IVibrator::CAP_AMPLITUDE_CONTROL;
    }

    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Vibrator::off() {
    mEnable << 0 << std::endl;
    if (!mEnable) {
        LOG(ERROR) << "Failed to turn vibrator off. Error: " << errno << " - " << strerror(errno);
        return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_SERVICE_SPECIFIC));
    }

    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Vibrator::on(int32_t timeoutMs,
                                const std::shared_ptr<IVibratorCallback>& callback) {
    mEnable << timeoutMs << std::endl;
    if (!mEnable) {
        LOG(ERROR) << "Failed to turn vibrator on. Error: " << errno << " - " << strerror(errno);
        return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_SERVICE_SPECIFIC));
    }

    if (callback != nullptr) {
        std::thread([=] {
            usleep(timeoutMs * 1000);
            if (!callback->onComplete().isOk()) {
                LOG(ERROR) << "Failed to call onComplete";
            }
        }).detach();
    }

    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Vibrator::perform(Effect effect, EffectStrength es, const std::shared_ptr<IVibratorCallback>& callback, int32_t* _aidl_return) {
    // Nilai MENTAH, bukan pecahan -- karena itu setVtgLevelRaw() yang dipanggil,
    // bukan setAmplitude(). Diturunkan dari rentang perangkat supaya tetap benar
    // kalau vtg_min/vtg_max berbeda dari asumsi a6010.
    int level = mVtgDefault;
    switch (es) {
        case EffectStrength::LIGHT:
            level = mVtgMin;
            break;
        case EffectStrength::MEDIUM:
            level = mVtgMin + (mVtgMax - mVtgMin) / 2;
            break;
        case EffectStrength::STRONG:
        default:
            level = mVtgMax;
            break;
    }

    ndk::ScopedAStatus status = ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
    switch (effect) {
        case Effect::CLICK:
            setVtgLevelRaw(level);
            *_aidl_return = mEffectClickDuration;
            status = on(mEffectClickDuration, callback);
            break;
        case Effect::TICK:
            setVtgLevelRaw(level);
            *_aidl_return = mEffectTickDuration;
            status = on(mEffectTickDuration, callback);
            break;
        default:
            break;
    }

    return status;
}

ndk::ScopedAStatus Vibrator::getSupportedEffects(std::vector<Effect>* _aidl_return) {
    *_aidl_return = {Effect::CLICK, Effect::TICK};
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Vibrator::setVtgLevelRaw(int level) {
    if (!mVtgLevel.is_open()) {
        return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
    }

    if (level < mVtgMin) level = mVtgMin;
    if (level > mVtgMax) level = mVtgMax;

    mVtgLevel << level << std::endl;
    if (!mVtgLevel) {
        LOG(ERROR) << "Failed to set vtg level. Error: " << errno << " - " << strerror(errno);
        return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_SERVICE_SPECIFIC));
    }
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Vibrator::setAmplitude(float amplitude) {
    // KONTRAK AIDL: amplitude adalah pecahan TERNORMALISASI dalam (0.0, 1.0],
    // bukan nilai vtg mentah.
    //
    // Sumber a6010 memeriksa `amplitude < 12.0f || amplitude > 31.0f` lalu
    // menulisnya apa adanya ke vtg_level. Itu keliru dua kali:
    //
    //   1. Framework mengirim pecahan (mis. 0.5), sehingga SETIAP panggilan
    //      ditolak. Terekam di perangkat ini:
    //        E VibratorController: Vibrator HAL setAmplitude failed:
    //          Status(-3, EX_ILLEGAL_ARGUMENT): ''
    //   2. Batasnya (12, 31) bahkan tidak cocok dengan mVtgMin/mVtgMax yang
    //      disetel konstruktornya sendiri (18, 31).
    //
    // perform() di berkas ini juga memanggil setAmplitude() dengan nilai MENTAH
    // (18/25/31), jadi satu metode melayani dua pemanggil bersatuan berbeda.
    // Karena itu penulisan mentah dipindah ke setVtgLevelRaw(), dan metode AIDL
    // ini murni memetakan pecahan ke rentang perangkat.
    if (!mVtgLevel.is_open()) {
        return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
    }

    if (!(amplitude > 0.0f) || amplitude > 1.0f) {
        return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_ILLEGAL_ARGUMENT));
    }

    return setVtgLevelRaw(mVtgMin + (int)lroundf(amplitude * (float)(mVtgMax - mVtgMin)));
}

ndk::ScopedAStatus Vibrator::setExternalControl(bool enabled __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::getCompositionDelayMax(int32_t* maxDelayMs __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::getCompositionSizeMax(int32_t* maxSize __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::getSupportedPrimitives(std::vector<CompositePrimitive>* supported __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::getPrimitiveDuration(CompositePrimitive primitive __unused,
                                                  int32_t* durationMs __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::compose(const std::vector<CompositeEffect>& composite __unused,
                                     const std::shared_ptr<IVibratorCallback>& callback __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::getSupportedAlwaysOnEffects(std::vector<Effect>* _aidl_return __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::alwaysOnEnable(int32_t id __unused, Effect effect __unused,
                                            EffectStrength strength __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

ndk::ScopedAStatus Vibrator::alwaysOnDisable(int32_t id __unused) {
    return ndk::ScopedAStatus(AStatus_fromExceptionCode(EX_UNSUPPORTED_OPERATION));
}

}  // namespace vibrator
}  // namespace hardware
}  // namespace android
}  // namespace aidl
