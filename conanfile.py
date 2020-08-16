from conans import ConanFile, tools, CMake

class GodotJsonEditorConan(ConanFile):
    name = "godot-json-editor"
    url = "https://github.com/hnOsmium0001/godot-json-editor"
    version = "1.2.0"
    settings = None
    exports_sources = "addons/json_editor/*"

    def build(self):
        # This plugin is GDscript only, which doesn't need to be builded at all
        pass

    def package(self):
        # Copy everything inside addon/json_editor
        self.copy("*")