package objects;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import imgui.ImGui;
import lime.graphics.RenderContext;
import objects.Cursor;
import openfl.events.KeyboardEvent;

#if windows // if we dont do this it wont render
@:cppFileCode('
#ifdef _WIN32
#include <windows.h>

typedef unsigned int GLenum;
typedef unsigned int GLuint;
typedef int GLint;
typedef int GLsizei;
typedef unsigned char GLboolean;
typedef unsigned char GLubyte;
typedef float GLfloat;
typedef char GLchar;
typedef ptrdiff_t GLsizeiptr;
typedef ptrdiff_t GLintptr;
typedef void GLvoid;

#define GL_FALSE 0
#define GL_TRUE 1
#define GL_TRIANGLES 4
#define GL_SRC_ALPHA 0x0302
#define GL_ONE_MINUS_SRC_ALPHA 0x0303
#define GL_FRONT_AND_BACK 0x0408
#define GL_CULL_FACE 0x0B44
#define GL_POLYGON_MODE 0x0B40
#define GL_DEPTH_TEST 0x0B71
#define GL_STENCIL_TEST 0x0B90
#define GL_VIEWPORT 0x0BA2
#define GL_BLEND 0x0BE2
#define GL_SCISSOR_BOX 0x0C10
#define GL_SCISSOR_TEST 0x0C11
#define GL_UNPACK_ROW_LENGTH 0x0CF2
#define GL_TEXTURE_2D 0x0DE1
#define GL_UNSIGNED_BYTE 0x1401
#define GL_UNSIGNED_SHORT 0x1403
#define GL_UNSIGNED_INT 0x1405
#define GL_FLOAT 0x1406
#define GL_RGBA 0x1908
#define GL_FILL 0x1B02
#define GL_VERSION 0x1F02
#define GL_TEXTURE_MAG_FILTER 0x2800
#define GL_TEXTURE_MIN_FILTER 0x2801
#define GL_TEXTURE_WRAP_S 0x2802
#define GL_TEXTURE_WRAP_T 0x2803
#define GL_LINEAR 0x2601
#define GL_CLAMP_TO_EDGE 0x812F
#define GL_TEXTURE_BINDING_2D 0x8069
#define GL_FUNC_ADD 0x8006
#define GL_BLEND_EQUATION_RGB 0x8009
#define GL_BLEND_DST_RGB 0x80C8
#define GL_BLEND_SRC_RGB 0x80C9
#define GL_BLEND_DST_ALPHA 0x80CA
#define GL_BLEND_SRC_ALPHA 0x80CB
#define GL_TEXTURE0 0x84C0
#define GL_ACTIVE_TEXTURE 0x84E0
#define GL_VERTEX_ARRAY_BINDING 0x85B5
#define GL_BLEND_EQUATION_ALPHA 0x883D
#define GL_ARRAY_BUFFER 0x8892
#define GL_ELEMENT_ARRAY_BUFFER 0x8893
#define GL_ARRAY_BUFFER_BINDING 0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING 0x8895
#define GL_STREAM_DRAW 0x88E0
#define GL_FRAGMENT_SHADER 0x8B30
#define GL_VERTEX_SHADER 0x8B31
#define GL_COMPILE_STATUS 0x8B81
#define GL_LINK_STATUS 0x8B82
#define GL_INFO_LOG_LENGTH 0x8B84
#define GL_CURRENT_PROGRAM 0x8B8D
#define GL_MAJOR_VERSION 0x821B
#define GL_MINOR_VERSION 0x821C
#define GL_UNPACK_ALIGNMENT 0x0CF5

#define GLF(ret, name, args) static ret (__stdcall *name) args = 0;
GLF(void, glBindTexture, (GLenum, GLuint))
GLF(void, glBlendFunc, (GLenum, GLenum))
GLF(void, glDeleteTextures, (GLsizei, const GLuint*))
GLF(void, glDisable, (GLenum))
GLF(void, glEnable, (GLenum))
GLF(void, glDrawElements, (GLenum, GLsizei, GLenum, const void*))
GLF(void, glGenTextures, (GLsizei, GLuint*))
GLF(void, glGetIntegerv, (GLenum, GLint*))
GLF(const GLubyte*, glGetString, (GLenum))
GLF(GLboolean, glIsEnabled, (GLenum))
GLF(void, glPixelStorei, (GLenum, GLint))
GLF(void, glPolygonMode, (GLenum, GLenum))
GLF(void, glScissor, (GLint, GLint, GLsizei, GLsizei))
GLF(void, glTexImage2D, (GLenum, GLint, GLint, GLsizei, GLsizei, GLint, GLenum, GLenum, const void*))
GLF(void, glTexParameteri, (GLenum, GLenum, GLint))
GLF(void, glViewport, (GLint, GLint, GLsizei, GLsizei))
GLF(void, glActiveTexture, (GLenum))
GLF(void, glAttachShader, (GLuint, GLuint))
GLF(void, glBindBuffer, (GLenum, GLuint))
GLF(void, glBindVertexArray, (GLuint))
GLF(void, glBlendEquation, (GLenum))
GLF(void, glBlendEquationSeparate, (GLenum, GLenum))
GLF(void, glBlendFuncSeparate, (GLenum, GLenum, GLenum, GLenum))
GLF(void, glBufferData, (GLenum, GLsizeiptr, const void*, GLenum))
GLF(void, glCompileShader, (GLuint))
GLF(GLuint, glCreateProgram, (void))
GLF(GLuint, glCreateShader, (GLenum))
GLF(void, glDeleteBuffers, (GLsizei, const GLuint*))
GLF(void, glDeleteProgram, (GLuint))
GLF(void, glDeleteShader, (GLuint))
GLF(void, glDeleteVertexArrays, (GLsizei, const GLuint*))
GLF(void, glDetachShader, (GLuint, GLuint))
GLF(void, glEnableVertexAttribArray, (GLuint))
GLF(void, glGenBuffers, (GLsizei, GLuint*))
GLF(void, glGenVertexArrays, (GLsizei, GLuint*))
GLF(GLint, glGetAttribLocation, (GLuint, const GLchar*))
GLF(void, glGetProgramInfoLog, (GLuint, GLsizei, GLsizei*, GLchar*))
GLF(void, glGetProgramiv, (GLuint, GLenum, GLint*))
GLF(void, glGetShaderInfoLog, (GLuint, GLsizei, GLsizei*, GLchar*))
GLF(void, glGetShaderiv, (GLuint, GLenum, GLint*))
GLF(GLint, glGetUniformLocation, (GLuint, const GLchar*))
GLF(void, glLinkProgram, (GLuint))
GLF(void, glShaderSource, (GLuint, GLsizei, const GLchar* const*, const GLint*))
GLF(void, glUniform1i, (GLint, GLint))
GLF(void, glUniformMatrix4fv, (GLint, GLsizei, GLboolean, const GLfloat*))
GLF(void, glUseProgram, (GLuint))
GLF(void, glVertexAttribPointer, (GLuint, GLint, GLenum, GLboolean, GLsizei, const void*))

static void* imguiGlProc(const char* name)
{
    HMODULE gl = GetModuleHandleA("opengl32.dll");
    if (!gl) return 0;
    typedef void* (__stdcall *GetProc)(const char*);
    GetProc wglProc = (GetProc)GetProcAddress(gl, "wglGetProcAddress");
    void* p = wglProc ? wglProc(name) : 0;
    if (p == 0 || p == (void*)1 || p == (void*)2 || p == (void*)3 || p == (void*)-1)
        p = (void*)GetProcAddress(gl, name);
    return p;
}

static bool imguiGlLoad()
{
    bool ok = true;
#define GLL(name) name = (decltype(name))imguiGlProc(#name); if (!name) ok = false;
    GLL(glBindTexture) GLL(glBlendFunc) GLL(glDeleteTextures) GLL(glDisable) GLL(glEnable)
    GLL(glDrawElements) GLL(glGenTextures) GLL(glGetIntegerv) GLL(glGetString) GLL(glIsEnabled)
    GLL(glPixelStorei) GLL(glPolygonMode) GLL(glScissor) GLL(glTexImage2D) GLL(glTexParameteri)
    GLL(glViewport) GLL(glActiveTexture) GLL(glAttachShader) GLL(glBindBuffer) GLL(glBindVertexArray)
    GLL(glBlendEquation) GLL(glBlendEquationSeparate) GLL(glBlendFuncSeparate) GLL(glBufferData)
    GLL(glCompileShader) GLL(glCreateProgram) GLL(glCreateShader) GLL(glDeleteBuffers)
    GLL(glDeleteProgram) GLL(glDeleteShader) GLL(glDeleteVertexArrays) GLL(glDetachShader)
    GLL(glEnableVertexAttribArray) GLL(glGenBuffers) GLL(glGenVertexArrays) GLL(glGetAttribLocation)
    GLL(glGetProgramInfoLog) GLL(glGetProgramiv) GLL(glGetShaderInfoLog) GLL(glGetShaderiv)
    GLL(glGetUniformLocation) GLL(glLinkProgram) GLL(glShaderSource) GLL(glUniform1i)
    GLL(glUniformMatrix4fv) GLL(glUseProgram) GLL(glVertexAttribPointer)
    return ok;
}

#define IMGUI_IMPL_OPENGL_LOADER_CUSTOM <stddef.h>
#include "backends/imgui_impl_opengl3.cpp"

static GLuint imguiCursorTexture = 0;

static void imguiGlSetCursorTexture(int width, int height, Array<unsigned char> pixels)
{
    if (imguiCursorTexture == 0)
        glGenTextures(1, &imguiCursorTexture);

    GLint previousTexture = 0;
    GLint previousUnpackAlignment = 4;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &previousTexture);
    glGetIntegerv(GL_UNPACK_ALIGNMENT, &previousUnpackAlignment);
    glBindTexture(GL_TEXTURE_2D, imguiCursorTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels->GetBase());
    glPixelStorei(GL_UNPACK_ALIGNMENT, previousUnpackAlignment);
    glBindTexture(GL_TEXTURE_2D, previousTexture);
}

