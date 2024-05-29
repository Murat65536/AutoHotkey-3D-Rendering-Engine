#SingleInstance Force
#Requires AutoHotkey v2.0.15+
#Include libraries\Gdip_all.ahk


If !pToken := Gdip_Startup()
{
	MsgBox('Gdiplus failed to start. Please ensure you have gdiplus on your system')
	ExitApp
}
OnExit ExitFunc

WindowWidth := 640
WindowHeight := 480
Window := Gui('-DPIScale +E0x02000000 +E0x00080000')
Window.OnEvent('Close', Gui_Close)
Window.Title := '3D Rendering Engine'
Window.BackColor := '000000'
Canvas := Window.add('Picture', 'x0 y0 w' WindowWidth ' h' WindowHeight ' 0xE')
Window.Show("W " WindowWidth " H " WindowHeight)

NumSect := 4
NumWall := 16

SectorData := [
	[0, 4, 0, 40, 2, 3],
	[4, 8, 0, 40, 4, 5],
	[8, 12, 0, 40, 6, 7],
	[12, 16, 0, 40, 0, 1]
]

WallData := [
	[0, 0, 32, 0, 0],
	[32, 0, 32, 32, 1],
	[32, 32, 0,32, 0],
	[0, 32, 0, 0, 1],
	
	[64, 0, 96, 0, 2],
	[96, 0, 96, 32, 3],
	[96, 32, 64, 32, 2],
	[64,32, 64, 0, 3],
	
	[64, 64, 96, 64, 4],
	[96, 64, 96, 96, 5],
	[96, 96, 64, 96, 4],
	[64, 96, 64, 64, 5],
	
	[0, 64, 32, 64, 6],
	[32, 64, 32, 96, 7],
	[32, 96, 0, 96, 6],
	[0, 96, 0, 64, 7]
]

Math := {
	cosvar: Array(),
	sinvar: Array()
}

Player := {
	x: 70,
	y: -110,
	z: 20,
	a: 0,
	l: 0
}

walls := Array()
Loop (30) {
	walls.InsertAt(A_Index, {x1: unset, y1: unset, x2: unset, y2: unset, c: unset})
}

Sectors := Array()
Loop (30) {
	Sectors.InsertAt(A_Index, {ws: unset, we: unset, z1: unset, z2: unset, d: unset, c1: unset, c2: unset, sw: [], surface: unset})
}

Canvas.GetPos(,, &Posw, &Posh)
pBitmap := Gdip_CreateBitmap(Posw, Posh)
G := Gdip_GraphicsFromImage(pBitmap)

Main()

Main() {
	Loop (360) {
		Math.sinvar.InsertAt(A_Index, Sin((A_Index - 1) / 180 * (ATan(1) * 4)))
		Math.cosvar.InsertAt(A_Index, Cos((A_Index - 1) / 180 * (ATan(1) * 4)))
	}
	
	v2 := 1
	Loop (NumSect) {
		Sectors[A_Index].ws := SectorData[A_Index][1]
		Sectors[A_Index].we := SectorData[A_Index][2]
		Sectors[A_Index].z1 := SectorData[A_Index][3]
		Sectors[A_Index].z2 := SectorData[A_Index][4] - SectorData[A_Index][3]
		Sectors[A_Index].c1 := SectorData[A_Index][5]
		Sectors[A_Index].c2 := SectorData[A_Index][6]
		w := Sectors[A_Index].ws
		Loop (Sectors[A_Index].we - Sectors[A_Index].ws) {
			walls[w + A_Index].x1 := WallData[v2][1]
			walls[w + A_Index].y1 := WallData[v2][2]
			walls[w + A_Index].x2 := WallData[v2][3]
			walls[w + A_Index].y2 := WallData[v2][4]
			walls[w + A_Index].c := WallData[v2][5]
			v2++
		}
	}
	
	Display()
}

Polygon(coords, color) {
	switch color {
		case 0:
			rgb := 0xFFFFFFFF
		case 1:
			rgb := 0xFFA0A000
		case 2:
			rgb := 0xFF00FF00
		case 3:
			rgb := 0xFF00A000
		case 4:
			rgb := 0xFF00FFFF
		case 5:
			rgb := 0xFF00A0A0
		case 6:
			rgb := 0xFFA06400
		case 7:
			rgb := 0xFF6E3200
		case 8:
			rgb := 0xFF003C82
		default:
			rgb := 0x00000000
	}
	Gdip_SetSmoothingMode(G, 4)
	pBrush := Gdip_BrushCreateSolid(rgb)
	Gdip_FillPolygon(G, pBrush, coords)
	Gdip_DeleteBrush(pBrush)
	Return
}

