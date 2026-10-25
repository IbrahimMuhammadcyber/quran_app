import re
import os

manifest_path = "android/app/src/main/AndroidManifest.xml"

with open(manifest_path) as f:
    manifest = f.read()

permissions = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
    "android.permission.WAKE_LOCK",
]

for perm in permissions:
    if perm not in manifest:
        manifest = manifest.replace(
            "<application",
            f'    <uses-permission android:name="{perm}" />\n    <application',
            1,
        )

if "com.ryanheise.audioservice.AudioService" not in manifest:
    service_block = (
        '        <service android:name="com.ryanheise.audioservice.AudioService"\n'
        '            android:foregroundServiceType="mediaPlayback"\n'
        '            android:exported="true">\n'
        '            <intent-filter>\n'
        '                <action android:name="android.media.browse.MediaBrowserService" />\n'
        '            </intent-filter>\n'
        '        </service>\n'
        '        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"\n'
        '            android:exported="true">\n'
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.MEDIA_BUTTON" />\n'
        '            </intent-filter>\n'
        '        </receiver>\n'
        '    </application>'
    )
    manifest = manifest.replace("    </application>", service_block, 1)

with open(manifest_path, "w") as f:
    f.write(manifest)

print("AndroidManifest.xml patched (permissions + audio_service entries)")

kts_path = "android/app/build.gradle.kts"
groovy_path = "android/app/build.gradle"

if os.path.exists(kts_path):
    path = kts_path
    compile_block = "    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }\n"
    dep_line = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n'
    dep_block = "dependencies {\n" + dep_line + "}\n"
else:
    path = groovy_path
    compile_block = "    compileOptions {\n        coreLibraryDesugaringEnabled true\n    }\n"
    dep_line = "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'\n"
    dep_block = "dependencies {\n" + dep_line + "}\n"

with open(path) as f:
    content = f.read()

content = re.sub(r"(android\s*\{)", r"\1\n" + compile_block, content, count=1)

if re.search(r"dependencies\s*\{", content):
    content = re.sub(r"(dependencies\s*\{)", r"\1\n" + dep_line, content, count=1)
else:
    content += "\n" + dep_block

with open(path, "w") as f:
    f.write(content)

print(f"Patched {path} for core library desugaring")

settings_kts = "android/settings.gradle.kts"
settings_groovy = "android/settings.gradle"

if os.path.exists(settings_kts):
    spath = settings_kts
    pattern = r'id\("org\.jetbrains\.kotlin\.android"\) version "[^"]*"'
    replacement = 'id("org.jetbrains.kotlin.android") version "2.2.20"'
else:
    spath = settings_groovy
    pattern = r'id "org\.jetbrains\.kotlin\.android" version "[^"]*"'
    replacement = 'id "org.jetbrains.kotlin.android" version "2.2.20"'

with open(spath) as f:
    scontent = f.read()

scontent = re.sub(pattern, replacement, scontent)

with open(spath, "w") as f:
    f.write(scontent)

print(f"Patched {spath} for Kotlin version")
