unit SDL3;
{$mode objfpc}{$H+}{$packrecords c}
interface
{ Deliberately small SDL 3.2+ ABI subset. Checked against official 3.4.18
  SDL headers; bool is one byte, flags are uint64, Event is 128 bytes.
  No SDL2 compatibility declarations. SDL/SDL_ttf are under the zlib license. }
const
  {$IFDEF WINDOWS}
  SDLknihovna = 'SDL3.dll'; TTFknihovna = 'SDL3_ttf.dll';
  {$ELSE}
  SDLknihovna = 'SDL3'; TTFknihovna = 'SDL3_ttf';
  {$ENDIF}
  SDL_INIT_VIDEO = $20;
  SDL_WINDOW_RESIZABLE = $20;
  SDL_WINDOW_HIGH_PIXEL_DENSITY = $2000;
  SDL_EVENT_QUIT = $100;
  SDL_EVENT_WINDOW_RESIZED = $206;
  SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED = $207;
  SDL_EVENT_WINDOW_FOCUS_GAINED = $20E;
  SDL_EVENT_WINDOW_FOCUS_LOST = $20F;
  SDL_EVENT_WINDOW_CLOSE_REQUESTED = $210;
  SDL_EVENT_WILL_ENTER_BACKGROUND = $103;
  SDL_EVENT_DID_ENTER_FOREGROUND = $106;
  SDL_EVENT_KEY_DOWN = $300;
  SDL_EVENT_TEXT_EDITING = $302;
  SDL_EVENT_TEXT_INPUT = $303;
  SDL_EVENT_MOUSE_BUTTON_DOWN = $401;
  SDL_EVENT_MOUSE_WHEEL = $403;
type
  SDL_Color = record r,g,b,a : byte end;
  SDL_Rect = record x,y,w,h : LongInt end;
  SDL_FRect = record x,y,w,h : Single end;
  PSDL_Rect = ^SDL_Rect;
  PSDL_FRect = ^SDL_FRect;
  PSDL_Surface = ^SDL_Surface;
  SDL_Surface = record
    flags,format : LongWord;
    w,h,pitch : LongInt;
    pixels : pointer;
    refcount : LongInt;
    reserved : pointer
  end;
  SDL_CommonEvent = record typ,reserved : LongWord; timestamp : QWord end;
  SDL_WindowEvent = record
    typ,reserved : LongWord; timestamp : QWord;
    windowID : LongWord; data1,data2 : LongInt
  end;
  SDL_KeyboardEvent = record
    typ,reserved : LongWord; timestamp : QWord;
    windowID,which,scancode,key : LongWord;
    modifiers,raw : word; down,repeated : boolean
  end;
  SDL_TextInputEvent = record
    typ,reserved : LongWord; timestamp : QWord;
    windowID : LongWord; text : PAnsiChar
  end;
  SDL_TextEditingEvent = record
    typ,reserved : LongWord; timestamp : QWord;
    windowID : LongWord; text : PAnsiChar; start,length : LongInt
  end;
  SDL_MouseButtonEvent = record
    typ,reserved : LongWord; timestamp : QWord;
    windowID,which : LongWord;
    button : byte; down : boolean; clicks,padding : byte; x,y : Single
  end;
  SDL_MouseWheelEvent = record
    typ,reserved : LongWord; timestamp : QWord;
    windowID,which : LongWord; x,y : Single; direction : LongWord;
    mouse_x,mouse_y : Single; integer_x,integer_y : LongInt
  end;
  SDL_Event = record
    case integer of
      0 : (typ : LongWord);
      1 : (common : SDL_CommonEvent);
      2 : (window : SDL_WindowEvent);
      3 : (key : SDL_KeyboardEvent);
      4 : (text : SDL_TextInputEvent);
      5 : (edit : SDL_TextEditingEvent);
      6 : (button : SDL_MouseButtonEvent);
      7 : (wheel : SDL_MouseWheelEvent);
      8 : (padding : array[0..127] of byte)
  end;
