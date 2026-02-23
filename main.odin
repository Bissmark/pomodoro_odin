package main

import "core:log"
import sdl "vendor:sdl3"

Button :: struct {
    x, y: f32,
    width, height: f32,
    hovered: bool,
    text: cstring,
}

init_sdl :: proc() {
    ok := sdl.Init({.VIDEO}); assert(ok)
    window := sdl.CreateWindow("Test", 400, 400, {}); assert(window != nil)
    renderer := sdl.CreateRenderer(window, nil)

    sdl.SetRenderDrawColor(renderer, 255, 0, 0, 255)
    sdl.RenderClear(renderer)
    sdl.RenderPresent(renderer)
}
 
main_loop :: proc() {
    main_loop: for {
        ev: sdl.Event
        for sdl.PollEvent(&ev) {
            #partial switch ev.type {
                case .QUIT:
                    break main_loop
                case .KEY_DOWN:
                    if ev.key.scancode == .ESCAPE do break main_loop
            }
        }
    }
}

main :: proc() {
    context.logger = log.create_console_logger()

    log.debug("Hello")

    init_sdl()
    main_loop()
}