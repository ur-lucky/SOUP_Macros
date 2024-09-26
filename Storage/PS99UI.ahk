#Requires AutoHotkey v2.0

global Version := "1.0.7"
global Dependencies := []

global PS99_UI_POSITION_MAP := Map()
global PS99_UI_COLOR_MAP := Map()


/**
 * 
 *              COLORS
 * 
 */

; X button
PS99_UI_COLOR_MAP["Exit"] := {Color: "0xFF135A", Variation: 5}

; Toggle colors
PS99_UI_COLOR_MAP["Enabled"] := {Color: "0x84F710", Variation: 5}
PS99_UI_COLOR_MAP["Disabled"] := {Color: "0xFF1761", Variation: 5}

; Yes/No buttons
PS99_UI_COLOR_MAP["Accept"] := {Color: "0x7DF50D", Variation: 5}
PS99_UI_COLOR_MAP["Ignore"] := {Color: "0x7DF50D", Variation: 5}

PS99_UI_COLOR_MAP["Oops_Blue"] := {Color: "0x4AD8ff", Variation: 5}

; stupid warning cat that says oops
PS99_UI_COLOR_MAP["Warning_Cat_Grey"] := {Color: "0x95A9CD", Variation: 5}

; HUD teleport button
PS99_UI_COLOR_MAP["HUD_Teleport_Button_Red"] := {Color: "0xDB113F", Variation: 30}
PS99_UI_COLOR_MAP["HUD_Teleport_Button_Grey"] := {Color: "0x60ACA4", Variation: 5}
PS99_UI_COLOR_MAP["HUD_SuperComputer_Blue"] := {Color: "0x27D4EF", Variation: 8}

; Misc
PS99_UI_COLOR_MAP["Search"] := {Color: "0xAFAFAF", Variation: 5}

; Clan related
PS99_UI_COLOR_MAP["Clan_Button_Blue"] := {Color: "0x077FDF", Variation: 5}

; Teleport menu
PS99_UI_COLOR_MAP["Teleport_Spawn"] := {Color: "0xFCAE03", Variation: 5}
PS99_UI_COLOR_MAP["Teleport_World1"] := {Color: "0x5CBCF4", Variation: 5}
PS99_UI_COLOR_MAP["Teleport_World2"] := {Color: "0xDE54FF", Variation: 5}
PS99_UI_COLOR_MAP["Teleport_World3"] := {Color: "0x02DAEA", Variation: 5}

PS99_UI_COLOR_MAP["Ultiamte_Red"] := {Color: "0xFF1C1C", Variation: 1}
PS99_UI_COLOR_MAP["Ultiamte_Blue"] := {Color: "0x70EDFC", Variation: 1}




/**
 * 
 *              POSITIONS
 * 
 */


; Larger menu
PS99_UI_POSITION_MAP["Menu_Close"] := {Position: {X: 748, Y: 111}, Bounds: [{X: 723, Y: 87}, {X: 776, Y: 135}]}
PS99_UI_POSITION_MAP["Search_Box"] := {Position: {X: 660, Y: 107}, Bounds: [{X: 600, Y: 96}, {X: 711, Y: 117}]}
PS99_UI_POSITION_MAP["Menu_Scroll"] := {Position: {X: 757, Y: 150}, Bounds: [{X: 757, Y: 150}, {X: 757, Y: 472}]}


; Smaller menu
PS99_UI_POSITION_MAP["Notification_Question"] := {Position: {X: 403, Y: 144}, Bounds: [{X: 176, Y: 145}, {X: 619, Y: 217}]}
PS99_UI_POSITION_MAP["Notification_Oops"] := {Position: {X: 403, Y: 144}, Bounds: [{X: 236, Y: 118}, {X: 560, Y: 164}]}
PS99_UI_POSITION_MAP["Notification_Text"] := {Position: {X: 403, Y: 144}, Bounds: [{X: 176, Y: 173}, {X: 619, Y: 264}]}
PS99_UI_POSITION_MAP["Notification_Scroll"] := {Position: {X: 631, Y: 150}, Bounds: [{X: 631, Y: 150}, {X: 631, Y: 472}]}
PS99_UI_POSITION_MAP["Notification_Icon"] := {Position: {X: 405, Y: 324}, Bounds: [{X: 376, Y: 302}, {X: 421, Y: 341}]}

PS99_UI_POSITION_MAP["Notification_Ok"] := {Position: {X: 405, Y: 424}, Bounds: [{X: 375, Y: 392}, {X: 432, Y: 452}]}
PS99_UI_POSITION_MAP["Notification_Yes"] := {Position: {X: 286, Y: 424}, Bounds: [{X: 195, Y: 396}, {X: 384, Y: 454}]}
PS99_UI_POSITION_MAP["Notification_Close"] := {Position: {X: 623, Y: 111}, Bounds: [{X: 597, Y: 87}, {X: 650, Y: 135}]}

