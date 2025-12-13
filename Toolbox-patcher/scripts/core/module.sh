#!/usr/bin/env bash
# scripts/core/module.sh
# Module creation functions


create_kaorios_module() {
    local version_name="1.0"
    local template_dir="module_template"

    log "Creating Kaorios Framework module..."

    # Check if module_template directory exists
    if [ ! -d "$template_dir" ]; then
        err "module_template directory not found in Toolbox-patcher directory!"
        return 1
    fi

    local build_dir="build_kaorios_module"
    rm -rf "$build_dir"
    
    log "Copying module template..."
    cp -r "$template_dir" "$build_dir"
    
    if [ ! -d "$build_dir" ]; then
        err "Failed to copy module template"
        return 1
    fi

    # Update module.prop with version
    if [ -f "$build_dir/module.prop" ]; then
        sed -i "s/^version=.*/version=v${version_name}/" "$build_dir/module.prop"
        log "✓ Updated module.prop"
    else
        warn "module.prop not found in template"
    fi

    # Add framework_patched.jar to system/framework/framework.jar
    if [ -f "framework_patched.jar" ]; then
        mkdir -p "$build_dir/system/framework"
        cp "framework_patched.jar" "$build_dir/system/framework/framework.jar"
        log "✓ Added framework_patched.jar to system/framework/framework.jar"
    else
        warn "framework_patched.jar not found!"
    fi

    # Add KaoriosToolbox.apk with native libraries
    local apk_source="kaorios_toolbox/KaoriosToolbox.apk"
    if [ -f "$apk_source" ]; then
        # Ensure directory exists
        mkdir -p "$build_dir/system/system_ext/priv-app/KaoriosToolbox/lib"
        
        # Copy APK
        cp "$apk_source" "$build_dir/system/system_ext/priv-app/KaoriosToolbox/KaoriosToolbox.apk"
        log "✓ Added KaoriosToolbox.apk"

        # Extract native libraries from APK
        local temp_extract="temp_apk_extract"
        mkdir -p "$temp_extract"
        unzip -q "$apk_source" "lib/*" -d "$temp_extract" 2>/dev/null
        
        if [ -d "$temp_extract/lib" ]; then
            # Copy libraries with proper architecture names
            [ -d "$temp_extract/lib/armeabi-v7a" ] && cp -r "$temp_extract/lib/armeabi-v7a" "$build_dir/system/system_ext/priv-app/KaoriosToolbox/lib/arm"
            [ -d "$temp_extract/lib/arm64-v8a" ] && cp -r "$temp_extract/lib/arm64-v8a" "$build_dir/system/system_ext/priv-app/KaoriosToolbox/lib/arm64"
            [ -d "$temp_extract/lib/x86" ] && cp -r "$temp_extract/lib/x86" "$build_dir/system/system_ext/priv-app/KaoriosToolbox/lib/x86"
            [ -d "$temp_extract/lib/x86_64" ] && cp -r "$temp_extract/lib/x86_64" "$build_dir/system/system_ext/priv-app/KaoriosToolbox/lib/x86_64"
            
            log "✓ Extracted native libraries from APK"
        else
            warn "No native libraries found in APK or extraction failed"
        fi
        rm -rf "$temp_extract"
    else
        warn "KaoriosToolbox.apk not found at $apk_source"
    fi

    # Create final module zip
    local zip_name="kaoriosFramework.zip"
    rm -f "$zip_name"
    
    if command -v 7z >/dev/null 2>&1; then
        (cd "$build_dir" && 7z a -tzip "../$zip_name" "*" >/dev/null)
    elif command -v zip >/dev/null 2>&1; then
        (cd "$build_dir" && zip -r "../$zip_name" . >/dev/null)
    else
        err "No archiver found (7z or zip)"
        return 1
    fi

    log "✓ Created module: $zip_name"
    echo "$zip_name"
}
