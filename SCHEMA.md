# PySwift Backend Schema

This schema validates PySwift backend configuration files (backend.yml).

## Usage

### In YAML files
Add this comment at the top of your backend.yml:
```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Py-Swift/PSProject/master/backend-schema.json
```

### In VS Code
The schema is automatically applied to all `backend.yml` and `backend.yaml` files in this workspace.

## Schema Properties

### Core Properties
- **name** (required): Backend name
- **dependencies**: List of backend dependencies
- **backend_dependencies**: List of backend dependencies
- **exclude_dependencies**: List of dependencies to exclude

### Resources
- **downloads**: URLs of files to download
- **frameworks**: Framework paths (supports `${PS_SUPPORT}` variable)

### Target Configuration
- **target_dependencies**: Xcode target dependencies (frameworks or packages)
  - `type`: "framework" or "package"
  - `reference`: Path or package name
  - `products`: Product names (for packages)
  - `platformFilter`: iOS, macOS, tvOS, watchOS, visionOS

### Packages
- **packages**: Swift Package Manager packages
  - `url`: Git URL
  - `path`: Local path (alternative to url)
  - Version specifications:
    - `revision`: Git commit hash
    - `branch`: Git branch name
    - `exactVersion`: Exact semantic version
    - `versionRange`: Min/max version range
    - `upToNextMinorVersion`: Up to next minor
    - `upToNextMajorVersion`: Up to next major
    - `versionRequirement`: Legacy format (branch/version/revision)

### Code Generation
- **wrapper_imports**: Import configurations per platform
  - `libraries`: Library names to import
  - `modules`: Python modules to import

### Scripts
Scripts can be single objects or arrays of objects:

- **install**: Installation scripts
- **copy_to_site_packages**: Site-packages copy scripts
- **modify_main_swift**: Main.swift modification scripts

Each script supports:
- `type`: "shell"
- `shell`: python, bash, zsh, sh, ruby, fish
- `file`: Path to script file OR
- `run`: Inline script text

### Application Configuration
- **plist_entries**: Custom Info.plist entries (any valid plist structure)
- **will_modify_main_swift**: Per-platform flags (all/iOS/macOS/etc)

## Platform Filters

- iOS
- macOS
- tvOS
- watchOS
- visionOS

## Shell Types

- python
- bash
- zsh
- sh
- ruby
- fish

## Example

Complete example based on template:

```yaml
name: MyBackend
backend_dependencies: []
exclude_dependencies:
  - SomePackage
downloads:
  - http://example.com/file.zip

frameworks:
  - ${PS_SUPPORT}/MyFramework.xcframework

target_dependencies:
  - type: framework
    reference: Support/MyFramework.xcframework
    platformFilter: iOS
  - type: package
    reference: MyPackage
    products:
      - MyProduct
    platformFilter: iOS

packages:
  Package1:
    url: https://github.com/user/Package1
    branch: master
  Package2:
    url: https://github.com/user/Package2
    exactVersion: "1.0.0"
  Package3:
    path: ../local-packages/Package3

wrapper_imports:
  all:
    libraries:
      - MyLibrary
    modules: []
  iOS:
    libraries:
      - IOSLibrary
    modules:
      - .ios_module

install:
  - type: shell
    shell: python
    file: install.py
  - type: shell
    shell: bash
    run: |
      echo "Installing..."

copy_to_site_packages:
  type: shell
  shell: python
  file: site_packages_install.py

plist_entries:
  CFBundleURLTypes:
    - CFBundleURLName: com.example.app
      CFBundleURLSchemes:
        - example-scheme
  NSAppTransportSecurity:
    NSAllowsArbitraryLoads: true

will_modify_main_swift:
  all: false
  iOS: true

modify_main_swift:
  type: shell
  shell: python
  file: main_swift.py
```
