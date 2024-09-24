#Requires AutoHotkey v2.0

global Version := "1.0.0"
global Dependencies := ["Utils\Functions.ahk", "Utils\UWBOCRLib.ahk", "Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

_GetRawUIData() {

}

_GetUIPosition(Name := "") {
    PositionBuilder := {X: 0, Y: 0}

    if (PS99_UI_POSITION_MAP.Has(Name)) {
        UIData := PS99_UI_POSITION_MAP[Name]
        if (UIData.HasOwnProp("Position")) {
            PositionBuilder := {X: UIData.Position.X, Y: UIData.Position.Y}
        } else {
            Error("INVALID UI - NO POSITION" Name)
        }
    }

    return PositionBuilder
}

_GetUIBounds(Name := "") {
    BoundsBuilder := [{X: 1,Y: 1},{X: 1,Y: 1}]

    if (PS99_UI_POSITION_MAP.Has(Name)) {
        UIData := PS99_UI_POSITION_MAP[Name]
        if (not UIData.HasOwnProp("Position")) {
            Error("INVALID POSITION " Name)
        }
        if (not UIData.HasOwnProp("Bounds")) {
            BoundsBuilder := [{X: UIData.Position.X - 1, Y: UIData.Position.Y - 1}, {X: UIData.Position.X + 1, Y: UIData.Position.Y + 1}]
        } else {
            BoundsBuilder := UIData.Bounds
        }
    }

    return BoundsBuilder
}

_GetColorForSearch(Name := "") {
    ColorBuilder := "0xFFFFFF"
    VariationBuilder := 1

    if (PS99_UI_COLOR_MAP.Has(Name)) {
        ColorData := PS99_UI_COLOR_MAP[Name]
        if (not ColorData.HasOwnProp("Color")) {
            Error("INVALID COLOR - COLOR KEY DOESNT EXIST " Name)
        } else {
            ColorBuilder := ColorData.Color
        }

        if (ColorData.HasOwnProp("Variation")) {
            VariationBuilder := ColorData.Variation
        }
    } else {
        Error("INVALID COLOR NAME" Name)
    }

    return [ColorBuilder, VariationBuilder]
}

_UIPixelSearchBuilder(Name := "", Color := "") {
    Bounds := _GetUIBounds(Name)
    Color := _GetColorForSearch(Color)

    x1 := Bounds[1].X
    y1 := Bounds[1].Y
    x2 := Bounds[2].X
    y2 := Bounds[2].Y

    colorValue := Color[1]
    variation := Color[2]

    return [x1, y1, x2, y2, colorValue, variation]
}

UIPixelSearch(Name := "", Color := "") {

    Success := PixelSearch(&outX, &outY, _UIPixelSearchBuilder(Name, Color)*)

    return [Success, {X: outX, Y: outY}]
}

UIPixelSearchLoop(Name := "", Color := "", Timeout := 10000) {
    PixelSearchBuild := _UIPixelSearchBuilder(Name, Color)
    
    x1 := PixelSearchBuild[1]
    y1 := PixelSearchBuild[2]
    x2 := PixelSearchBuild[3]
    y2 := PixelSearchBuild[4]
    color := PixelSearchBuild[5]
    variation := PixelSearchBuild[6]
    
    StartTick := A_TickCount
    initialLook := PixelSearch(&outX, &outY, x1, y1, x2, y2, color, variation)
    if (not initialLook) {
        Loop {
            if (A_TickCount - StartTick) >= Timeout {
                break
            }

            if (PixelSearch(&outX, &outY, x1, y1, x2, y2, color, variation)) {
                return [true, {X: outX, Y: outY}]
            }
        }
    } else {
        return [true, {X: outX, Y: outY}]
    }

    return [false, {X: 0, Y: 0}]
}

UIClick(Name := "", Amount := 1, MouseSmoothing := 0) {
    UIPosition := _GetUIPosition(Name)

    MouseMove(UIPosition.X + 1, UIPosition.Y + 1, MouseSmoothing)
    ;if (MouseSmoothing != 0 && MouseSmoothing <= 5) {
    ;    MouseMove(UIPosition.X, UIPosition.Y, MouseSmoothing)
    ;}
    Sleep(5)

    SendEvent "{Click," UIPosition.X "," UIPosition.Y "," Amount "}"
}

HideMouse() {
    MouseMove(3, 3, 0)
    Sleep(5)
    MouseMove(2, 2, 0)
}

DrawPolygonOnUI(Name := "", Duration := 3000) {
    DrawPolygon(BoundsToPolygon(_GetUIBounds(Name)), showTime := Duration)
}


ExitMenus() {
    Loop {
        MenuOpen := UIPixelSearch("Menu_Close", "Exit")[1]
        NotificationOpen := UIPixelSearch("Notification_Close", "Exit")[1]

        if (MenuOpen == 1) {
            UIClick("Menu_Close")
        }
        if (NotificationOpen == 1) {
            UIClick("Notification_Close")
        }

        if (not MenuOpen && not NotificationOpen) {
            break
        }
        Sleep(100)
    } Until A_Index > 100
}

HasMenuOpen(MenuName := "") {
    Bounds1 := RelativeXYToAbsolute(70,84)
    Bounds2 := RelativeXYToAbsolute(360,130)

    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    
    
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
    ;DrawPolygon(BoundsToPolygon([{X: 68, Y: 82}, {X: 362, Y: 132}]), showTime := 1000)
    Debug("FOUND TEXT: " ocrResult.Text)

    return RegExMatch(ocrResult.Text, MenuName) > 0
}

HasNotificationOpen(MenuName := "") {
    x1 := 195
    y1 := 84
    x2 := 472
    y2 := 129

    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)

    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    
    
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
    ;DrawPolygon(BoundsToPolygon([{X: x1-1, Y: y1-1}, {X: x2+1, Y: y2+1}]), showTime := 1000)
    Debug("FOUND TEXT: " ocrResult.Text)

    return RegExMatch(ocrResult.Text, MenuName)
}

SearchNotificationWarning() {
    x1 := 236
    y1 := 118
    x2 := 560
    y2 := 164

    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)

    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    
    
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
    ;DrawPolygon(BoundsToPolygon([{X: x1-1, Y: y1-1}, {X: x2+1, Y: y2+1}]), showTime := 1000)
    Debug("FOUND TEXT: " ocrResult.Text)

    return ocrResult.Text
}

SearchNotificationWarningText() {
    x1 := 176
    y1 := 173
    x2 := 619
    y2 := 264

    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)

    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    
    
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
    ;DrawPolygon(BoundsToPolygon([{X: x1-1, Y: y1-1}, {X: x2+1, Y: y2+1}]), showTime := 1000)
    Debug("FOUND TEXT: " ocrResult.Text)

    return ocrResult.Text
}

SearchNotificationQuestion() {
    x1 := 176
    y1 := 145
    x2 := 619
    y2 := 217

    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)

    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    
    
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
    ;DrawPolygon(BoundsToPolygon([{X: x1-1, Y: y1-1}, {X: x2+1, Y: y2+1}]), showTime := 1000)
    Debug("FOUND TEXT: " ocrResult.Text)

    return ocrResult.Text
}

_FindOops() {
    x1 := 352
    y1 := 120
    x2 := 450
    y2 := 160
    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)
    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

    return RegExMatch(ocrResult.Text, "Oops|oops|oo|ps") > 0
}