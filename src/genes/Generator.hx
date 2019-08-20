package genes;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.JSGenApi;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import genes.generator.es.ModuleGenerator;
import genes.generator.dts.DefinitionGenerator;

using Lambda;
using StringTools;

class Generator {
  static function generate(api: JSGenApi) {
    final toGenerate = typesPerModule(api.types);
    final output = Path.withoutExtension(Path.withoutDirectory(api.outputFile));
    final modules = new Map();
    function addModule(module: String, types: Array<Type>,
        ?main: Null<TypedExpr>)
      modules.set(module, new Module(module, types, main));
    switch api.main {
      case null:
      case v:
        addModule(output, switch toGenerate.get(output) {
          case null: [];
          case v: v;
        }, v);
    }
    for (module => types in toGenerate)
      if (module != output)
        addModule(module, types);
    for (module in modules)
      generateModule(api, module);
    return modules;
  }

  static function typesPerModule(types: Array<Type>) {
    final modules = new Map<String, Array<Type>>();
    for (type in types) {
      switch type {
        // Todo: init extern inst
        case TInst(_.get() => {
          module: module,
          isExtern: false
        }, _) | TEnum(_.get() => {
            module: module,
            isExtern: false
          }, _) | TType(_.get() => {
            module: module,
            isExtern: false
          }, _):
          if (modules.exists(module))
            modules.get(module).push(type);
          else
            modules.set(module, [type]);
        default:
      }
    }
    return modules;
  }

  static function generateModule(api: JSGenApi, module: Module) {
    final outputDir = Path.directory(api.outputFile);
    function save(file: String, content: String) {
      final path = Path.join([outputDir, file]);
      final dir = Path.directory(path);
      if (!FileSystem.exists(dir))
        FileSystem.createDirectory(dir);
      File.saveContent(path, content);
    }
    ModuleGenerator.module(api, save, module);
  }

  #if macro
  public static function use() {
    Compiler.setCustomJSGenerator(Generator.generate);
  }
  #end
}
