//
//  BuildScripts.swift
//  PythonSwiftProject
//
//  Created by CodeBuilder on 04/08/2025.
//

import ProjectSpec
import PathKit

extension BuildScript.ScriptType: Swift.ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self = .script(value)
    }
    
    
}

extension BuildScript {
    
    static func installAppModule(pythonProject: Path) -> BuildScript {
        let hostPython: Path = .hostPython
        let pip3 = hostPython + "bin/pip3"
        return .init(
            script: .script("""
            
            APP_SRC="$PROJECT_DIR/../../"
            PIP3=\(pip3)
            PIP_ARGS="--compile -U --no-deps"
            
            if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
                echo "Installing App module for iOS Simulator"
                $PIP3 install $APP_SRC $PIP_ARGS -t "$PROJECT_DIR/site_packages/iphonesimulator/"
            elif [ "$EFFECTIVE_PLATFORM_NAME" = "-iphoneos" ]; then
                echo "Installing App module for iOS"
                $PIP3 install $APP_SRC $PIP_ARGS -t "$PROJECT_DIR/site_packages/iphoneos/" 
            else
                echo "Installing App module for macOS"
                $PIP3 install $APP_SRC $PIP_ARGS -t "$PROJECT_DIR/site_packages/macos/" 
            fi
            """),
            name: "Install App Module"
        )
    }
    //    if [ "$ARCHS" = "arm64 x86_64" ]; then
    //    echo "universal archs pip wheel"
    //    else
    //        echo "single arch pip wheel"
    //        fi
    static func installAppWheelModule(name: String) -> BuildScript {
        let hostPython: Path = .hostPython
        let pip3 = hostPython + "bin/pip3"
        let pip_base = """
        -U --no-deps \
        --disable-pip-version-check \
        --platform=$PLATFORM_ARCH \
        --only-binary=:all: \
        --extra-index-url file://$APP_SRC/wheels/simple \
        --target $SITE
        """
        let pip_base_macos = """
        -U --no-deps \
        --disable-pip-version-check \
        --only-binary=:all: \
        --extra-index-url file://$APP_SRC/wheels/simple \
        --target $SITE
        """
        let os_min = "ios_13_0"
        
        return .init(
            script: .script("""
            
            APP_SRC="$PROJECT_DIR/../.."
            PIP3=\(pip3)
            PLATFORM_ARCH=\(os_min)_arm64_iphoneos
            
            if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
                echo "Installing App module for iOS Simulator"
                SITE="$PROJECT_DIR/site_packages/iphonesimulator/"
                if [ "$ARCHS" = "x86_64" ]; then
                    PLATFORM_ARCH=\(os_min)_x86_64_iphonesimulator
                else
                    PLATFORM_ARCH=\(os_min)_arm64_iphonesimulator
                fi
                PIP_BASE="\(pip_base)"
            elif [ "$EFFECTIVE_PLATFORM_NAME" = "-iphoneos" ]; then
                echo "Installing App module for iOS"
                SITE="$PROJECT_DIR/site_packages/iphoneos/"
                PIP_BASE="\(pip_base)"
            else
                echo "Installing App module for macOS"
                SITE="$PROJECT_DIR/site_packages/macos/"
                PIP_BASE="\(pip_base_macos)"
            fi
            
            PIP_CMD="$PIP3 install \(name) $PIP_BASE"
            echo "$PIP_CMD"
            $PIP_CMD
            
            """),
            name: "Install App Module"
        )
    }
    
    static func installPyModules(pythonProject: Path) -> BuildScript {
        .init(
            script: .script(.installPyModulesMultiPlatform(pythonProject: pythonProject)),
            name: "Install target specific Python modules"
        )
    }
    
    static func installPyModulesIphoneOS(pythonProject: Path) -> BuildScript {
        .init(
            script: .script("""
            set -e
            
            PYTHON="$PROJECT_DIR/python3"
            
            mkdir -p "$CODESIGNING_FOLDER_PATH/python/lib"
            if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
                echo "Installing Python modules for iOS Simulator"
                rsync -au --delete "$PROJECT_DIR/Support/ios-arm64_x86_64-simulator/lib/" "$CODESIGNING_FOLDER_PATH/python/lib/" 
                rsync -au --delete "$PROJECT_DIR/site_packages.iphonesimulator/" "$CODESIGNING_FOLDER_PATH/site_packages" 
            else
                echo "Installing Python modules for iOS Device"
                rsync -au --delete "$PROJECT_DIR/Support/ios-arm64/lib/" "$CODESIGNING_FOLDER_PATH/python/lib" 
                rsync -au --delete "$PROJECT_DIR/site_packages.iphoneos/" "$CODESIGNING_FOLDER_PATH/site_packages" 
            fi
            
            PY_APP="$CODESIGNING_FOLDER_PATH/app"
            rsync -au --delete "\(pythonProject)/" $PY_APP
            #$PYTHON -m compileall -f -b -o2 $PY_APP
            #find $PY_APP -regex '.*\\.py' -delete
            
            PY_SITE="$CODESIGNING_FOLDER_PATH/site_packages"
            #$PYTHON -m compileall -f -b -o2 $PY_SITE
            #find $PY_SITE -regex '.*\\.py' -print -delete
            #find $PY_SITE -name '__pycache__' -type d -print -exec rm -r {} + -depth
            
            """),
            name: "Install target specific Python modules"
        )
    }
    
