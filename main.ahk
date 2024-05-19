#SingleInstance Force
#Requires AutoHotkey v2.0.15+
#Include libraries\Gdip_all.ahk


; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox('Gdiplus failed to start. Please ensure you have gdiplus on your system')
	ExitApp
}
OnExit ExitFunc

WindowWidth := 640
WindowHeight := 480
Window := Gui('-DPIScale')
Window.OnEvent('Close', Gui_Close)
Window.Title := '3D Rendering Engine'
Window.BackColor := '000000'
Canvas := Window.add('Picture', 'x0 y0 w' WindowWidth ' h' WindowHeight ' 0xE')
Window.Show()
Window.Width := WindowWidth
Window.Height := WindowHeight
; Window.Maximize()

numSect := 4
numWall := 16

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

wallLen := 1
walls := Array()
while (wallLen <= 30) {
	walls.InsertAt(wallLen, {x1: unset, y1: unset, x2: unset, y2: unset, c: unset})
	wallLen++
}

sectorLen := 1
Sectors := Array()
while (sectorLen <= 30) {
	Sectors.InsertAt(sectorLen, {ws: unset, we: unset, z1: unset, z2: unset, d: unset, c1: unset, c2: unset})
	sectorLen++
}

Canvas.GetPos(,, &Posw, &Posh)
pBitmap := Gdip_CreateBitmap(Posw, Posh)
G := Gdip_GraphicsFromImage(pBitmap)

Main()
return

Main() {
	deg := 1
	while (deg <= 360) {
		Math.cosvar.InsertAt(deg, Cos((deg - 1) / 180 * (ATan(1) * 4)))
		Math.sinvar.InsertAt(deg, Sin((deg - 1) / 180 * (ATan(1) * 4)))
		deg++
	}
	
	s := 1
	v1 := 1
	v2 := 1
	while (s <= numSect) {
		Sectors[s].ws := SectorData[v1][1]
		Sectors[s].we := SectorData[v1][2]
		Sectors[s].z1 := SectorData[v1][3]
		Sectors[s].z2 := SectorData[v1][4] - SectorData[v1][3]
		Sectors[s].c1 := SectorData[v1][5]
		Sectors[s].c2 := SectorData[v1][6]
		v1++
		w := Sectors[s].ws
		while (w < Sectors[s].we) {
			walls[w + 1].x1 := WallData[v2][1]
			walls[w + 1].y1 := WallData[v2][2]
			walls[w + 1].x2 := WallData[v2][3]
			walls[w + 1].y2 := WallData[v2][4]
			walls[w + 1].c := WallData[v2][5]
			v2++
			w++
		}
		s++
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
	global hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	return
}

MovePlayer() {
	
	Up := GetKeyState('w')
	Left := GetKeyState('a')
	Right := GetKeyState('d')
	Down := GetKeyState('s')
	Look := GetKeyState('m')
	StrafeLeft := GetKeyState('left')
	StrafeRight := GetKeyState('right')
	
	dx := Math.cosvar[Player.a + 1] * 10
	dy := Math.sinvar[Player.a + 1] * 10
	if (Up == 1) {
		if (Look == 1) {
			Player.z -= 4
		}
		else {
			Player.x += dx
			Player.y += dy
		}
	}
	if (Down == 1) {
		if (Look == 1) {
			Player.z += 4
		}
		else {
			Player.x -= dx
			Player.y -= dy
		}
	}
	if (Left == 1) {
		if (Look == 1){
			Player.l -= 1
		}
		else {
			Player.a -= 4
			if (Player.a < 0) {
				Player.a += 360
			}
		}
	}
	if (Right == 1) {
		if (Look == 1) {
			Player.l += 1
		}
		else {
			Player.a += 4
			if (Player.a > 359) {
				Player.a -= 360
			}
		}
	}
	if (StrafeLeft == 1) {
		Player.x += dy
		Player.y -= dx
	}
	if (StrafeRight == 1) {
		Player.x -= dy
		Player.y += dx
	}
}

ClipBehindPlayer(x1, y1, z1, x2, y2, z2) {
	d := y1 - y2
	if (d == 0) {
		d := 1
	}
	s := y1 / (y1 - y2)
	x1 += s * (x2 - x1)
	y1 += s * (y2 - y1)
	if (y1 == 0) {
		y1 := 1
	}
	z1 += s * (z2 - z1)
	return [x1, y1, z1]
}

DrawWall(x1, x2, b1, b2, t1, t2, c, s) {
	dyb := b2 - b1
	dyt := t2 - t1
	dx := x2 - x1
	if (dx == 0) {
		dx := 1
	}
	xs := x1
	if (x1 < 0) {
		x1 := 0
	}
	else if (x1 > WindowWidth) {
		x1 := WindowWidth
	}
	if (x2 < 0) {
		x2 := 0
	}
	else if (x2 > WindowWidth) {
		x2 := WindowWidth
	}
	y1 := dyb * (x1 - xs + 0.5) / dx + b1
	y2 := dyt * (x1 - xs + 0.5) / dx + t1
	y3 := dyb * (x2 - xs + 0.5) / dx + b1
	y4 := dyt * (x2 - xs + 0.5) / dx + t1
	if (y1 < 0) {
		y1 := 0
	}
	else if (y1 > WindowHeight) {
		y1 := WindowHeight
	}
	if (y2 < 0) {
		y2 := 0
	}
	else if (y2 > WindowHeight) {
		y2 := WindowHeight
	}
	if (y3 < 0) {
		y3 := 0
	}
	else if (y3 > WindowHeight) {
		y3 := WindowHeight
	}
	if (y4 < 0) {
		y4 := 0
	}
	else if (y4 > WindowHeight) {
		y4 := WindowHeight
	}
	Polygon(x1 ',' y1 '|' x1 ',' y2 '|' x2 ',' y4 '|' x2 ',' y3, c)
}

ClearBackground() {
	global pBitmap
	global G
	global hBitmap

	Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap)
	pBitmap := Gdip_CreateBitmap(Posw, Posh)
	G := Gdip_GraphicsFromImage(pBitmap)
}

