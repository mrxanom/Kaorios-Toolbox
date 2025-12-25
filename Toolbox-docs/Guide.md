# Kaorios Toolbox Guide
#V1.0.7

## Step 1: Download & place system files

- **Download** `App & Xml`, and `classes.dex` from: **[releases](https://github.com/Wuang26/Kaorios-Toolbox/releases)**
- **Add app directory:**
  - Copy the **KaoriosToolbox** folder to: `/system_ext/priv-app/` or `/product/priv-app/`
- **Copy files:**
  - Copy `privapp_whitelist_com.kousei.kaorios.xml` → `/system_ext/etc/permissions/` or `/product/etc/permissons/`
- **Permissions:**
  - Directories: `0755` (e.g., `KaoriosToolbox`, `lib`, `lib/*`)
  - Files: `0644` (for `.xml`, `.apk`, and any `.so`)

---

## Step 2: Add to `system/build.prop`

```properties
# Kaorios Toolbox
persist.sys.kaorios=kousei
# Leave the value after the = sign blank.
ro.control_privapp_permissions=
```

---

## Step 3: Import `classes.dex`

> Import **classes.dex** into the **last classes** of `framework.jar` (append as the last `classes*.dex`).

---

## Step 4: Patch `framework.jar` classes

> **Note:** If you are unsure about the exact injection spots, please refer to the **sample .smali templates** in the repo’s **[Toolbox-docs/Template](https://github.com/Wuang26/Kaorios-Toolbox/tree/main/Toolbox-docs/Template)** folder.

> **For Framework.jar in Android 15 you will need to remove methods containing invoke-custom to avoid bootloop**

### Class:
```
ApplicationPackageManager
```

> ### This feature can easily cause bootloop, if you don't use it you can skip this Method:
```
hasSystemFeature(Ljava/lang/String;)Z
```
> Replace all method (skip if bootloop):
```
.method public hasSystemFeatureTests(Ljava/lang/String;)Z
    .registers 3

    const/4 v0, 0x0

    invoke-virtual {p0, p1, v0}, Landroid/app/ApplicationPackageManager;->hasSystemFeature(Ljava/lang/String;I)Z

    move-result p0

    :try_start_kousei
    invoke-static {p0, p1}, Lcom/android/internal/util/kaorios/KaoriPropsUtils;->KaoriFeatureBlock(ZLjava/lang/String;)Z

    move-result p0
    :try_end_kaorios
    .catchall {:try_start_kousei .. :try_end_kaorios} :catchall_kaorios

    :catchall_kaorios
    return p0
.end method

```
> ### Method:
```
hasSystemFeature(Ljava/lang/String;I)Z
```
> below: **.registers X** add this code:
```
invoke-static {}, Landroid/app/ActivityThread;->currentPackageName()Ljava/lang/String;
            
    move-result-object v0
            
    :try_start_kaori_override
    iget-object v1, p0, Landroid/app/ApplicationPackageManager;->mContext:Landroid/app/ContextImpl;
            
    invoke-static {v1, p1, v0}, Lcom/android/internal/util/kaorios/KaoriFeatureOverrides;->getOverride(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Boolean;
            
    move-result-object v0
    :try_end_kaori_override
    .catchall {:try_start_kaori_override .. :try_end_kaori_override} :catchall_kaori_override
            
    goto :goto_kaori_override
            
    :catchall_kaori_override
    const/4 v0, 0x0
            
    :goto_kaori_override
    if-eqz v0, :cond_kaori_override
            
    invoke-virtual {v0}, Ljava/lang/Boolean;->booleanValue()Z
            
    move-result p0
            
    return p0
            
    :cond_kaori_override
```

---

### Class:
```
Instrumentation
```

> #### Method:
```
newApplication(Ljava/lang/Class;Landroid/content/Context;)Landroid/app/Application;
```
> in method find:
```
return-object v0
    .end method
```

> add this code above the just found:
```
invoke-static {p1}, Lcom/android/internal/util/kaorios/KaoriPropsUtils;->KaoriProps(Landroid/content/Context;)V
```

---

> #### Method:
```
newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;
```

> in method find:
```
return-object v0
    .end method
```

> add this code above the just found:
```
invoke-static {p3}, Lcom/android/internal/util/kaorios/KaoriPropsUtils;->KaoriProps(Landroid/content/Context;)V
```

---

### Class:
```
KeyStore2
```
> #### Method:
```
getKeyEntry(Landroid/system/keystore2/KeyDescriptor;)Landroid/system/keystore2/KeyEntryResponse;
```
> in method find:
```
return-object v0
    .end method
```

> add this code above the just found:
```
invoke-static {v0}, Lcom/android/internal/util/kaorios/KaoriKeyboxHooks;->KaoriGetKeyEntry(Landroid/system/keystore2/KeyEntryResponse;)Landroid/system/keystore2/KeyEntryResponse;

    move-result-object v0
```

---

### Class:
```
AndroidKeyStoreSpi
```

> #### Method:
```
engineGetCertificateChain(Ljava/lang/String;)[Ljava/security/cert/Certificate;
```
> below: **.registers XX** add this code:
```
invoke-static {}, Lcom/android/internal/util/kaorios/KaoriPropsUtils;->KaoriGetCertificateChain()V
```
> in method find:
```
const/4 v4, 0x0

    aput-object v2, v3, v4
```
> add this code below the just found:
```
invoke-static {v3}, Lcom/android/internal/util/kaorios/KaoriKeyboxHooks;->KaoriGetCertificateChain([Ljava/security/cert/Certificate;)[Ljava/security/cert/Certificate;

    move-result-object v3
```