    static func signPythonBinary() -> BuildScript {
        .init(
            script: .script(.signPythonBinaryMultiPlatform()),
            name: "Sign Python Binary Modules"
        )
    }
    
    static func signPythonBinaryIphoneOS() -> BuildScript {
        .init(
            script: .script(.signPythonBinaryIPhoneOS()),
            name: "Sign Python Binary Modules"
        )
    }
    
    static func copyAppPackagesMacOS() -> BuildScript {
        .init(
            script: """
                
                """,
            name: "Copy App Packages"
        )
    }
    
    static func signPythonBinaryMacOS() -> BuildScript {
        .init(
            script: .script(.signPythonBinaryMacOS()),
            name: "Sign Python Binary Modules"
        )
    }
}


extension String {
    
    fileprivate static var ios_condition: Self { "[ \"$EFFECTIVE_PLATFORM_NAME\" = \"-iphonesimulator\" ] || [ \"$EFFECTIVE_PLATFORM_NAME\" = \"-iphoneos\" ]"}
    
    fileprivate static func signPythonBinaryMultiPlatform() -> Self {
        
        let ios_string = signPythonBinaryIPhoneOS_Base().replacing("\n", with: "\n\t")
        let macos_string = signPythonBinaryMacOS_Base().replacing("\n", with: "\n\t")
        return """
        set -e
        if \(ios_condition); then
            echo "Installing Python modules for iOS Device/Simulator"
            \(ios_string)
        else
            echo "Installing Python modules for macOS"
            \(macos_string)
        fi
        """
    }
    
    fileprivate static func signPythonBinaryMacOS() -> Self {
        """
        set -e
        \(signPythonBinaryMacOS_Base())
        """
    }
    
    fileprivate static func signPythonBinaryMacOS_Base() -> Self {
        // $CODESIGNING_FOLDER_PATH
        // $BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH
        return """
        set -e
        echo "Signed as $EXPANDED_CODE_SIGN_IDENTITY_NAME ($EXPANDED_CODE_SIGN_IDENTITY)"
        
        find "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/site_packages" -name "*.so" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \\; 
        find "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/app" -name "*.so" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \\; 
        """
    }
    
    fileprivate static func signPythonBinaryIPhoneOS() -> Self {
        """
        set -e
        \(signPythonBinaryIPhoneOS_Base())
        """
    }
    
    fileprivate static func signPythonBinaryIPhoneOS_Base() -> Self {
            """
            install_dylib () {
                INSTALL_BASE=$1
                FULL_EXT=$2
            
                # The name of the extension file
                EXT=$(basename "$FULL_EXT")
                # The location of the extension file, relative to the bundle
                RELATIVE_EXT=${FULL_EXT#$CODESIGNING_FOLDER_PATH/} 
                # The path to the extension file, relative to the install base
                PYTHON_EXT=${RELATIVE_EXT/$INSTALL_BASE/}
                # The full dotted name of the extension module, constructed from the file path.
                FULL_MODULE_NAME=$(echo $PYTHON_EXT | cut -d "." -f 1 | tr "/" "."); 
                # A bundle identifier; not actually used, but required by Xcode framework packaging
                FRAMEWORK_BUNDLE_ID=$(echo $PRODUCT_BUNDLE_IDENTIFIER.$FULL_MODULE_NAME | tr "_" "-")
                # The name of the framework folder.
                FRAMEWORK_FOLDER="Frameworks/$FULL_MODULE_NAME.framework"
            
                # If the framework folder doesn't exist, create it.
                if [ ! -d "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER" ]; then
                    echo "Creating framework for $RELATIVE_EXT" 
                    mkdir -p "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER"
            
                    cp "$CODESIGNING_FOLDER_PATH/dylib-Info-template.plist" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
                    plutil -replace CFBundleExecutable -string "$FULL_MODULE_NAME" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
                    plutil -replace CFBundleIdentifier -string "$FRAMEWORK_BUNDLE_ID" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
                fi
                
                echo "Installing binary for $FRAMEWORK_FOLDER/$FULL_MODULE_NAME" 
                mv "$FULL_EXT" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/$FULL_MODULE_NAME"
                # Create a placeholder .fwork file where the .so was
                echo "$FRAMEWORK_FOLDER/$FULL_MODULE_NAME" > ${FULL_EXT%.so}.fwork
                # Create a back reference to the .so file location in the framework
                echo "${RELATIVE_EXT%.so}.fwork" > "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/$FULL_MODULE_NAME.origin"     
            }
            
            echo "Install standard library extension modules..."
            find "$CODESIGNING_FOLDER_PATH/python/lib/python3.11/lib-dynload" -name "*.so" | while read FULL_EXT; do
                install_dylib python/lib/python3.11/lib-dynload/ "$FULL_EXT"
            done
            echo "Install app package extension modules..."
            find "$CODESIGNING_FOLDER_PATH/site_packages" -name "*.so" | while read FULL_EXT; do
                install_dylib app_packages/ "$FULL_EXT"
            done
            echo "Install app extension modules..."
            find "$CODESIGNING_FOLDER_PATH/app" -name "*.so" | while read FULL_EXT; do
                install_dylib app/ "$FULL_EXT"
            done
            
            # Clean up dylib template 
            rm -f "$CODESIGNING_FOLDER_PATH/dylib-Info-template.plist"
            
            echo "Signing frameworks as $EXPANDED_CODE_SIGN_IDENTITY_NAME ($EXPANDED_CODE_SIGN_IDENTITY)..."
            find "$CODESIGNING_FOLDER_PATH/Frameworks" -name "*.framework" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" ${OTHER_CODE_SIGN_FLAGS:-} -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der "{}" \\; 
            """
    }
    
