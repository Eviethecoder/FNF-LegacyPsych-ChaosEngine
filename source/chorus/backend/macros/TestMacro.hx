package macros;

#if macro 
import haxe.macro.ExprTools;
import haxe.macro.Context;
import haxe.macro.Expr;

class TestMacro {

    macro public static function build():Array<Field> {
        var fields = Context.getBuildFields(); 
        fields.push({
            name: "__hscript",
            access:  [Access.APrivate],
            kind: FieldType.FVar(macro:Dynamic, macro $v{null}), 
            pos: Context.currentPos(),
        }); 

        for (field in fields) {  
            switch (field.kind) {
                case FFun(f):
                    if(field.name == "new") 
                        continue;  
                    
                    var omg:Expr = macro if(output != null && output.__fn == 'skip')
                                    return output.__value;
                    
                    if(f.ret == null || f.ret.getParameters()[0] == 'Void')
                    {
                        omg = macro {
                            if(output != null && output.__fn == 'skip')
                                return;
                        };
                    } 
 
                    var yo:String = '[ ';
                    for (s in f.args) { 
                        yo += s.name + ',';
                    } 
                    yo = yo.substring(0, yo.length - 1);
                    yo += ']'; 

                    var expr = Context.parse(yo, Context.currentPos());

                    var injected = macro {
                        if (__hscript != null) { 
                            var __array:Array<Dynamic> = $expr;
                            var output = __hscript.runFunction($v{field.name}, __array); 
                            $omg;
                        }
                    };

                    f.expr = macro {
                        $injected;
                        ${f.expr};
                    };
                    field.kind = FFun(f); 
                default:
            }
        }
        return fields;
    }
}
#end 