static void imguiGlDrawCursor(float x, float y, float width, float height)
{
    ImGui::GetForegroundDrawList()->AddImage(
        (ImTextureID)(intptr_t)imguiCursorTexture,
        ImVec2(x, y),
        ImVec2(x + width, y + height),
        ImVec2(0, 0),
        ImVec2(1, 1));
}

static bool imguiGlInit() { return imguiGlLoad() && ImGui_ImplOpenGL3_Init(NULL); }
static void imguiGlNewFrame() { ImGui_ImplOpenGL3_NewFrame(); }
static void imguiGlRender() { ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData()); }
static void imguiGlShutdown()
{
    ImGui_ImplOpenGL3_Shutdown();
    if (imguiCursorTexture != 0)
        glDeleteTextures(1, &imguiCursorTexture);
    imguiCursorTexture = 0;
}
#endif
')
#end
class FlxImGui
{
	private var imguiGlReady:Bool = false;
	private var imguiFrameReady:Bool = false;
	private var imguiMouseWasVisible:Bool = false;
	private var imguiMouseWasUsingSystemCursor:Bool = false;
	private var drawImGuiCallback:Void->Void;

	public var colors:Dynamic;

	public function new(drawImGuiCallback:Void->Void)
	{
		this.drawImGuiCallback = drawImGuiCallback;
		ImGui.createContext();

		#if windows
		imguiGlReady = untyped __cpp__('imguiGlInit()');
		if (!imguiGlReady)
			trace('ImGui OpenGL3 backend failed to initialize');
		else
		{
			var io = ImGui.getIO();
			io.keyMap[ImGuiKey.Tab] = FlxKey.TAB;
			io.keyMap[ImGuiKey.LeftArrow] = FlxKey.LEFT;
			io.keyMap[ImGuiKey.RightArrow] = FlxKey.RIGHT;
			io.keyMap[ImGuiKey.UpArrow] = FlxKey.UP;
			io.keyMap[ImGuiKey.DownArrow] = FlxKey.DOWN;
			io.keyMap[ImGuiKey.PageUp] = FlxKey.PAGEUP;
			io.keyMap[ImGuiKey.PageDown] = FlxKey.PAGEDOWN;
			io.keyMap[ImGuiKey.Home] = FlxKey.HOME;
			io.keyMap[ImGuiKey.End] = FlxKey.END;
			io.keyMap[ImGuiKey.Delete] = FlxKey.DELETE;
			io.keyMap[ImGuiKey.Backspace] = FlxKey.BACKSPACE;
			io.keyMap[ImGuiKey.Enter] = FlxKey.ENTER;
			io.keyMap[ImGuiKey.Escape] = FlxKey.ESCAPE;
			io.keyMap[ImGuiKey.Insert] = FlxKey.INSERT;
			io.keyMap[ImGuiKey.Space] = FlxKey.SPACE;
			io.keyMap[ImGuiKey.A] = FlxKey.A;
			io.keyMap[ImGuiKey.C] = FlxKey.C;
			io.keyMap[ImGuiKey.V] = FlxKey.V;
			io.keyMap[ImGuiKey.X] = FlxKey.X;
			io.keyMap[ImGuiKey.Y] = FlxKey.Y;
			io.keyMap[ImGuiKey.Z] = FlxKey.Z;

			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onImGuiKeyDown);
			imguiMouseWasVisible = FlxG.mouse.visible;
			imguiMouseWasUsingSystemCursor = FlxG.mouse.useSystemCursor;
			if (FlxG.mouse.cursor == null)
				FlxG.mouse.load();
			FlxG.mouse.useSystemCursor = false;
			FlxG.mouse.visible = false;
			ImGui.getIO().mouseDrawCursor = false;
			Cursor.updateImGuiTexture(uploadImGuiCursorTexture);
		}
		ImGui.styleColorsDark();
		colors = ImGui.getStyle().colors;
		colors[ImGuiCol.WindowBg] = ImVec4.create(0.16, 0.02, 0.02, 1.0);
		colors[ImGuiCol.ChildBg] = ImVec4.create(0.12, 0.02, 0.02, 1.0);
		colors[ImGuiCol.PopupBg] = ImVec4.create(0.18, 0.02, 0.02, 0.98);
		colors[ImGuiCol.FrameBg] = ImVec4.create(0.35, 0.04, 0.04, 1.0);
		colors[ImGuiCol.FrameBgHovered] = ImVec4.create(0.55, 0.06, 0.06, 1.0);
		colors[ImGuiCol.FrameBgActive] = ImVec4.create(0.68, 0.08, 0.08, 1.0);
		colors[ImGuiCol.TitleBg] = ImVec4.create(0.24, 0.02, 0.02, 1.0);
		colors[ImGuiCol.TitleBgActive] = ImVec4.create(0.48, 0.03, 0.03, 1.0);
		colors[ImGuiCol.MenuBarBg] = ImVec4.create(0.24, 0.02, 0.02, 1.0);
		colors[ImGuiCol.ScrollbarGrab] = ImVec4.create(0.48, 0.04, 0.04, 1.0);
		colors[ImGuiCol.ScrollbarGrabHovered] = ImVec4.create(0.65, 0.06, 0.06, 1.0);
		colors[ImGuiCol.ScrollbarGrabActive] = ImVec4.create(0.78, 0.08, 0.08, 1.0);
		colors[ImGuiCol.CheckMark] = ImVec4.create(1.0, 0.24, 0.24, 1.0);
		colors[ImGuiCol.SliderGrab] = ImVec4.create(0.85, 0.08, 0.08, 1.0);
		colors[ImGuiCol.SliderGrabActive] = ImVec4.create(1.0, 0.18, 0.18, 1.0);
		colors[ImGuiCol.Button] = ImVec4.create(0.55, 0.04, 0.04, 1.0);
		colors[ImGuiCol.ButtonHovered] = ImVec4.create(0.78, 0.06, 0.06, 1.0);
		colors[ImGuiCol.ButtonActive] = ImVec4.create(0.92, 0.08, 0.08, 1.0);
		colors[ImGuiCol.Header] = ImVec4.create(0.5, 0.04, 0.04, 1.0);
		colors[ImGuiCol.HeaderHovered] = ImVec4.create(0.72, 0.06, 0.06, 1.0);
		colors[ImGuiCol.HeaderActive] = ImVec4.create(0.86, 0.08, 0.08, 1.0);
		colors[ImGuiCol.Tab] = ImVec4.create(0.36, 0.03, 0.03, 1.0);
		colors[ImGuiCol.TabHovered] = ImVec4.create(0.72, 0.06, 0.06, 1.0);
		colors[ImGuiCol.TabActive] = ImVec4.create(0.55, 0.04, 0.04, 1.0);
		colors[ImGuiCol.TabUnfocused] = ImVec4.create(0.24, 0.02, 0.02, 1.0);
		colors[ImGuiCol.TabUnfocusedActive] = ImVec4.create(0.38, 0.03, 0.03, 1.0);

