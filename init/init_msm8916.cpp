/*
   Copyright (c) 2016, The CyanogenMod Project

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/sysinfo.h>

// _system_properties.h menolak di-include langsung (guard
// _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_ di bionic/libc/include/sys/
// _system_properties.h:35). Definisikan guard-nya seperti yang dilakukan
// system/core/init sendiri, agar prop_info dan __system_property_update
// bisa dipakai.
#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/properties.h>
#include <android-base/strings.h>

#include "property_service.h"
#include "vendor_init.h"

using android::base::GetProperty;
using android::base::ReadFileToString;
using android::base::Trim;

/*
 * android::init::property_set dihapus dari property_service.h di Android 11,
 * dan penggantinya (InitPropertySet, property_service.cpp:607) tidak diekspor
 * lewat header mana pun.
 *
 * android::base::SetProperty juga bukan pengganti yang benar di sini:
 * vendor_load_properties() dipanggil dari PropertyLoadBootDefaults()
 * (property_service.cpp:877,917), yaitu SEBELUM StartPropertyService(),
 * sehingga socket /dev/socket/property_service belum ada dan SetProperty akan
 * gagal.
 *
 * Jadi dipakai penulisan langsung ke property area — pola yang sama dengan
 * PropertySet di property_service.cpp:179-193. Bedanya di sini penjaga
 * "ro.* write-once" memang sengaja dilewati, karena itulah gunanya override
 * dari vendor init.
 */
static void property_override(const char* name, const char* value)
{
    prop_info* pi = (prop_info*) __system_property_find(name);
    if (pi != nullptr) {
        __system_property_update(pi, value, strlen(value));
    } else {
        __system_property_add(name, strlen(name), value, strlen(value));
    }
}

static void init_alarm_boot_properties()
{
    char const *boot_reason_file = "/proc/sys/kernel/boot_reason";
    char const *power_off_alarm_file = "/persist/alarm/powerOffAlarmSet";
    std::string boot_reason;
    std::string power_off_alarm;
    std::string tmp = GetProperty("ro.boot.alarmboot","");

    if (ReadFileToString(boot_reason_file, &boot_reason)
            && ReadFileToString(power_off_alarm_file, &power_off_alarm)) {
        /*
         * Setup ro.alarm_boot value to true when it is RTC triggered boot up
         * For existing PMIC chips, the following mapping applies
         * for the value of boot_reason:
         *
         * 0 -> unknown
         * 1 -> hard reset
         * 2 -> sudden momentary power loss (SMPL)
         * 3 -> real time clock (RTC)
         * 4 -> DC charger inserted
         * 5 -> USB charger insertd
         * 6 -> PON1 pin toggled (for secondary PMICs)
         * 7 -> CBLPWR_N pin toggled (for external power supply)
         * 8 -> KPDPWR_N pin toggled (power key pressed)
         */
        if ((Trim(boot_reason) == "3" || tmp == "true")
                && Trim(power_off_alarm) == "1")
            property_override("ro.alarm_boot", "true");
        else
            property_override("ro.alarm_boot", "false");
    }
}

bool is2GB()
{
    struct sysinfo sys;
    sysinfo(&sys);
    return sys.totalram > 1024ull * 1024 * 1024;
}

void set_device_dalvik_properties()
{
  property_override("dalvik.vm.heapstartsize", "16m");
  property_override("dalvik.vm.heapgrowthlimit", is2GB() ? "256m" : "128m");
  property_override("dalvik.vm.heapsize", is2GB() ? "512m" : "256m");
  property_override("dalvik.vm.heaptargetutilization", "0.75");
  property_override("dalvik.vm.heapminfree", is2GB() ? "2m" : "512k");
  property_override("dalvik.vm.heapmaxfree", "8m");
  property_override("ro.vendor.qti.sys.fw.bg_apps_limit", is2GB() ? "17" : "9");
}

void vendor_load_properties()
{
    set_device_dalvik_properties();
    init_alarm_boot_properties();
}