MovePlayer() {
	Up := GetKeyState('w')
	Left := GetKeyState('a')
	Right := GetKeyState('d')
	Down := GetKeyState('s')
	Look := GetKeyState('m')
	StrafeLeft := GetKeyState('left')
	StrafeRight := GetKeyState('right')
	
	dx := Math.sinvar[Player.a + 1]
	dy := Math.cosvar[Player.a + 1]
	If (Up == 1) {
		If (Look == 1) {
			Player.z -= 4
		}
		Else {
			Player.x += dx
			Player.y += dy
		}
	}
	If (Down == 1) {
		If (Look == 1) {
			Player.z += 4
		}
		Else {
			Player.x -= dx
			Player.y -= dy
		}
	}
	If (Left == 1) {
		If (Look == 1){
			Player.l -= 1
		}
		Else {
			Player.a -= 1
			If (Player.a < 0) {
				Player.a += 360
			}
		}
	}
	If (Right == 1) {
		If (Look == 1) {
			Player.l += 1
		}
		Else {
			Player.a += 1
			If (Player.a > 359) {
				Player.a -= 360
			}
		}
	}
	If (StrafeLeft == 1) {
		Player.x -= dy
		Player.y += dx
	}
	If (StrafeRight == 1) {
		Player.x += dy
		Player.y -= dx
	}
}

ClipBehindPlayer(x1, y1, z1, x2, y2, z2) {
    deltaY := y1 - y2
    If (deltaY == 0) {
        deltaY := 1
    }
    ratio := y1 / (y1 - y2)
    x1 += ratio * (x2 - x1)
    y1 += ratio * (y2 - y1)
    If (y1 == 0) {
        y1 := 1
    }
    z1 += ratio * (z2 - z1)
    Return [x1, y1, z1]
}

DrawWall(x1, x2, b1, b2, t1, t2, c, s) {
	dyb := b2 - b1
	dyt := t2 - t1
	dx := x2 - x1
	If (dx == 0) {
		dx := 1
	}
	xs := x1
	If (x1 < 0) {
		x1 := 0
	}
	Else If (x1 > WindowWidth) {
		x1 := WindowWidth
	}
	If (x2 < 0) {
		x2 := 0
	}
	Else If (x2 > WindowWidth) {
		x2 := WindowWidth
	}
	y1 := dyb * (x1 - xs + 0.5) / dx + b1
	y2 := dyt * (x1 - xs + 0.5) / dx + t1
	y3 := dyb * (x2 - xs + 0.5) / dx + b1
	y4 := dyt * (x2 - xs + 0.5) / dx + t1
	If (y1 < 0) {
		y1 := 0
	}
	Else If (y1 > WindowHeight) {
		y1 := WindowHeight
	}
	If (y2 < 0) {
		y2 := 0
	}
	Else If (y2 > WindowHeight) {
		y2 := WindowHeight
	}
	If (y3 < 0) {
		y3 := 0
	}
	Else If (y3 > WindowHeight) {
		y3 := WindowHeight
	}
	If (y4 < 0) {
		y4 := 0
	}
	Else If (y4 > WindowHeight) {
		y4 := WindowHeight
	}
	Polygon(x1 ',' y1 '|' x1 ',' y2 '|' x2 ',' y4 '|' x2 ',' y3, c)
}

ClearBackground() {
	global pBitmap
	global G

	Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap)
	pBitmap := Gdip_CreateBitmap(Posw, Posh)
	G := Gdip_GraphicsFromImage(pBitmap)
}

Dist(x1, y1, x2, y2) {
	distance := Sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
	Return distance
}

