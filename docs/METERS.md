# VU Meter Configuration Reference

Complete reference for meters.txt configuration.

## File Structure

```ini
[meter-name]
meter.type = circular
channels = 2
ui.refresh.period = 0.033
bgr.filename = meter-bgr.png
fgr.filename = meter-fgr.png
indicator.filename = meter-needle.png
screen.bgr = meter-ext.jpg
meter.x = 0
meter.y = 100

# --- volumio optional entries -------
config.extend = True
```

## Meter Types

### Circular (Needle) - Stereo

```ini
[example-circular]
meter.type = circular
channels = 2
ui.refresh.period = 0.033
bgr.filename = meter-bgr.png
fgr.filename = meter-fgr.png
indicator.filename = meter-needle.png
start.angle = 45
stop.angle = -45
steps.per.degree = 4
distance = 100
left.origin.x = 200
left.origin.y = 200
right.origin.x = 600
right.origin.y = 200
meter.x = 0
meter.y = 100
screen.bgr = meter-ext.jpg
```

### Circular (Needle) - Mono

```ini
[example-circular-mono]
meter.type = circular
channels = 1
ui.refresh.period = 0.033
bgr.filename = meter-bgr.png
indicator.filename = meter-needle.png
start.angle = 75
stop.angle = -75
steps.per.degree = 4
distance = 100
mono.origin.x = 401
mono.origin.y = 157
meter.x = 0
meter.y = 0
```

### Linear (Bar)

```ini
[example-linear]
meter.type = linear
channels = 2
ui.refresh.period = 0.033
bgr.filename = meter-bgr.png
fgr.filename = meter-fgr.png
indicator.filename = meter-indicator.png
left.x = 20
left.y = 50
right.x = 20
right.y = 150
position.regular = 10
position.overload = 2
step.width.regular = 8
step.width.overload = 8
direction = left-right
meter.x = 0
meter.y = 0
screen.bgr = meter-ext.jpg
```

## Core Settings

| Key | Type | Description |
|-----|------|-------------|
| meter.type | string | circular or linear |
| channels | int | 1 (mono) or 2 (stereo) |
| ui.refresh.period | float | Frame time (0.033 = 30fps) |
| meter.visible | bool | Show/hide VU meter needles |

## Volumio Extended Configuration

Enable with `config.extend = True`

### Album Art

```ini
albumart.pos = 20,20
albumart.dimension = 200,200
albumart.border = 1
albumart.mask = mask.png
albumart.rotation = True
albumart.rotation.speed = 1.5
```

| Key | Description |
|-----|-------------|
| albumart.pos | Position x,y |
| albumart.dimension | Width,height |
| albumart.border | Border width in pixels |
| albumart.mask | Optional mask image (PNG) |
| albumart.rotation | Enable rotation: True/False |
| albumart.rotation.speed | Rotation speed in RPM |

### Vinyl Turntable

Spinning vinyl disc beneath album art. Alternative to reel system.

```ini
vinyl.filename = vinyl_disc.png
vinyl.pos = 269,42
vinyl.center = 466,242
vinyl.direction = cw
```

| Key | Description |
|-----|-------------|
| vinyl.filename | PNG file for vinyl disc |
| vinyl.pos | Top-left position x,y |
| vinyl.center | Rotation pivot point x,y |
| vinyl.direction | cw or ccw |

**Vinyl-Album Art Coupling:**
- `albumart.rotation = True`: Album art spins WITH vinyl (locked)
- `albumart.rotation = False`: Vinyl spins, album art stays static
- Speed controlled by `albumart.rotation.speed` (shared)

### Cassette Reels

Rotating tape reels for cassette-style skins.

```ini
reel.left.filename = reel_left.png
reel.left.pos = 100,150
reel.left.center = 137,187
reel.right.filename = reel_right.png
reel.right.pos = 300,150
reel.right.center = 355,187
reel.rotation.speed = 1.5
reel.direction = ccw
```

| Key | Description |
|-----|-------------|
| reel.left.filename | Left reel PNG file |
| reel.left.pos | Left reel top-left position x,y |
| reel.left.center | Left reel rotation center x,y |
| reel.right.filename | Right reel PNG file |
| reel.right.pos | Right reel top-left position x,y |
| reel.right.center | Right reel rotation center x,y |
| reel.rotation.speed | Rotation speed in RPM |
| reel.direction | cw or ccw |

### Tonearm

Animated tonearm that tracks playback progress.

```ini
tonearm.filename = tonearm.png
tonearm.pos = 727,129
tonearm.pivot.screen = 727,129
tonearm.pivot.image = 75,102
tonearm.angle.rest = -5
tonearm.angle.start = -21
tonearm.angle.end = -39
tonearm.drop.duration = 1.8
tonearm.lift.duration = 1.2
```

| Key | Description |
|-----|-------------|
| tonearm.filename | Tonearm PNG file |
| tonearm.pos | Draw position (usually same as pivot.screen) |
| tonearm.pivot.screen | Screen coordinates of pivot point |
| tonearm.pivot.image | Pivot point within the PNG image |
| tonearm.angle.rest | Angle when parked (degrees) |
| tonearm.angle.start | Angle at track start (outer groove) |
| tonearm.angle.end | Angle at track end (inner groove) |
| tonearm.drop.duration | Drop animation duration (seconds) |
| tonearm.lift.duration | Lift animation duration (seconds) |

**Angle convention:** 0 = RIGHT, negative = clockwise (-90 = DOWN)

### Track Information

```ini
playinfo.title.pos = 250,30,bold
playinfo.title.color = 255,255,255
playinfo.title.maxwidth = 400

playinfo.artist.pos = 250,60,regular
playinfo.artist.color = 200,200,200
playinfo.artist.maxwidth = 400

playinfo.album.pos = 250,90,light
playinfo.album.color = 180,180,180
playinfo.album.maxwidth = 400

playinfo.center = False
```

Position format: `x,y,style` where style is `bold`, `regular`, or `light`

### Scrolling Speed

```ini
playinfo.scrolling.speed = 40
playinfo.scrolling.speed.artist = 15
playinfo.scrolling.speed.title = 25
playinfo.scrolling.speed.album = 20
```

| Key | Description |
|-----|-------------|
| playinfo.scrolling.speed | Global speed (pixels/sec) |
| playinfo.scrolling.speed.artist | Artist field speed |
| playinfo.scrolling.speed.title | Title field speed |
| playinfo.scrolling.speed.album | Album field speed |

Per-field speeds override global speed. Default is 40.

### Fonts

```ini
font.size.digi = 28
font.size.light = 14
font.size.regular = 16
font.size.bold = 18
font.color = 255,255,255
```

### Time and Format

```ini
time.remaining.pos = 700,120
time.remaining.color = 255,255,255

playinfo.type.pos = 700,30
playinfo.type.color = 255,255,255
playinfo.type.dimension = 32,32

playinfo.samplerate.pos = 700,70,regular
playinfo.samplerate.maxwidth = 130
```

### Spectrum Overlay

```ini
spectrum.visible = True
spectrum.name = s.1
spectrum.size = 800,150
spectrum.pos = 0,300
```

## Render Z-Order

Bottom to top:
1. Background (bgr.filename)
2. Meters/Spectrum
3. Reels
4. Vinyl
5. Album Art
6. Tonearm
7. Text/Metadata
8. Foreground (fgr.filename)

## Deprecated Settings

| Setting | Replacement |
|---------|-------------|
| playinfo.maxwidth | Use playinfo.title.maxwidth, etc. |
