
package debug;

class ConsoleCore
{
    public static var instance:ConsoleCore;

    var commands:Map<String, Dynamic> = [];

    public function new()
    {
        instance = this;
    }

    public function register(name:String, func:Dynamic)
    {
        commands.set(name.toLowerCase(), func);
    }

    public function execute(cmd:String)
    {
        var ui = ConsolePlugin.instance.ui;

        ui.print("> " + cmd);

        var parts = cmd.split(" ");
        var name = parts.shift().toLowerCase();

        if (commands.exists(name))
        {
            try
            {
                Reflect.callMethod(null, commands.get(name), parts);
            }
            catch (e)
            {
                ui.print("Error: " + e);
            }
        }
        else
        {
            ui.print("Unknown command");
        }
    }
}