package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

SCREEN_WIDTH :: 400
SCREEN_HEIGHT :: 400

FONT_SIZE :: 80
FONT_TEXT :: "00:00"
FONT_COLOR :: sdl.Color{255, 255, 255, 255}

BUTTON_SIZE :: 40
BUTTON_TEXT :: "START"
BUTTON_COLOR :: sdl.Color{255, 0, 255, 255}

TABS_SIZE :: 15
POMODORO_TEXT :: "Pomodoro"
SHORT_BREAK_TEXT :: "Short Break"
LONG_BREAK_TEXT :: "Long Break"


Button :: struct {
    x, y: f32,
    width, height: f32,
    hovered: bool,
    text: cstring,
}

Game :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    event: sdl.Event,

    pomodoro_rect: sdl.Rect,
    pomodoro_image: ^sdl.Texture,
    short_break_rect: sdl.Rect,
    short_break_image: ^sdl.Texture,
    long_break_rect: sdl.Rect,
    long_break_image: ^sdl.Texture,

    timer_rect: sdl.Rect,
    timer_image: ^sdl.Texture,

    start_rect: sdl.Rect,
    start_image: ^sdl.Texture,
    
    pause_rect: sdl.Rect,
    pause_image: ^sdl.Texture,

    running:      bool,
    seconds_left: int,
    last_tick:    u64,
}

initialize :: proc(g: ^Game) -> bool {
    ttf.Init()
    g.seconds_left = 1500

    g.window = sdl.CreateWindow("Pomodoro", SCREEN_WIDTH, SCREEN_HEIGHT, {.BORDERLESS})
    if g.window == nil {
        log.error("Failed to create window:", sdl.GetError())
        return false
    }

    g.renderer = sdl.CreateRenderer(g.window, nil)
    if g.renderer == nil {
        log.error("Failed to create renderer:", sdl.GetError())
        return false
    }

    sdl.SetRenderDrawColor(g.renderer, 0, 0, 0, 255)
    return true
}

update_timer_texture :: proc(g: ^Game) {
    font := ttf.OpenFont("fonts/ShareTechMono-Regular.ttf", FONT_SIZE)
    
    mins := g.seconds_left / 60
    secs := g.seconds_left % 60
    timer_text := fmt.ctprintf("%02d:%02d", mins, secs)

    font_surf := ttf.RenderText_Blended(font, timer_text, 0, FONT_COLOR)
    ttf.CloseFont(font)

    if g.timer_image != nil do sdl.DestroyTexture(g.timer_image)

    g.timer_rect.w = font_surf.w
    g.timer_rect.h = font_surf.h
    g.timer_rect.x = (SCREEN_WIDTH - font_surf.w) / 2
    g.timer_rect.y = (SCREEN_HEIGHT - font_surf.h) / 2

    g.timer_image = sdl.CreateTextureFromSurface(g.renderer, font_surf)
    sdl.DestroySurface(font_surf)
}