    static func installPyModulesIphoneOS(pythonProject: Path) -> Self {
        InstallPyModulesBase(
            text: installPyModulesIphoneOS_Base(pythonProject: pythonProject),
            pythonProject: pythonProject
        )
    }
    
    static func installPyModulesMacOS(pythonProject: Path) -> Self {
        InstallPyModulesBase(
            text: installPyModulesMacOS_Base(pythonProject: pythonProject),
            pythonProject: pythonProject
        )
    }
    
    static func installPyModulesMultiPlatform(pythonProject: Path) -> Self {
        let ios_string = installPyModulesIphoneOS_Base(pythonProject: pythonProject).replacing("\n", with: "\n\t")
        let macos_string = installPyModulesMacOS_Base(pythonProject: pythonProject).replacing("\n", with: "\n\t")
        return """
        set -e
        if \(ios_condition); then
            echo "Installing Python modules for iOS Device/Simulator"
            \(ios_string)
        else
            echo "Installing Python modules for macOS"
            \(macos_string)
        fi
        """
    }
    
    static func InstallPyModulesBase(text: String, pythonProject: Path) -> Self {
        """
        set -e
        
        \(text)
        
        PYTHON="$PROJECT_DIR/python3"

        PY_APP="$CODESIGNING_FOLDER_PATH/app"
        rsync -au --delete "\(pythonProject)/" $PY_APP
        #$PYTHON -m compileall -f -b -o2 $PY_APP
        #find $PY_APP -regex '.*\\.py' -delete

        PY_SITE="$CODESIGNING_FOLDER_PATH/site_packages"
        #$PYTHON -m compileall -f -b -o2 $PY_SITE
        #find $PY_SITE -regex '.*\\.py' -print -delete
        #find $PY_SITE -name '__pycache__' -type d -print -exec rm -r {} + -depth
        """
    }
    
    static func installPyModulesIphoneOS_Base(pythonProject: Path) -> Self {
            """
            mkdir -p "$CODESIGNING_FOLDER_PATH/python/lib"
            if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
                echo "Installing Python modules for iOS Simulator"
                rsync -au --delete "$PROJECT_DIR/Support/ios-arm64_x86_64-simulator/lib/" "$CODESIGNING_FOLDER_PATH/python/lib/" 
                rsync -au --delete "$PROJECT_DIR/site_packages/iphonesimulator/" "$CODESIGNING_FOLDER_PATH/site_packages" 
            else
                echo "Installing Python modules for iOS Device"
                rsync -au --delete "$PROJECT_DIR/Support/ios-arm64/lib/" "$CODESIGNING_FOLDER_PATH/python/lib" 
                rsync -au --delete "$PROJECT_DIR/site_packages/iphoneos/" "$CODESIGNING_FOLDER_PATH/site_packages" 
            fi
            rsync -au --delete "$PROJECT_DIR/app/" "$CODESIGNING_FOLDER_PATH/app"
            """
    }
    
    static func installPyModulesMacOS_Base(pythonProject: Path) -> Self {
            """
            #mkdir -p "$CODESIGNING_FOLDER_PATH/python/lib"
            rsync -au --delete "$PROJECT_DIR/Support/macos-arm64_x86_64/lib/" "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/python/lib"
            
            SITE_DST="$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/site_packages"
            mkdir -p $SITE_DST
            mkdir -p "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/app"
            echo "Installing Python modules for macOS Device"
            rsync -au --delete "$PROJECT_DIR/site_packages/macos/" $SITE_DST
            rsync -au --delete "$PROJECT_DIR/app/" "$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/app"
            """
    }
}
