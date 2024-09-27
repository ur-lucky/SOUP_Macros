#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.2"
global Dependencies := ["Utils\Functions.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

SolveMovement(MovementMap) {
    KeyPresses := []  ; Array to store key presses and their timings
    CurrentTime := 0  ; Start from 0 time
    Markers := []  ; Store actions with exact time markers

    ; First pass: Cache all actions with their respective time markers
    for action in MovementMap {
        if (action.HasOwnProp("Key")) {
            ; Handle camera movements based on "Camera" action
            if (action.Key = "Camera") {
                if (action.HasOwnProp("Direction") && action.HasOwnProp("Degrees")) {
                    ; Cache camera turn based on direction and degrees
                    Markers.Push({
                        Direction: action.Direction, 
                        Degrees: action.Degrees, 
                        Time: CurrentTime, 
                        Action: "TurnCamera", 
                        Processed: false
                    })
                }
            ; Handle Wheel scroll support with repeat
            } else if (action.Key = "WheelUp" || action.Key = "WheelDown") {
                if (action.HasOwnProp("Repeat")) {
                    RepeatTimes := action.Repeat
                    Loop RepeatTimes {
                        ScrollTime := CurrentTime + ((A_Index - 1) * (action.Delay || 0))  ; Add delay between each scroll
                        Markers.Push({Key: action.Key, Time: ScrollTime, Action: "Scroll", Processed: false})
                    }
                    CurrentTime += action.Delay * (action.Repeat - 1)  ; Increment current time for scrolls
                } else {
                    Markers.Push({Key: action.Key, Time: CurrentTime, Action: "Scroll", Processed: false})
                }

            ; Handle Repeat logic for other keys
            } else if (action.HasOwnProp("Repeat")) {
                RepeatTimes := action.Repeat
                actionDuration := action.HasOwnProp("Duration") ? action.Duration : 0
                Loop RepeatTimes {
                    PressTime := CurrentTime + ((A_Index - 1) * (actionDuration + (A_Index > 1 ? action.Delay : 0)))
                    ReleaseTime := PressTime + actionDuration
                    Markers.Push({Key: action.Key, Time: PressTime, Action: "Down", Processed: false})
                    Markers.Push({Key: action.Key, Time: ReleaseTime, Action: "Up", Processed: false})
                }
                CurrentTime += (actionDuration * action.Repeat) + (action.Delay * (action.Repeat - 1))

            ; Handle duration without explicit "Down/Up"
            } else if (action.HasOwnProp("Duration")) {
                ; Press and release automatically
                Markers.Push({Key: action.Key, Time: CurrentTime, Action: "Down", Processed: false})
                Markers.Push({Key: action.Key, Time: CurrentTime + action.Duration, Action: "Up", Processed: false})
                CurrentTime += action.Duration
            
            ; Handle simple key press
            } else {
                ; Default simple key press without duration
                Markers.Push({Key: action.Key, Time: CurrentTime, Action: "Down", Processed: false})
                Markers.Push({Key: action.Key, Time: CurrentTime + 1, Action: "Up", Processed: false})  ; Instant release after 1ms
            }
        } else if (action.HasOwnProp("Rest")) {
            ; Add rest time to the current timeline
            CurrentTime += action.Rest

        } else if (action.HasOwnProp("Func")) {
            ; Function execution marker
            Markers.Push({Func: action.Func, Time: CurrentTime, Action: "RunFunc", Processed: false})
        }
    }

    StartTime := A_TickCount

    ; Loop through the cached markers based on time
    Loop {
        TimeElapsed := A_TickCount - StartTime
        AllDone := true  ; Flag to check if all actions are done

        for i, marker in Markers {
            if (marker.Processed) {
                continue
            }

            ; Check if it's time to execute this marker
            if (TimeElapsed >= marker.Time) {
                if (marker.Action = "Scroll") {
                    SendEvent "{" marker.Key "}"
                } else if (marker.Action = "Down" || marker.Action = "Up") {
                    SendEvent "{" marker.Key " " marker.Action "}"
                } else if (marker.Action = "TurnCamera") {
                    ; Handle camera turns
                    if (marker.Direction = "X") {
                        CoordMode "Mouse", "Window"
                        WinGetPos(&somex, &somey, &width, &height, "A")
                        MouseMove(width/2, height/2, 0)
                        Sleep(10)
                        SendEvent("{RButton Down}")
                        Sleep(50)
                        ;MouseMove(0, 0, 0, "R")
                        MouseMover(1,0)
                        MouseMover(-1,0)
                        TurnCameraX(marker.Degrees)
                        SendEvent("{RButton Up}")
                        CoordMode "Mouse", "Client"
                    } else if (marker.Direction = "Y") {
                        CoordMode "Mouse", "Window"
                        WinGetPos(&somex, &somey, &width, &height, "A")
                        MouseMove(width/2, height/2, 0)
                        Sleep(10)
                        SendEvent("{RButton Down}")
                        Sleep(50)
                        ;MouseMove(0, 0, 0, "R")
                        MouseMover(0,1)
                        MouseMover(0,-1)
                        TurnCameraY(marker.Degrees)
                        SendEvent("{RButton Up}")
                        CoordMode "Mouse", "Client"

                    }
                } else if (marker.Action = "RunFunc") {
                    ; Execute the function and measure its duration
                    funcStart := A_TickCount
                    marker.Func.Call()  ; Call the function
                    funcEnd := A_TickCount
                    funcDuration := funcEnd - funcStart

                    ; Adjust CurrentTime for the time taken by the function
                    for j in Markers {
                        if !j.Processed and j.Time > marker.Time {
                            j.Time += funcDuration  ; Adjust subsequent markers by the function's duration
                        }
                    }
                }
                marker.Processed := true  ; Mark this action as processed
                
                ; Debug information
                Debug("Executed " marker.Action " on " (marker.HasOwnProp("Key") ? marker.Key : "Function") " at " marker.Time)
            } else {
                AllDone := false  ; Not all actions have been processed
            }
        }

        ; If all actions have been processed, break the loop
        if (AllDone) {
            break
        }

        Sleep(10)  ; Small sleep to avoid hogging CPU
    }
}