tabs :: proc(g: ^Game) -> bool {
    font := ttf.OpenFont("fonts/ShareTechMono-Regular.ttf", TABS_SIZE)
    if font == nil {
        log.error("Failed to load font:", sdl.GetError())
        return false
    }

    font_pomodoro_surf := ttf.RenderText_Blended(font, POMODORO_TEXT, 0, FONT_COLOR)
    if font_pomodoro_surf == nil {
        log.error("Failed to render text:", sdl.GetError())
        return false
    }

    g.pomodoro_rect.w = font_pomodoro_surf.w
    g.pomodoro_rect.h = font_pomodoro_surf.h
    g.pomodoro_rect.x = SCREEN_WIDTH / 2 - 150
    g.pomodoro_rect.y = SCREEN_HEIGHT / 2 - 120

    font_short_break_surf := ttf.RenderText_Blended(font, SHORT_BREAK_TEXT, 0, FONT_COLOR)
    if font_pomodoro_surf == nil {
        log.error("Failed to render text:", sdl.GetError())
        return false
    }

    g.short_break_rect.w = font_short_break_surf.w
    g.short_break_rect.h = font_short_break_surf.h
    g.short_break_rect.x = SCREEN_WIDTH / 2 - 50
    g.short_break_rect.y = SCREEN_HEIGHT / 2 - 120

    font_long_break_surf := ttf.RenderText_Blended(font, LONG_BREAK_TEXT, 0, FONT_COLOR)
    if font_pomodoro_surf == nil {
        log.error("Failed to render text:", sdl.GetError())
        return false
    }

    g.long_break_rect.w = font_long_break_surf.w
    g.long_break_rect.h = font_long_break_surf.h
    g.long_break_rect.x = SCREEN_WIDTH / 2 + 70
    g.long_break_rect.y = SCREEN_HEIGHT / 2 - 120
    ttf.CloseFont(font)

    g.pomodoro_image = sdl.CreateTextureFromSurface(g.renderer, font_pomodoro_surf)
    sdl.DestroySurface(font_pomodoro_surf)
    g.short_break_image = sdl.CreateTextureFromSurface(g.renderer, font_short_break_surf)
    sdl.DestroySurface(font_short_break_surf)
    g.long_break_image = sdl.CreateTextureFromSurface(g.renderer, font_long_break_surf)
    sdl.DestroySurface(font_long_break_surf)

    return true
}

timer :: proc(g: ^Game) -> bool {
    font := ttf.OpenFont("fonts/ShareTechMono-Regular.ttf", FONT_SIZE)
    if font == nil {
        log.error("Failed to load font:", sdl.GetError())
        return false
    }

    mins := g.seconds_left / 60
    secs := g.seconds_left % 60
    timer_text := fmt.ctprintf("%02d:%02d", mins, secs)

    font_surf := ttf.RenderText_Blended(font, timer_text, 0, FONT_COLOR)
    if font_surf == nil {
        log.error("Failed to render text:", sdl.GetError())
        return false
    }
    ttf.CloseFont(font)

    g.timer_rect.w = font_surf.w
    g.timer_rect.h = font_surf.h
    g.timer_rect.x = (SCREEN_WIDTH - font_surf.w) / 2
    g.timer_rect.y = (SCREEN_HEIGHT - font_surf.h) / 2

    g.timer_image = sdl.CreateTextureFromSurface(g.renderer, font_surf)
    sdl.DestroySurface(font_surf)

    return true
}

button_start :: proc(g: ^Game) -> bool {
    font := ttf.OpenFont("fonts/ShareTechMono-Regular.ttf", BUTTON_SIZE)
    if font == nil {
        log.error("Failed to load font:", sdl.GetError())
        return false
    }

    // load START texture
    start_surf := ttf.RenderText_Blended(font, "START", 0, BUTTON_COLOR)
    if start_surf == nil {
        log.error("Failed to render start text:", sdl.GetError())
        return false
    }
    g.start_rect.w = start_surf.w
    g.start_rect.h = start_surf.h
    g.start_rect.x = (SCREEN_WIDTH - start_surf.w) / 2
    g.start_rect.y = SCREEN_HEIGHT / 2 + 70
    g.start_image = sdl.CreateTextureFromSurface(g.renderer, start_surf)
    sdl.DestroySurface(start_surf)

    // load PAUSE texture
    pause_surf := ttf.RenderText_Blended(font, "PAUSE", 0, BUTTON_COLOR)
    if pause_surf == nil {
        log.error("Failed to render pause text:", sdl.GetError())
        return false
    }
    g.pause_rect.w = pause_surf.w
    g.pause_rect.h = pause_surf.h
    g.pause_rect.x = (SCREEN_WIDTH - pause_surf.w) / 2
    g.pause_rect.y = SCREEN_HEIGHT / 2 + 70
    g.pause_image = sdl.CreateTextureFromSurface(g.renderer, pause_surf)
    sdl.DestroySurface(pause_surf)

    ttf.CloseFont(font)
    return true
}
 
