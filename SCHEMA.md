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

- **name** (required): Backend name
- **dependencies**: List of backend dependencies
- **frameworks**: Framework paths (supports `${PS_SUPPORT}` variable)
- **target_dependencies**: Xcode target dependencies (frameworks or packages)
- **packages**: Swift Package Manager packages
- **wrapper_imports**: Import configurations per platform
- **install**: Installation script configuration
- **copy_to_site_packages**: Site-packages copy script
- **will_modify_main_swift**: Whether main.swift modification is needed
- **modify_main_swift**: Main.swift modification script

## Platform Filters

- iOS
- macOS
- tvOS
- watchOS

## Example

Based on `src/kivyschool/kivy3launcher/backend.yml`:

```yaml
name: Kivy3Launcher
dependencies:
  - sdl3
frameworks: []
packages:
  KivyLauncher:
    url: https://github.com/kivy-school/KivyLauncher
    versionRequirement:
      branch: master
  Kivy_iOS_Module:
    url: https://github.com/kivy-school/Kivy_iOS_Module
    versionRequirement:
      branch: master

target_dependencies:
  - type: package
    reference: KivyLauncher
    products:
      - Kivy3Launcher
    
  - type: package
    reference: Kivy_iOS_Module
    products:
      - Kivy_iOS_Module
    platformFilter: iOS

wrapper_imports:
  all:
    libraries:
      - Kivy3Launcher
    modules: []
  iOS:
    libraries:
      - Kivy_iOS_Module
    modules:
      - .ios

copy_to_site_packages:
  type: shell
  shell: python
  file: site_packages_install.py

will_modify_main_swift:
  all: true

modify_main_swift:
  type: shell
  shell: python
  file: main_swift.py
```
