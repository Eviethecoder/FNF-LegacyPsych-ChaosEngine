package macros;

#if !display
#if macro
@:nullSafety
class FlxMacro
{
  /**
   * A macro to be called targeting the `FlxBasic` class.
   * @return An array of fields that the class contains. modified to add hscript class
   */
  public static macro function buildFlxBasic():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    // Add __hscript : Dynamic = null
    fields = fields.concat([
      {
        name: "__hscript",
        access: [haxe.macro.Expr.Access.APublic], // public, change if needed
        kind: haxe.macro.Expr.FieldType.FVar(
          macro :Dynamic,        // type
          macro $v{null}         // default value
        ),
        pos: pos
      }
    ]);

    return fields;
  }
}
#end
#end
