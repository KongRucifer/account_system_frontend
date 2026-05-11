USB cable ເຊື່ອມ phone ກັບ PC ສາມາດໃຊ້ໄດ້ 2 ທາງ:

ວິທີທີ່ງ່າຍທີ່ສຸດ — adb reverse
ໃຊ້ adb reverse ເຮັດໃຫ້ phone ສາມາດ access localhost ຂອງ PC ໄດ້ໂດຍກົງ:

powershell
adb reverse tcp:4000 tcp:4000
ຫຼັງຈາກນີ້ .env ຂອງ frontend ບໍ່ຕ້ອງປ່ຽນ — ໃຊ້ localhost:4000 ໄດ້ເລີຍ.

ແຕ່ກ່ອນອື່ນ — backend ແລ່ນ port ຫຍັງ? ກວດ:

Command netstat, findstr


netstat -ano | findstr "LISTENING" | findstr ":4000\|:3000"





⚠️ ທຸກຄັ້ງທີ່ unplug/replug cable ຫຼື restart phone ຕ້ອງ run adb reverse ໃໝ່. ຫຼື add ໃສ່ script:

powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:4000 tcp:4000