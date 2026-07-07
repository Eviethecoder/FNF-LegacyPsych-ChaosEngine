package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import meta.data.*;
import objects.FunkinSprite;
import Character.IconData as IconData;

using StringTools;

class HealthIcon extends FunkinSprite
{
	// This backend is slightly stolen from V-Slice. Support the official release.
	public var sprTracker:FlxSprite;

	public var animOffsets:Map<String, Array<Dynamic>>;

	private var isOldIcon:Bool = false;

	public var isPlayer:Bool = false;
	public var char:String = '';
	public var icontype:String = '';
	public var animoveride:Bool = false;
	public var autoUpdate:Bool = true;
	public var autoAdjustY:Bool = true;
	public var icondata:Character.IconData;
	public var iconOffset:Int = 26;
	public var iconPosOffset:Array<Float> = [0, 0];

	private var baseIconWidth:Float = HEALTH_ICON_SIZE;

	/**
	 * The size of a non-pixel icon when using the legacy format.
	 * Remember, modern icons can be any size.
	 */
	public static final HEALTH_ICON_SIZE:Int = 150;

	/**
	 * The size of a pixel icon when using the legacy format.
	 * Remember, modern icons can be any size.
	 */
	static final PIXEL_ICON_SIZE:Int = 32;

	/**
	 * At this amount of health, play the winning animation instead of idle.
	 */
	static final WINNING_THRESHOLD:Float = 80;

	/**
	 * At this amount of health, play the losing animation instead of idle.
	 */
	static final LOSING_THRESHOLD:Float = 20;

	public var islegacy:Bool = false;

	public function new(iconData:IconData, isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		this.icondata = iconData;

		changeIcon(this.icondata);
		flipX = isPlayer;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
		}

		if (!autoUpdate || PlayState.instance == null)
		{
			return;
		}

