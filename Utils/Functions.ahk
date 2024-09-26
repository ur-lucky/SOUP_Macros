#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.2"
global Dependencies := []

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

Debug(Text := "") {
    OutputDebug("[DEBUG] | " Text)
}

DrawDestroy(highlightGuis) {
    ;Debug("destroying highlights")
    for _, highlightGui in highlightGuis {
        highlightGui.Destroy()
    }
}

DrawPolygon(points, showTime := 3000, color := "000000", d := 2, relative := false) {
    static guis := []

    ; Create a copy of the points array to avoid modifying the original
    localPoints := []
    for i, point in points {
        localPoints.Push({X: point.X, Y: point.Y})
    }

    ; Clear all existing highlights if no points are provided
    if !IsSet(localPoints) {
        for _, guiSet in guis {
            for _, somegui in guiSet {
                somegui.Destroy()
            }
        }
        guis := [] ; Reset the guis array
        return
    }

    highlightGuis := []
    pi := 4 * atan(1)

    ; If relative is true, convert all points to absolute screen coordinates
    if (relative) {
        for i, point in localPoints {
            localPoints[i] := RelativeXYToAbsolute(point.X, point.Y)
        }
    }

    ; Loop through points and draw lines between each pair of consecutive points
    Loop localPoints.Length {
        p1 := localPoints[A_Index]
        p2 := localPoints[A_Index = localPoints.Length ? 1 : A_Index + 1] ; Loop back to first point at the end

        deltaX := p2.X - p1.X
        deltaY := p2.Y - p1.Y
        distance := Sqrt(deltaX**2 + deltaY**2)

        ; Check if the line is diagonal (deltaX != 0 and deltaY != 0)
        if Abs(deltaX) > 0 && Abs(deltaY) > 0 {
            ; Draw a diagonal using steps (creating multiple segments for smoothness)
            steps := Ceil(Max(Abs(deltaX), Abs(deltaY)) / d)
            Loop steps {
                x := p1.X + (deltaX * A_Index / steps)
                y := p1.Y + (deltaY * A_Index / steps)
                newgui := Gui(Options := "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000", "")
                newgui.BackColor := color
                newgui.Show("NA x" Integer(x) " y" Integer(y) " w" d " h" d)
                highlightGuis.Push(newgui)
            }
        } else if deltaX != 0 { 
            ; Horizontal lines
            newgui := Gui(Options := "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000", "")
            newgui.BackColor := color
            x1 := deltaX > 0 ? p1.X : p2.X ; Ensure correct start point
            newgui.Show("NA x" Integer(x1) " y" Integer(p1.Y) " w" Integer(Abs(deltaX)) " h" d)
            highlightGuis.Push(newgui)
        } else {
            ; Vertical lines
            newgui := Gui(Options := "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000", "")
            newgui.BackColor := color
            y1 := deltaY > 0 ? p1.Y : p2.Y ; Ensure correct start point
            newgui.Show("NA x" Integer(p1.X) " y" Integer(y1) " w" d " h" Integer(Abs(deltaY)))
            highlightGuis.Push(newgui)
        }
    }

    guis.Push(highlightGuis)

    ; Destroy after the specified time
    if showTime > 0 {
        SetTimer(DrawDestroy.Bind(highlightGuis), -showTime)
    } else if showTime < 0 {
        SetTimer(DrawDestroy.Bind(highlightGuis), -Abs(showTime))
    }

    return highlightGuis
}


BoundsToPolygon(Arry) {
    NewArray := Array()
    
    Loop Arry.Length {
        AbsolutePos := RelativeXYToAbsolute(X := Arry[A_Index].X, Y := Arry[A_Index].Y)
        ;Debug("X: " AbsolutePos.X " Y: " AbsolutePos.Y)
        NewArray.Push(AbsolutePos)
    }

    ; If there are only 2 points, calculate the other 2 points to form a rectangle
    if (NewArray.Length != 4) {
        P1 := NewArray[1]
        P2 := NewArray[2]

        ; Adjust the bounding box to be "out by 1"
        ; P1 should move left by 1 (x-1) and up by 1 (y-1)
        P1 := {X: P1.X - 1, Y: P1.Y - 1}

        ; P2 should move right by 1 (x+1) and down by 1 (y+1)
        P2 := {X: P2.X + 1, Y: P2.Y + 1}

        P3 := {X: P2.X, Y: P1.Y} ; Keep x from P2 and y from P1
        P4 := {X: P1.X, Y: P2.Y} ; Keep x from P1 and y from P2

        return [P1, P4, P2, P3] ; Return the four points in order (P1, P4, P2, P3 forms a rectangle)
    }

    if (NewArray.Length == 4) {
        P1 := NewArray[1]
        P2 := NewArray[2]
        P3 := NewArray[3]
        P4 := NewArray[4]

        P1 := [P1.X - 1, P1.Y - 1] ; Top-left corner moves left and up
        P2 := [P2.X + 1, P2.Y - 1] ; Top-right corner moves right and up
        P3 := [P3.X + 1, P3.Y + 1] ; Bottom-right corner moves right and down
        P4 := [P4.X - 1, P4.Y + 1] ; Bottom-left corner moves left and down

        return [P1, P2, P3, P4] ; Return the adjusted 4-point rectangle
    }

    return NewArray ; Fallback if the length is not 2 or 4
}

RelativeXYToAbsolute(X := 0, Y := 0) {
    ;Debug("Passed X: " X)
    WinGetPos(&absoluteX, &absoluteY, &width, &height, "A")
    return {X: absoluteX + X + 6, Y: absoluteY + Y + 31}
}

PixelSearchPosition(x1 := 0 y1 := 0, x2 := 0 y2 := 0, color := 0xFFFFFF, variation := 1 returnPosition := false) {
    Success := PixelSearch(&x, &y, x1, y1, x2, y2, color, variation)
    if Success {
        if returnPosition {
            return [Success, {X: x, Y: y}]
        } else {
            return [Success]
        }
    } else {
        return [false]
    }
}

TrueFalseToString(condition) {
    return (condition == true ? " true" : " false")
}