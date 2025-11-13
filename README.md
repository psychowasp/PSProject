# PSProject

Tool to create PySwiftKit based Apps

## Installation

### Homebrew (Recommended)

First, add the Homebrew tap:

```bash
brew tap PythonSwiftLink/tools
```

Then install PSProject:

```bash
brew install psproject
```

To upgrade PSProject:

```bash
brew update
brew upgrade --formula psproject
```

### From Source

Alternatively, you can build PSProject from source using Swift Package Manager.

## Usage

### Create a New Project

First, create a new project which will generate a `pyproject.toml` file:

```bash
psproject init HelloWorld
```

Navigate to the new project directory:

```bash
cd HelloWorld
```

Or open it in VS Code:

```bash
code HelloWorld
```

### Configure for Kivy

The generated `pyproject.toml` will contain default configuration. To create a Kivy-based app, add Kivy to the project dependencies and configure the PSProject backends:

```toml
[project]
name = "helloworld"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "kivy"
]

[tool.psproject]
app_name = "HelloWorld"
backends = [
    "kivyschool.kivylauncher"
]
cythonized = false
extra_index = []
pip_install_app = false

[tool.psproject.ios]
backends = []
extra_index = [
    "https://pypi.anaconda.org/beeware/simple",
    "https://pypi.anaconda.org/pyswift/simple",
    "https://pypi.anaconda.org/kivyschool/simple"
]
```

### Create Xcode Project

Generate the Xcode project:

```bash
psproject create xcode
```

### Update Site Packages

To update the Xcode project's site-packages:

```bash
psproject update site-packages
```

## Additional Resources

- [PySwiftKit Wiki](https://py-swift.github.io/wiki/)
- [Setup Guide](https://py-swift.github.io/wiki/setup/)
- [Kivy Project Documentation](https://py-swift.github.io/wiki/project/kivy/create/)
- [PyProject Configuration](https://py-swift.github.io/wiki/project/kivy/pyproject-configuration/)

## License

MIT License - See LICENSE file for details