		var healthPercent:Float = PlayState.instance.hud.healthBar.percent;
		var mult:Float = FlxMath.lerp(1, scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * PlayState.instance.playbackRate), 0, 1));
		scale.set(mult, mult);
		updateHitbox();

		var healthBar = PlayState.instance.hud.healthBar;
		var barCenterY:Float = healthBar.y + ((healthBar.barOffset.y + (healthBar.barHeight * 0.5)) * healthBar.scale.y);
		if (autoAdjustY)
		{
			y = barCenterY - (height * 0.5) + iconPosOffset[1];
		}
		switch (isPlayer)
		{
			case true:
				updateHealthIcon(healthPercent);
				if (PlayState.instance.hud.hudData.iconp1overide == null)
				{
					x = healthBar.x
						+ (healthBar.width * (FlxMath.remapToRange(healthPercent, 0, 100, 100, 0) * 0.01))
						+ (baseIconWidth * scale.x - baseIconWidth) / 2
						- iconOffset;
				}
			case false:
				updateHealthIcon(100 - healthPercent);
				if (PlayState.instance.hud.hudData.iconp2overide == null)
				{
					x = healthBar.x
						+ (healthBar.width * (FlxMath.remapToRange(healthPercent, 0, 100, 100, 0) * 0.01))
						- (baseIconWidth * scale.x) / 2
						- iconOffset * 2;
				}
		}
	}

	function loadAnimationNew():Void
	{
		animation.addByPrefix(Neutral, "Neutral", 24, true);
		animation.addByPrefix(Winning, "Winning", 24, true);
		animation.addByPrefix(Losing, "Losing", 24, true);
		animation.addByPrefix(ToWinning, "ToWinning", 24, false);
		animation.addByPrefix(ToLosing, "ToLosing", 24, false);
		animation.addByPrefix(FromWinning, "FromWinning", 24, false);
		animation.addByPrefix(FromLosing, "FromLosing", 24, false);
	}

	function loadAnimationOld():Void
	{
		animation.add(Neutral, [0], 0, false, false);
		animation.add(Losing, [1], 0, false, false);
		if (animation.numFrames >= 3)
		{
			animation.add(Winning, [2], 0, false, false);
		}
	}

	public function playAnimation(name:String, fallback:String = null, restart:Bool = false):Void
	{
		if (hasAnimation(name))
		{
			var daOffset = animOffsets.get(name);
			if (animOffsets.exists(name))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);
			animation.play(name, restart, false, 0);
			return;
		}

		if (fallback != null && hasAnimation(fallback))
		{
			var daOffset = animOffsets.get(fallback);
			if (animOffsets.exists(fallback))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);
			animation.play(fallback, restart, false, 0);
		}
	}

	public function changeIcon(newicondata:IconData):Void
	{
		if (newicondata != null)
		{
			icondata = newicondata;
		}
		trace('icon data is: ' + icondata);
		var charId = icondata.healthicon;
		if (charId == null || !iconExists(charId))
		{
			FlxG.log.warn('No icon for character: $charId : using default placeholder face instead!');
			charId = Constants.DEFAULT_HEALTH_ICON;
		}

		char = charId;
		var iconPath = 'characters/icons/icon-$charId';
		var isPixel = isPixelIcon(charId);

		islegacy = !isNewSpritesheet(charId);
		trace('Loading health icon for character: $charId (legacy: $islegacy)');

		if (!islegacy)
		{
			trace('Loading new spritesheet for health icon: ' + iconPath);
			frames = Paths.getSparrowAtlas(iconPath);
			loadAnimationNew();
		}
		else
		{
			loadGraphic(Paths.image(iconPath), true, isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE, isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE);
			loadAnimationOld();
		}

		antialiasing = !isPixel;
		playAnimation(Neutral, Neutral, true);
		for (iconOffsetData in icondata.iconOffsets)
		{
			addOffset(iconOffsetData.animname, iconOffsetData.offsets[0], iconOffsetData.offsets[1]);
		}
		updateHitbox();
		baseIconWidth = frameWidth > 0 ? frameWidth : HEALTH_ICON_SIZE;
	}

	function iconExists(charId:String):Bool
	{
		return Paths.fileExists('images/characters/icons/icon-$charId.png', IMAGE);
	}

	public function addOffset(name:String, x:Float = 0,
			y:Float = 0) // we need to edit this, but make sure if their is no extra offsets then it defaults to 0, 0 instead of null, which causes errors
	{
		animOffsets[name] = [x, y];
	}

	function isNewSpritesheet(charId:String):Bool
	{
		return Paths.fileExists('images/characters/icons/icon-$charId.xml', TEXT);
	}

	inline function isPixelIcon(charId:String):Bool
	{
		return charId.endsWith('-pixel');
	}

	public function getCharacter():String
	{
		return char;
	}

	public function bop():Void
	{
		if (autoUpdate)
		{
			scale.set(1.2, 1.2);
		}
	}

	function updateHealthIcon(health:Float):Void
	{
		switch (getCurrentAnimation())
		{
			case Neutral:
				if (health < LOSING_THRESHOLD)
				{
					playAnimation(ToLosing, Losing);
				}
				else if (health > WINNING_THRESHOLD)
				{
					playAnimation(ToWinning, Winning);
				}
				else
				{
					playAnimation(Neutral);
				}
			case Winning:
				if (health < WINNING_THRESHOLD)
				{
					playAnimation(FromWinning, Neutral);
				}
				else
				{
					playAnimation(Winning, Neutral);
				}
			case Losing:
				if (health > LOSING_THRESHOLD)
				{
					playAnimation(FromLosing, Neutral);
				}
				else
				{
					playAnimation(Losing, Neutral);
				}
			case ToLosing:
				if (isAnimationFinished())
				{
					playAnimation(Losing, Neutral);
				}
			case ToWinning:
				if (isAnimationFinished())
				{
					playAnimation(Winning, Neutral);
				}
			case FromLosing | FromWinning:
				if (isAnimationFinished())
				{
					playAnimation(Neutral);
				}
			case '':
				playAnimation(Neutral);
			default:
				playAnimation(Neutral);
		}
	}
}

enum abstract HealthIconState(String) to String from String
{
	public var Neutral = 'Neutral';
	public var Winning = 'winning';
	public var Losing = 'losing';
	public var ToWinning = 'toWinning';
	public var ToLosing = 'toLosing';
	public var FromWinning = 'fromWinning';
	public var FromLosing = 'fromLosing';
}
