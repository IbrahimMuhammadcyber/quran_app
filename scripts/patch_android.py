import re
import os

manifest_path = "android/app/src/main/AndroidManifest.xml"

with open(manifest_path) as f:
    manifest = f.read()

if "android.permission.INTERNET" not in manifest:
    manifest = manifest.replace(
        "<application",
        '    <uses-permission android:name="android.permission.INTERNET" />\n    <application',
        1,
    )
if "android.permission.POST_NOTIFICATIONS" not in manifest:
    manifest = manifest.replace(
        "<application",
        '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <application',
        1,
    )
if "android.permission.ACCESS_FINE_LOCATION" not in manifest:
    manifest = manifest.replace(
        "<application",
        '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <application',
        1,
    )
if "android.permission.ACCESS_COARSE_LOCATION" not in manifest:
    manifest = manifest.replace(
        "<application",
        '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n    <application',
        1,
    )

with open(manifest_path, "w") as f:
    f.write(manifest)

print("AndroidManifest.xml patched (permissions)")

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

proguard_path = "android/app/proguard-rules.pro"
proguard_rules = (
    "-keep class com.dexterous.** { *; }\n"
    "-keepattributes Signature\n"
    "-keepattributes *Annotation*\n"
    "-dontwarn com.dexterous.**\n"
    "-keep class androidx.work.** { *; }\n"
)
with open(proguard_path, "w") as f:
    f.write(proguard_rules)
print("Created proguard-rules.pro")

if os.path.exists(kts_path):
    bpath = kts_path
    proguard_insert = '            proguardFiles(\n                getDefaultProguardFile("proguard-android-optimize.txt"),\n                "proguard-rules.pro"\n            )\n'
else:
    bpath = groovy_path
    proguard_insert = "            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'\n"

with open(bpath) as f:
    bcontent = f.read()

if "proguard-rules.pro" not in bcontent:
    release_match = re.search(r"(release\s*\{)", bcontent)
    if release_match:
        bcontent = bcontent[:release_match.end()] + "\n" + proguard_insert + bcontent[release_match.end():]
        with open(bpath, "w") as f:
            f.write(bcontent)
        print(f"Added proguardFiles reference to {bpath}")
    else:
        print("Could not find release block to patch proguardFiles")
else:
    print("proguardFiles already referenced")

if os.path.exists(kts_path):
    mpath = kts_path
    minify_pattern = r'isMinifyEnabled\s*=\s*true'
    minify_insert = "isMinifyEnabled = false\n            isShrinkResources = false"
else:
    mpath = groovy_path
    minify_pattern = r'minifyEnabled\s+true'
    minify_insert = "minifyEnabled false\n            shrinkResources false"

with open(mpath) as f:
    mcontent = f.read()

if re.search(minify_pattern, mcontent):
    mcontent = re.sub(minify_pattern, minify_insert, mcontent, count=1)
    print("Disabled code shrinking for release build")
else:
    release_match = re.search(r"(release\s*\{)", mcontent)
    if release_match and "isMinifyEnabled" not in mcontent and "minifyEnabled" not in mcontent:
        mcontent = mcontent[:release_match.end()] + "\n            " + minify_insert + "\n" + mcontent[release_match.end():]
        print("Added code shrinking disable flags to release build")
    else:
        print("Could not locate minify flag to patch")

with open(mpath, "w") as f:
    f.write(mcontent)