Draw3D() {
	global Player
	
	CS := Math.cosvar[Player.a + 1]
	SN := Math.sinvar[Player.a + 1]
	
	s := 1
	Loop (NumSect) {
		Sectors[A_Index].d := 0
		Loop (Sectors[A_Index].we - (Sectors[A_Index].ws + 1)) {
			x1 := walls[Sectors[s].ws + A_Index].x1 - Player.x
			x2 := walls[Sectors[s].ws + A_Index].x2 - Player.x
			y1 := walls[Sectors[s].ws + A_Index].y1 - Player.y
			y2 := walls[Sectors[s].ws + A_Index].y2 - Player.y
			wx := [x1 * CS - y1 * SN, x2 * CS - y2 * SN, x1 * CS - y1 * SN, x2 * CS - y2 * SN]
			wy := [y1 * CS + x1 * SN, y2 * CS + x2 * SN, y1 * CS + x1 * SN, y2 * CS + x2 * SN]
			Sectors[s].d += Dist(0, 0, (wx[1] + wx[2]) / 2, (wy[1] + wy[2]) / 2)
		}
		s++
	}
	Loop (NumSect - 1) {
		Loop (NumSect - (A_Index - 1) - 1) {
			If (Sectors[A_Index].d < Sectors[A_Index + 1].d) {
				st := Sectors[A_Index]
				Sectors[A_Index] := Sectors[A_Index + 1]
				Sectors[A_Index + 1] := st
			}
		}
	}
	s := 1
	Loop (NumSect) {
		Loop (Sectors[A_Index].we - Sectors[A_Index].ws) {
			x1 := walls[Sectors[s].ws + A_Index].x1 - Player.x
			x2 := walls[Sectors[s].ws + A_Index].x2 - Player.x
			y1 := walls[Sectors[s].ws + A_Index].y1 - Player.y
			y2 := walls[Sectors[s].ws + A_Index].y2 - Player.y
			wx := [x1 * CS - y1 * SN, x2 * CS - y2 * SN, x1 * CS - y1 * SN, x2 * CS - y2 * SN]
			wy := [y1 * CS + x1 * SN, y2 * CS + x2 * SN, y1 * CS + x1 * SN, y2 * CS + x2 * SN]
			wz := [Sectors[s].z1 - Player.z + ((Player.l * wy[1]) / 32), Sectors[s].z1 - Player.z + ((Player.l * wy[2]) / 32), (0 - Player.z + ((Player.l * wy[1]) / 32)) + Sectors[s].z2, (0 - Player.z + ((Player.l * wy[2]) / 32)) + Sectors[s].z2]
			If (wy[1] < 1 && wy[2] < 1) {
				continue
			}
			If (wy[1] < 1) {
				clip := ClipBehindPlayer(wx[1], wy[1], wz[1], wx[2], wy[2], wz[2])
				wx[1] := clip[1]
				wy[1] := clip[2]
				wz[1] := clip[3]
				clip := ClipBehindPlayer(wx[3], wy[3], wz[3], wx[4], wy[4], wz[4])
				wx[3] := clip[1]
				wy[3] := clip[2]
				wz[3] := clip[3]
			}
			If (wy[2] < 1) {
				clip := ClipBehindPlayer(wx[2], wy[2], wz[2], wx[1], wy[1], wz[1])
				wx[2] := clip[1]
				wy[2] := clip[2]
				wz[2] := clip[3]
				clip := ClipBehindPlayer(wx[4], wy[4], wz[4], wx[3], wy[3], wz[3])
				wx[4] := clip[1]
				wy[4] := clip[2]
				wz[4] := clip[3]
			}
			wx := [wx[1] * 200 / wy[1] + (WindowWidth / 2), wx[2] * 200 / wy[2] + (WindowWidth / 2), wx[3] * 200 / wy[3] + (WindowWidth / 2), wx[4] * 200 / wy[4] + (WindowWidth / 2)]
			wy := [wz[1] * 200 / wy[1] + (WindowHeight / 2), wz[2] * 200 / wy[2] + (WindowHeight / 2), wz[3] * 200 / wy[3] + (WindowHeight / 2), wz[4] * 200 / wy[4] + (WindowHeight / 2)]
			If ((wx[2] - wx[1]) * 2 > 0) {
				DrawWall(wx[1], wx[2], wy[1], wy[2], wy[3], wy[4], walls[Sectors[s].ws + A_Index].c, s)
			}
		}
		Sectors[A_Index].d /= (Sectors[s].we - Sectors[A_Index].ws)
		s++
	}
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(Canvas.Hwnd, hBitmap)
	DeleteObject(hBitmap)
	Return
}

Print(string) {
	FileAppend(string "`r", "*")
}

Display() {
	Loop {
		MovePlayer()
		Draw3D()
		ClearBackground()
	}
	Return
}

Gui_Close(GuiObj) {
	GuiClose:
		ExitApp
	Return
}

ExitFunc(ExitReason, ExitCode)
{
	global
	Gdip_Shutdown(pToken)
}