Dist(x1, y1, x2, y2) {
	distance := Sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
	return distance
}

Draw3D() {
	global Player
	s := 1
	while (s <= numSect) {
		Sectors[s].d := 0
		w := Sectors[s].ws + 1
		while (w < Sectors[s].we) {
			CS := Math.cosvar[Player.a + 1]
			SN := Math.sinvar[Player.a + 1]
			x1 := walls[w].x1 - Player.x
			y1 := walls[w].y1 - Player.y
			x2 := walls[w].x2 - Player.x
			y2 := walls[w].y2 - Player.y
			wx := [x1 * CS - y1 * SN, x2 * CS - y2 * SN, x1 * CS - y1 * SN, x2 * CS - y2 * SN]
			wy := [y1 * CS + x1 * SN, y2 * CS + x2 * SN, y1 * CS + x1 * SN, y2 * CS + x2 * SN]
			Sectors[s].d += Dist(0, 0, (wx[1] + wx[2]) / 2, (wy[1] + wy[2]) / 2)
			w++
		}
		s++
	}
	s := 0
	while (s < numSect - 1) {
		w := 1
		while (w <= numSect - s - 1) {
			if (Sectors[w].d < Sectors[w + 1].d) {
				st := Sectors[w]
				Sectors[w] := Sectors[w + 1]
				Sectors[w + 1] := st
			}
			w++
		}
		s++
	}
	s := 1
	while (s <= numSect) {
		Sectors[s].d := 0
		w := Sectors[s].ws
		while (w < Sectors[s].we) {
			CS := Math.cosvar[Player.a + 1]
			SN := Math.sinvar[Player.a + 1]
			x1 := walls[w + 1].x1 - Player.x
			y1 := walls[w + 1].y1 - Player.y
			x2 := walls[w + 1].x2 - Player.x
			y2 := walls[w + 1].y2 - Player.y
			wx := [x1 * CS - y1 * SN, x2 * CS - y2 * SN, x1 * CS - y1 * SN, x2 * CS - y2 * SN]
			wy := [y1 * CS + x1 * SN, y2 * CS + x2 * SN, y1 * CS + x1 * SN, y2 * CS + x2 * SN]
			Sectors[s].d += Dist(0, 0, (wx[1] + wx[2]) / 2, (wy[1] + wy[2]) / 2)
			wz := [Sectors[s].z1 - Player.z + ((Player.l * wy[1]) / 32), Sectors[s].z1 - Player.z + ((Player.l * wy[2]) / 32), (0 - Player.z + ((Player.l * wy[1]) / 32)) + Sectors[s].z2, (0 - Player.z + ((Player.l * wy[2]) / 32)) + Sectors[s].z2]
			if (wy[1] < 1 && wy[2] < 1) {
				w++
				continue
			}
			if (wy[1] < 1) {
				clip := ClipBehindPlayer(wx[1], wy[1], wz[1], wx[2], wy[2], wz[2])
				wx[1] := clip[1]
				wy[1] := clip[2]
				wz[1] := clip[3]
				clip := ClipBehindPlayer(wx[3], wy[3], wz[3], wx[4], wy[4], wz[4])
				wx[3] := clip[1]
				wy[3] := clip[2]
				wz[3] := clip[3]
			}
			if (wy[2] < 1) {
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
			DrawWall(wx[1], wx[2], wy[1], wy[2], wy[3], wy[4], walls[w + 1].c, s)
			w++
		}
		Sectors[s].d /= (Sectors[s].we - Sectors[s].ws)
		s++
	}
	SetImage(Canvas.Hwnd, hBitmap)
	return
}

Display() {
	
	loop {
		MovePlayer()
		Draw3D()
		ClearBackground()
	}
	return
}

Gui_Close(GuiObj) {
GuiClose:
	ExitApp
return
}

ExitFunc(ExitReason, ExitCode)
{
	global
	; gdi+ may now be shutdown
	Gdip_Shutdown(pToken)
}