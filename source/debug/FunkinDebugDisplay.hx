package debug;

import flixel.util.FlxStringUtil;
import debug.FunkinStatsGraph;
import flixel.FlxG;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import flixel.system.debug.stats.Stats;
import openfl.text.TextFormat;

/**
 * A debug overlay showing useful info. 
 * Ported from v-slice to Psych Engine 
 */
class FunkinDebugDisplay extends Sprite
{
    var isDragging:Bool = false;
    var dragOffsetX:Float = 0;
    var dragOffsetY:Float = 0;

    static final UPDATE_DELAY:Int = 100;
    static final INNER_RECT_DIFF:Int = 3;
    static final OUTER_RECT_DIMENSIONS:Array<Int> = [234, 201];
    static final OTHERS_OFFSET:Int = 8;



  
    public var isAdvanced(default, set):Bool = false;
    public var backgroundOpacity(default, set):Float = 0.5;

    var currentFPS:Int;
    var deltaTimeout:Float;
    var times:Array<Float>;
    var color:Int;

    #if !html5
    var gcMem:Float;
    var gcMemPeak:Float;

    var taskMem:Float;
    var taskMemPeak:Float;
    #end

    var background:Shape;

    var fpsGraph:FunkinStatsGraph;
    var gcMemGraph:FunkinStatsGraph;
    var taskMemGraph:FunkinStatsGraph;

