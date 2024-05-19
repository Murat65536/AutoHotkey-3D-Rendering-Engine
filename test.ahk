#Requires AutoHotkey v2.0.15+
#SingleInstance Force

Test(&var1) {
    &var1 += 1
}

l := [1]
Test(l[1])
MsgBox(l[1])