function SDL_Init(flags : LongWord) : boolean; cdecl; external SDLknihovna;
procedure SDL_Quit; cdecl; external SDLknihovna;
function SDL_GetError : PAnsiChar; cdecl; external SDLknihovna;
function SDL_CreateWindow(title : PAnsiChar; w,h : LongInt; flags : QWord) : pointer; cdecl; external SDLknihovna;
procedure SDL_DestroyWindow(window : pointer); cdecl; external SDLknihovna;
function SDL_GetWindowSize(window : pointer; var w,h : LongInt) : boolean; cdecl; external SDLknihovna;
function SDL_SetWindowSize(window : pointer; w,h : LongInt) : boolean; cdecl; external SDLknihovna;
function SDL_SetWindowMinimumSize(window : pointer; w,h : LongInt) : boolean; cdecl; external SDLknihovna;
function SDL_CreateRenderer(window : pointer; name : PAnsiChar) : pointer; cdecl; external SDLknihovna;
procedure SDL_DestroyRenderer(renderer : pointer); cdecl; external SDLknihovna;
function SDL_GetRenderOutputSize(renderer : pointer; var w,h : LongInt) : boolean; cdecl; external SDLknihovna;
function SDL_SetRenderScale(renderer : pointer; x,y : Single) : boolean; cdecl; external SDLknihovna;
function SDL_SetRenderDrawColor(renderer : pointer; r,g,b,a : byte) : boolean; cdecl; external SDLknihovna;
function SDL_RenderClear(renderer : pointer) : boolean; cdecl; external SDLknihovna;
function SDL_RenderFillRect(renderer : pointer; rect : PSDL_FRect) : boolean; cdecl; external SDLknihovna;
function SDL_SetRenderClipRect(renderer : pointer; rect : PSDL_Rect) : boolean; cdecl; external SDLknihovna;
function SDL_RenderTexture(renderer,texture : pointer; src,dst : PSDL_FRect) : boolean; cdecl; external SDLknihovna;
function SDL_RenderPresent(renderer : pointer) : boolean; cdecl; external SDLknihovna;
function SDL_CreateTextureFromSurface(renderer : pointer; surface : PSDL_Surface) : pointer; cdecl; external SDLknihovna;
procedure SDL_DestroyTexture(texture : pointer); cdecl; external SDLknihovna;
procedure SDL_DestroySurface(surface : PSDL_Surface); cdecl; external SDLknihovna;
function SDL_RenderReadPixels(renderer : pointer; rect : PSDL_Rect) : PSDL_Surface; cdecl; external SDLknihovna;
function SDL_SaveBMP(surface : PSDL_Surface; path : PAnsiChar) : boolean; cdecl; external SDLknihovna;
function SDL_PollEvent(var event : SDL_Event) : boolean; cdecl; external SDLknihovna;
function SDL_PushEvent(var event : SDL_Event) : boolean; cdecl; external SDLknihovna;
function SDL_GetWindowID(window : pointer) : LongWord; cdecl; external SDLknihovna;
function SDL_GetTicks : QWord; cdecl; external SDLknihovna;
procedure SDL_Delay(ms : LongWord); cdecl; external SDLknihovna;
function SDL_StartTextInput(window : pointer) : boolean; cdecl; external SDLknihovna;
function SDL_StopTextInput(window : pointer) : boolean; cdecl; external SDLknihovna;
function SDL_SetTextInputArea(window : pointer; rect : PSDL_Rect; cursor : LongInt) : boolean; cdecl; external SDLknihovna;
function SDL_GetPrefPath(org,app : PAnsiChar) : PAnsiChar; cdecl; external SDLknihovna;
function SDL_GetBasePath : PAnsiChar; cdecl; external SDLknihovna;
procedure SDL_free(p : pointer); cdecl; external SDLknihovna;
function SDL_ShowSimpleMessageBox(flags : LongWord; title,message : PAnsiChar; window : pointer) : boolean; cdecl; external SDLknihovna;
function TTF_Init : boolean; cdecl; external TTFknihovna;
procedure TTF_Quit; cdecl; external TTFknihovna;
function TTF_OpenFont(path : PAnsiChar; ptsize : Single) : pointer; cdecl; external TTFknihovna;
procedure TTF_CloseFont(font : pointer); cdecl; external TTFknihovna;
function TTF_RenderText_Blended_Wrapped(font : pointer; text : PAnsiChar; length : SizeUInt; color : SDL_Color; wrapwidth : LongInt) : PSDL_Surface; cdecl; external TTFknihovna;
function TTF_GetStringSize(font : pointer; text : PAnsiChar; length : SizeUInt; var w,h : LongInt) : boolean; cdecl; external TTFknihovna;
implementation
end.