    var infoDisplay:TextField;

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000):Void
    {
        super();
        this.x = x;
        this.y = y;
        this.currentFPS = 0;
        this.deltaTimeout = 0.0;
        #if !html5
        this.gcMem = 0.0;
        this.gcMemPeak = 0.0;
        this.taskMem = 0.0;
        this.taskMemPeak = 0.0;
        #end
        this.times = [];
        this.color = color;
        this.backgroundOpacity = 0;
        this.isAdvanced = false;

        
        this.addEventListener("mouseDown", onMouseDown);
        this.addEventListener("mouseUp", onMouseUp);
        this.addEventListener("mouseMove", onMouseMove);
    }

    function onMouseDown(e:Dynamic):Void {
        isDragging = true;
        dragOffsetX = e.stageX - this.x;
        dragOffsetY = e.stageY - this.y;
    }

    function onMouseUp(e:Dynamic):Void {
        isDragging = false;
    }

    function onMouseMove(e:Dynamic):Void {
        if (isDragging) {
            this.x = e.stageX - dragOffsetX;
            this.y = e.stageY - dragOffsetY;
        }
    }

    function buildDebugDisplay(advanced:Bool):Void
    {
        removeChildren(0, numChildren);

        final BG_WIDTH_MULTIPLIER:Float = #if html5 advanced ? 1 : 0.3 #else 1 #end;
        final BG_HEIGHT_MULTIPLIER:Float = advanced ? 1 : (supportsTaskMem()) ? 0.3 : 0.2;
        var alpha = 0.5;

        background = new Shape();
        background.graphics.beginFill(0x3d3f41, 1);
        background.graphics.drawRect(0, 0, (OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER) + (INNER_RECT_DIFF * 2),
                                     (OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER) + (INNER_RECT_DIFF * 2));
        background.graphics.endFill();
        background.graphics.beginFill(0x2c2f30, 1);
        background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF,
                                     OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER,
                                     OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER);
        background.graphics.endFill();
        switch(advanced){
          case true:
             background.alpha = alpha;
          case false:
            background.alpha = backgroundOpacity;


        }
        addChild(background);

        if (advanced) {
            createAdvancedElements();
            updateAdvancedDisplay();
        } else {
            createSimpleElements();
            updateSimpleDisplay();
        }
    }

    function createAdvancedElements():Void
    {
        final graphsWidth:Int = OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2) - (OTHERS_OFFSET * 3);
        final graphsHeight:Int = 25;

        fpsGraph = new FunkinStatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + 49, graphsWidth, graphsHeight, 0xFF0000);
        fpsGraph.textDisplay.y = -49;
        fpsGraph.minValue = 0;
        addChild(fpsGraph);

        #if !html5
        gcMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), graphsWidth, graphsHeight, 0xFF0000);
        gcMemGraph.minValue = 0;
        addChild(gcMemGraph);

         taskMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), graphsWidth, graphsHeight,
        color);
        taskMemGraph.minValue = 0;
        addChild(taskMemGraph);
        #end
    }

    function createSimpleElements():Void
    {
        infoDisplay = new TextField();
        infoDisplay.x = OTHERS_OFFSET;
        infoDisplay.y = OTHERS_OFFSET;
        infoDisplay.width = 500;
        infoDisplay.selectable = false;
        infoDisplay.mouseEnabled = false;
        infoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, 0xFF0000);
        infoDisplay.antiAliasType = NORMAL;
        infoDisplay.sharpness = 100;
        infoDisplay.multiline = true;
        addChild(infoDisplay);
    }

    override function __enterFrame(deltaTime:Float):Void
    {
        // Cross-platform current time in milliseconds
        final currentTime:Float = 
            #if cpp
                Sys.time() * 1000;
            #elseif html5
                js.Browser.window.performance.now();
            #else
                haxe.Timer.stamp() * 1000;
            #end

        times.push(currentTime);

        while (times[0] < currentTime - 1000)
            times.shift();

        if (deltaTimeout < UPDATE_DELAY) {
            deltaTimeout += deltaTime;
            return;
        }

        currentFPS = times.length;

        #if !html5
        gcMem =  openfl.system.System.totalMemoryNumber;
        if (gcMem > gcMemPeak) gcMemPeak = gcMem;
        taskMem = getTaskMemory();
        if (taskMem > taskMemPeak) taskMemPeak = taskMem;


        #end

        if (isAdvanced)
            updateAdvancedDisplay();
        else
            updateSimpleDisplay();

        deltaTimeout = 0.0;
    }

    function updateAdvancedDisplay():Void
    {
        updateFPSGraph();
        #if !html5
        updateGcMemGraph();
        updateTaskMemGraph();
        #end

        final info:Array<String> = [];
        info.push('FPS: $currentFPS');
        info.push('AVG FPS: ${Math.floor(fpsGraph.average())}');
        info.push('1% LOW FPS: ${Math.floor(fpsGraph.lowest())}');
        fpsGraph.textDisplay.text = info.join('\n');

        #if !html5
        gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}';
        if (taskMemGraph != null)
            taskMemGraph.textDisplay.text = 'TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}';
        #end
    }

    function updateSimpleDisplay():Void
    {
        if (infoDisplay != null) {
            final info:Array<String> = [];
            info.push('FPS: $currentFPS');
            #if !html5
            info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}');
            #end
            infoDisplay.text = info.join('\n');
        }
    }

    function updateFPSGraph(?currentFPS:Int = 0):Void
    {
        fpsGraph.maxValue = FlxG.drawFramerate;
        fpsGraph.update(times.length);
    }

    #if !html5
    function updateGcMemGraph(?currentFPS:Int = 0):Void
    {
        gcMemGraph.maxValue = gcMemPeak;
        gcMemGraph.update(gcMem);
    }


    public static function getTaskMemory():Float
    {
        #if (windows && cpp)
        return external.WinAPI.getProcessMemoryWorkingSetSize();
        #elseif ((ios || macos) && cpp)
       // return funkin.external.apple.MemoryUtil.getCurrentProcessRss();
        #elseif (linux || android)
        try
        {
        #if cpp
        final input:sys.io.FileInput = sys.io.File.read('/proc/${cpp.NativeSys.sys_get_pid()}/status', false);
        #else
        final input:sys.io.FileInput = sys.io.File.read('/proc/self/status', false);
        #end

        final regex:EReg = ~/^VmRSS:\s+(\d+)\s+kB/m;
        var line:String;
        do
        {
            if (input.eof())
            {
            input.close();
            return 0.0;
            }
            line = input.readLine();
        } while (!regex.match(line));

        input.close();

        final kb:Float = Std.parseFloat(regex.matched(1));

        if (!Math.isNaN(kb))
        {
            return kb * 1024.0;
        }
        }
        catch (e:Dynamic)
        {
        }
        #end

        return 0.0;
  }

    function updateTaskMemGraph(?currentFPS:Int = 0):Void
    {
        if (taskMemGraph != null) {
            taskMemGraph.maxValue = taskMemPeak;
            taskMemGraph.update(taskMem);
        }
    }
    #end

    function set_isAdvanced(value:Bool):Bool
    {
        buildDebugDisplay(value);
        return isAdvanced = value;
    }

    function set_backgroundOpacity(value:Float):Float
    {
        if (background != null) background.alpha = value;
        return backgroundOpacity = value;
    }
      public static function supportsTaskMem():Bool
    {
      #if ((cpp && (windows || ios || macos)) || linux || android)
      return true;
      #else
      return false;
      #end
    }
}

enum abstract DebugDisplayMode(Int) from Int to Int
{
    var OFF = 0;
    var SIMPLE = 1;
    var ADVANCED = 2;
}