; HUD
PS99_UI_POSITION_MAP["HUD_Gift_Button"] := {Position: {X: 40, Y: 188}, Bounds: [{X: 23, Y: 172}, {X: 58, Y: 197}]}
PS99_UI_POSITION_MAP["HUD_Teleport_Button"] := {Position: {X: 106, Y: 188}, Bounds: [{X: 104, Y: 180}, {X: 118, Y: 200}]}
PS99_UI_POSITION_MAP["HUD_Teleport_Button_Red"] := {Position: {X: 106, Y: 188}, Bounds: [{X: 104, Y: 186}, {X: 114, Y: 200}]}
;Lower bounds ({X: 112, Y: 192})

PS99_UI_POSITION_MAP["HUD_Hoverboard_Button"] := {Position: {X: 40, Y: 247}, Bounds: [{X: 597, Y: 87}, {X: 650, Y: 135}]}
PS99_UI_POSITION_MAP["HUD_AutoHatch_Button"] := {Position: {X: 106, Y: 247}, Bounds: [{X: 597, Y: 87}, {X: 650, Y: 135}]}
PS99_UI_POSITION_MAP["HUD_AutoHatch_Button_Toggle"] := {Position: {X: 119, Y: 231}, Bounds: [{X: 117, Y: 228}, {X: 122, Y: 235}]}

PS99_UI_POSITION_MAP["HUD_AutoFarm_Button"] := {Position: {X: 37, Y: 306}, Bounds: [{X: 24, Y: 299}, {X: 59, Y: 324}]}
PS99_UI_POSITION_MAP["HUD_AutoFarm_Button_Toggle"] := {Position: {X: 57, Y: 293}, Bounds: [{X: 55, Y: 290}, {X: 61, Y: 296}]}

PS99_UI_POSITION_MAP["HUD_AutoTap_Button"] := {Position: {X: 106, Y: 306}, Bounds: [{X: 95, Y: 305}, {X: 116, Y: 321}]}
PS99_UI_POSITION_MAP["HUD_AutoTap_Button_Toggle"] := {Position: {X: 119, Y: 293}, Bounds: [{X: 117, Y: 290}, {X: 122, Y: 296}]}
PS99_UI_POSITION_MAP["HUD_SuperComputer_Button"] := {Position: {X: 106, Y: 365}, Bounds: [{X: 95, Y: 365}, {X: 114, Y: 386}]}

; Bottom Bar
PS99_UI_POSITION_MAP["Clan_Button"] := {Position: {X: 488, Y: 517}, Bounds: [{X: 454, Y: 494}, {X: 508, Y: 535}]}


; Clan Menu
PS99_UI_POSITION_MAP["Clan_Side_Buttons"] := {Position: {X: 150, Y: 172}, Bounds: [{X: 54, Y: 146}, {X: 228, Y: 365}]}
PS99_UI_POSITION_MAP["Clan_Name_Label"] := {Position: {X: 400, Y: 172}, Bounds: [{X: 388, Y: 171}, {X: 533, Y: 233}]}



; Teleport Menu
PS99_UI_POSITION_MAP["Teleport_Middle"] := {Position: {X: 312, Y: 202}, Bounds: [{X: 260, Y: 153}, {X: 359, Y: 259}]}
PS99_UI_POSITION_MAP["Teleport_Spawn"] := {Position: {X: 23, Y: 197}, Bounds: [{X: 10, Y: 184}, {X: 34, Y: 207}]}
PS99_UI_POSITION_MAP["Teleport_World1"] := {Position: {X: 23, Y: 240}, Bounds: [{X: 10, Y: 229}, {X: 34, Y: 250}]}
PS99_UI_POSITION_MAP["Teleport_World2"] := {Position: {X: 23, Y: 286}, Bounds: [{X: 10, Y: 275}, {X: 34, Y: 297}]}
PS99_UI_POSITION_MAP["Teleport_World3"] := {Position: {X: 23, Y: 330}, Bounds: [{X: 10, Y: 320}, {X: 34, Y: 339}]}


; Hatch Settings Menu
PS99_UI_POSITION_MAP["HatchSettings_Autohatch_Toggle"] := {Position: {X: 523, Y: 193}, Bounds: [{X: 450, Y: 170},{X: 592, Y: 215}]}
PS99_UI_POSITION_MAP["HatchSettings_ChargedEggs_Toggle"] := {Position: {X: 523, Y: 295}, Bounds: [{X: 450, Y: 272},{X: 592, Y: 318}]}
PS99_UI_POSITION_MAP["HatchSettings_GoldenEggs_Toggle"] := {Position: {X: 523, Y: 398}, Bounds: [{X: 450, Y: 376},{X: 592, Y: 422}]}

PS99_UI_POSITION_MAP["Ultimate_Check"] := {Position: {X: 235, Y: 479}, Bounds: [{X: 230, Y: 475},{X: 250, Y: 489}]}