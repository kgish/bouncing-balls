package game

import rl "vendor:raylib"
import "core:math/linalg"
import "core:fmt"

SCREEN_SIZE :: 320
BALL_RADIUS :: 4
BALL_START_X :: 160
BALL_START_Y :: 160

ball_pos: rl.Vector2
ball_dir: rl.Vector2
ball_speed: f32
started: bool
game_over: bool
score: int
accumulated_time: f32
previous_ball_pos: rl.Vector2

restart :: proc() {
    ball_pos = { SCREEN_SIZE / 2, BALL_START_Y }
    previous_ball_pos = ball_pos
    started = false
    game_over = false
    score = 0
}

bounce :: proc(sound: rl.Sound) {
    rl.SetSoundPitch(sound, f32(rl.GetRandomValue(8, 12)) / 10)
    rl.PlaySound(sound)
    score = score + 1
}

reflect :: proc(dir, normal: rl.Vector2) -> rl.Vector2 {
    new_direction := linalg.reflect(dir, linalg.normalize(normal))
    return linalg.normalize(new_direction)
}

main :: proc() {
    rl.SetConfigFlags({ .VSYNC_HINT })
    rl.InitWindow(1280, 1280, "Bouncing Ball")
    rl.InitAudioDevice()
    rl.SetTargetFPS(500)

    hit_block_sound := rl.LoadSound("hit_block.wav")
    game_over_sound := rl.LoadSound("game_over.wav")

    mouse_drag := false

    restart()

    for !rl.WindowShouldClose() {
        DT :: 1.0 / 60.0 // 16 ms, 0.016 s

        if !started {
            ball_pos = {
                BALL_START_X,
                BALL_START_Y,
            }

            previous_ball_pos = ball_pos
        } else if game_over {
            if rl.IsKeyPressed(.SPACE) {
                restart()
            }
        } else {
            accumulated_time += rl.GetFrameTime()
        }

        for accumulated_time >= DT {
            previous_ball_pos = ball_pos
            //			previous_paddle_pos_x = paddle_pos_x
            ball_pos += ball_dir * ball_speed * DT

            // Right edge
            if ball_pos.x + BALL_RADIUS > SCREEN_SIZE {
                ball_pos.x = SCREEN_SIZE - BALL_RADIUS
                ball_dir = reflect(ball_dir, { -1, 0 })
                bounce(hit_block_sound)
            }

            // Left edge
            if ball_pos.x - BALL_RADIUS < 0 {
                ball_pos.x = BALL_RADIUS
                ball_dir = reflect(ball_dir, { 1, 0 })
                bounce(hit_block_sound)
            }

            // Top edge
            if ball_pos.y - BALL_RADIUS < 0 {
                ball_pos.y = BALL_RADIUS
                ball_dir = reflect(ball_dir, { 0, 1 })
                bounce(hit_block_sound)
            }

            // Bottom edge
            if ball_pos.y + BALL_RADIUS > SCREEN_SIZE {
                ball_pos.y = SCREEN_SIZE - BALL_RADIUS
                ball_dir = reflect(ball_dir, { 0, -1 })
                bounce(hit_block_sound)
            }

            if !game_over && ball_pos.y > SCREEN_SIZE + BALL_RADIUS * 6 {
                game_over = true
                rl.PlaySound(game_over_sound)
            }

            accumulated_time -= DT
        }

        rl.BeginDrawing()
        rl.ClearBackground({ 150, 190, 220, 255 })

        camera := rl.Camera2D {
            zoom = f32(rl.GetScreenHeight() / SCREEN_SIZE),
        }

        rl.BeginMode2D(camera)

        if !started {
        //            start_text := fmt.ctprint("Start: SPACE")
        //            start_text_width := rl.MeasureText(start_text, 15)
        //            rl.DrawText(start_text, SCREEN_SIZE / 2 - start_text_width / 2, BALL_START_Y - 30, 15, rl.WHITE)

            mouse_pos := rl.GetMousePosition()
            mouse_over := rl.CheckCollisionPointCircle({ mouse_pos.x / 4, mouse_pos.y / 4 }  , ball_pos, BALL_RADIUS)
            if mouse_over {
                rl.DrawCircleV(ball_pos, BALL_RADIUS, { 200, 90, 20, 100 })
                rl.SetMouseCursor(.CROSSHAIR)
            } else {
                rl.DrawCircleV(ball_pos, BALL_RADIUS, { 200, 90, 20, 255 })
                rl.SetMouseCursor(.DEFAULT)
            }

            mouse_button_down := rl.IsMouseButtonDown(.LEFT)

            if (mouse_button_down) {
                mouse_drag = true
                rl.DrawLineEx(ball_pos, { mouse_pos.x / 4, mouse_pos.y / 4 }, 1, { 255, 0, 0, 255 })
            } else {
                if mouse_drag {
                    ball_to_screen_pos := ball_pos - { mouse_pos.x / 4, mouse_pos.y / 4 }
                    ball_dir = linalg.normalize0(ball_to_screen_pos)
                    rl.SetMouseCursor(.DEFAULT)
                    started = true
                    mouse_drag = false
                }
            }

            if (mouse_drag) {
                rl.SetMouseCursor(.CROSSHAIR)
                ball_speed = min(rl.Vector2Distance(ball_pos, { mouse_pos.x / 4, mouse_pos.y / 4 }) * 10, f32(2500))
                text := fmt.ctprintf("%v", int(ball_speed))
                rl.DrawText(text, 5, 5, 10, rl.WHITE)
            } else if mouse_over {
                rl.SetMouseCursor(.CROSSHAIR)
            } else {
                rl.SetMouseCursor(.DEFAULT)
            }
        } else {
            rl.DrawCircleV(ball_pos, BALL_RADIUS, { 200, 90, 20, 255 })
            score_text := fmt.ctprint(score)
            rl.DrawText(score_text, 5, 5, 10, rl.WHITE)
        }

        if game_over {
            game_over_text := fmt.ctprintf("Score: %v. Reset: SPACE", score)
            game_over_text_width := rl.MeasureText(game_over_text, 15)
            rl.DrawText(game_over_text, SCREEN_SIZE / 2 - game_over_text_width / 2, BALL_START_Y - 30, 15, rl.WHITE)
        }

        rl.EndMode2D()
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    rl.CloseAudioDevice()
    rl.CloseWindow()
}
