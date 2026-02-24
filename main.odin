package main

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

    timer_rect: sdl.Rect,
    timer_image: ^sdl.Texture,

    start_rect: sdl.Rect,
    start_image: ^sdl.Texture
}

initialize :: proc(g: ^Game) -> bool {
    ttf.Init()

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

load_media :: proc(g: ^Game) -> bool {
    font := ttf.OpenFont("fonts/ShareTechMono-Regular.ttf", FONT_SIZE)
    if font == nil {
        log.error("Failed to load font:", sdl.GetError())
        return false
    }

    font_surf := ttf.RenderText_Blended(font, FONT_TEXT, 0, FONT_COLOR)
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

    font_surf := ttf.RenderText_Blended(font, BUTTON_TEXT, 0, BUTTON_COLOR)
    if font_surf == nil {
        log.error("Failed to render text:", sdl.GetError())
        return false
    }
    ttf.CloseFont(font)

    g.start_rect.w = font_surf.w
    g.start_rect.h = font_surf.h
    g.start_rect.x = (SCREEN_WIDTH - font_surf.w) / 2
    g.start_rect.y = SCREEN_HEIGHT / 2 + 70

    g.start_image = sdl.CreateTextureFromSurface(g.renderer, font_surf)
    sdl.DestroySurface(font_surf)

    return true
}
 
main_loop :: proc(g: ^Game) {
    for {
        for sdl.PollEvent(&g.event) {
            #partial switch g.event.type {
                case .QUIT:
                    return
                case .KEY_DOWN:
                    // #partial switch g.event.key.keysym.scancode {
                    // case .ESCAPE:
                    //     return
                    // }
                case .MOUSE_BUTTON_DOWN:
                    mx := g.event.button.x
                    my := g.event.button.y
                    if mx >= f32(g.start_rect.x) && mx <= f32(g.start_rect.x + g.start_rect.w) &&
                    my >= f32(g.start_rect.y) && my <= f32(g.start_rect.y + g.start_rect.h) {
                        log.debug("start button clicked")
                    }
            }
        }
        sdl.RenderClear(g.renderer)

        dst_timer := sdl.FRect{
            x = f32(g.timer_rect.x),
            y = f32(g.timer_rect.y),
            w = f32(g.timer_rect.w),
            h = f32(g.timer_rect.h),
        }

        dst_start := sdl.FRect{
            x = f32(g.start_rect.x),
            y = f32(g.start_rect.y),
            w = f32(g.start_rect.w),
            h = f32(g.start_rect.h),
        }

        sdl.RenderTexture(g.renderer, g.timer_image, nil, &dst_timer)
        sdl.RenderTexture(g.renderer, g.start_image, nil, &dst_start)
        sdl.RenderPresent(g.renderer)
    }
}

main :: proc() {
    context.logger = log.create_console_logger()

    game: Game

    if !initialize(&game) do return
    if !load_media(&game) do return
    if !button_start(&game) do return
    main_loop(&game)

    sdl.DestroyRenderer(game.renderer)
    sdl.DestroyWindow(game.window)
    ttf.Quit()
    sdl.Quit()
}