main_loop :: proc(g: ^Game) {
    for {
        for sdl.PollEvent(&g.event) {
            #partial switch g.event.type {
                case .QUIT:
                    return
                case .MOUSE_BUTTON_DOWN:
                    mx := g.event.button.x
                    my := g.event.button.y
                    active_rect := g.start_rect if !g.running else g.pause_rect

                    if mx >= f32(active_rect.x) && mx <= f32(active_rect.x + active_rect.w) &&
                    my >= f32(active_rect.y) && my <= f32(active_rect.y + active_rect.h) {
                        g.running = !g.running
                        if g.running do g.last_tick = sdl.GetTicks()
                    }

                    // pomodoro tab - 25 mins
                    if mx >= f32(g.pomodoro_rect.x) && mx <= f32(g.pomodoro_rect.x + g.pomodoro_rect.w) &&
                    my >= f32(g.pomodoro_rect.y) && my <= f32(g.pomodoro_rect.y + g.pomodoro_rect.h) {
                        g.running = false
                        g.seconds_left = 25 * 60
                        update_timer_texture(g)
                    }

                    // short break tab - 5 mins
                    if mx >= f32(g.short_break_rect.x) && mx <= f32(g.short_break_rect.x + g.short_break_rect.w) &&
                    my >= f32(g.short_break_rect.y) && my <= f32(g.short_break_rect.y + g.short_break_rect.h) {
                        g.running = false
                        g.seconds_left = 5 * 60
                        update_timer_texture(g)
                    }

                    // long break tab - 15 mins
                    if mx >= f32(g.long_break_rect.x) && mx <= f32(g.long_break_rect.x + g.long_break_rect.w) &&
                    my >= f32(g.long_break_rect.y) && my <= f32(g.long_break_rect.y + g.long_break_rect.h) {
                        g.running = false
                        g.seconds_left = 15 * 60
                        update_timer_texture(g)
                    }
            }
        }

        if g.running {
                now := sdl.GetTicks()
                if now - g.last_tick >= 1000 {
                    g.last_tick = now
                    g.seconds_left -= 1
                    update_timer_texture(g)
                }
            }
        sdl.RenderClear(g.renderer)

        dst_timer := sdl.FRect{
            x = f32(g.timer_rect.x),
            y = f32(g.timer_rect.y),
            w = f32(g.timer_rect.w),
            h = f32(g.timer_rect.h),
        }

        sdl.RenderTexture(g.renderer, g.timer_image, nil, &dst_timer)
        btn_image := g.start_image if !g.running else g.pause_image
        btn_rect  := g.start_rect  if !g.running else g.pause_rect
        dst_start := sdl.FRect{
            x = f32(btn_rect.x),
            y = f32(btn_rect.y),
            w = f32(btn_rect.w),
            h = f32(btn_rect.h),
        }
        sdl.RenderTexture(g.renderer, btn_image, nil, &dst_start)

        pomodoro_button := sdl.FRect{
            x = f32(g.pomodoro_rect.x),
            y = f32(g.pomodoro_rect.y),
            w = f32(g.pomodoro_rect.w),
            h = f32(g.pomodoro_rect.h),
        }
        sdl.RenderTexture(g.renderer, g.pomodoro_image, nil, &pomodoro_button)
        
        short_break_button := sdl.FRect{
            x = f32(g.short_break_rect.x),
            y = f32(g.short_break_rect.y),
            w = f32(g.short_break_rect.w),
            h = f32(g.short_break_rect.h),
        }
        sdl.RenderTexture(g.renderer, g.short_break_image, nil, &short_break_button)
        
        long_break_button := sdl.FRect{
            x = f32(g.long_break_rect.x),
            y = f32(g.long_break_rect.y),
            w = f32(g.long_break_rect.w),
            h = f32(g.long_break_rect.h),
        }
        sdl.RenderTexture(g.renderer, g.long_break_image, nil, &long_break_button)

        sdl.RenderPresent(g.renderer)

        sdl.Delay(16)  // ~60fps cap
    }
}

main :: proc() {
    context.logger = log.create_console_logger()

    game: Game

    if !initialize(&game) do return
    if !tabs(&game) do return
    if !timer(&game) do return
    if !button_start(&game) do return
    main_loop(&game)

    sdl.DestroyRenderer(game.renderer)
    sdl.DestroyWindow(game.window)
    ttf.Quit()
    sdl.Quit()
}