		FlxG.stage.window.onRender.add(onImGuiWindowRender, false, -10000);
		#end
	}

	public function newFrame(elapsed:Float):Void
	{
		if (!imguiGlReady)
			return;

		var io = ImGui.getIO();
		io.displaySize = ImVec2.create(FlxG.stage.window.width, FlxG.stage.window.height);
		io.deltaTime = elapsed > 0 ? elapsed : 1 / 60;
		io.mousePos = ImVec2.create(FlxG.stage.mouseX, FlxG.stage.mouseY);
		io.mouseDown[0] = FlxG.mouse.pressed;
		io.mouseDown[1] = FlxG.mouse.pressedRight;
		io.mouseWheel = FlxG.mouse.wheel;
		io.keyCtrl = FlxG.keys.pressed.CONTROL;
		io.keyAlt = FlxG.keys.pressed.ALT;
		io.keyShift = FlxG.keys.pressed.SHIFT;
		io.keySuper = FlxG.keys.pressed.WINDOWS;
		io.keysDown[FlxKey.TAB] = FlxG.keys.pressed.TAB;
		io.keysDown[FlxKey.LEFT] = FlxG.keys.pressed.LEFT;
		io.keysDown[FlxKey.RIGHT] = FlxG.keys.pressed.RIGHT;
		io.keysDown[FlxKey.UP] = FlxG.keys.pressed.UP;
		io.keysDown[FlxKey.DOWN] = FlxG.keys.pressed.DOWN;
		io.keysDown[FlxKey.PAGEUP] = FlxG.keys.pressed.PAGEUP;
		io.keysDown[FlxKey.PAGEDOWN] = FlxG.keys.pressed.PAGEDOWN;
		io.keysDown[FlxKey.HOME] = FlxG.keys.pressed.HOME;
		io.keysDown[FlxKey.END] = FlxG.keys.pressed.END;
		io.keysDown[FlxKey.INSERT] = FlxG.keys.pressed.INSERT;
		io.keysDown[FlxKey.DELETE] = FlxG.keys.pressed.DELETE;
		io.keysDown[FlxKey.BACKSPACE] = FlxG.keys.pressed.BACKSPACE;
		io.keysDown[FlxKey.ENTER] = FlxG.keys.pressed.ENTER;
		io.keysDown[FlxKey.ESCAPE] = FlxG.keys.pressed.ESCAPE;
		io.keysDown[FlxKey.SPACE] = FlxG.keys.pressed.SPACE;
		io.keysDown[FlxKey.A] = FlxG.keys.pressed.A;
		io.keysDown[FlxKey.C] = FlxG.keys.pressed.C;
		io.keysDown[FlxKey.V] = FlxG.keys.pressed.V;
		io.keysDown[FlxKey.X] = FlxG.keys.pressed.X;
		io.keysDown[FlxKey.Y] = FlxG.keys.pressed.Y;
		io.keysDown[FlxKey.Z] = FlxG.keys.pressed.Z;

		var cursor = FlxG.mouse.cursor;
		Cursor.updateImGuiTexture(uploadImGuiCursorTexture);

		#if windows
		untyped __cpp__('imguiGlNewFrame()');
		#end
		ImGui.newFrame();
		drawImGuiCallback();
		if (cursor != null)
		{
			#if windows
			untyped __cpp__('imguiGlDrawCursor({0}, {1}, {2}, {3})', io.mousePos.x + cursor.x, io.mousePos.y + cursor.y, cursor.width, cursor.height);
			#end
		}
		ImGui.render();
		imguiFrameReady = true;
	}

	function uploadImGuiCursorTexture(width:Int, height:Int, pixels:haxe.io.BytesData):Void
	{
		#if windows
		untyped __cpp__('imguiGlSetCursorTexture({0}, {1}, {2})', width, height, pixels);
		#end
	}

	function onImGuiKeyDown(event:KeyboardEvent):Void
	{
		if (event.charCode != 0)
			ImGui.getIO().addInputCharactersUTF8(String.fromCharCode(event.charCode));
	}

	public function isImGuiReady():Bool
	{
		return imguiGlReady;
	}

	function onImGuiWindowRender(_:RenderContext):Void
	{
		#if windows
		if (imguiGlReady && imguiFrameReady)
			untyped __cpp__('imguiGlRender()');
		#end
	}

	public function clean():Void
	{
		#if windows
		FlxG.stage.window.onRender.remove(onImGuiWindowRender);
		if (imguiGlReady)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onImGuiKeyDown);
			untyped __cpp__('imguiGlShutdown()');
		}
		#end
		if (imguiGlReady)
		{
			FlxG.mouse.visible = imguiMouseWasVisible;
			FlxG.mouse.useSystemCursor = imguiMouseWasUsingSystemCursor;
		}
		imguiFrameReady = false;
		ImGui.destroyContext();
	}
}
