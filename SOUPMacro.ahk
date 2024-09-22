#Requires AutoHotkey v2.0

global PATH_DIR := A_MyDocuments
global FOLDER_ARRAY := [
    "SOUP_Macros\Macros",
    "SOUP_Macros\Utils",
    "SOUP_Macros\Storage",
    "SOUP_Macros\blah"
]

for _, path in FOLDER_ARRAY {
    fullPath := PATH_DIR "\" path
    DirCreate(fullPath)
}