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

## Playback Indicators

Display Volumio playback control states. Requires `config.extend = True`.

### Indicator Types

| Indicator | States | Source |
|-----------|--------|--------|
| Volume | 0-100 | `pushState.volume` |
| Mute | on/off | `pushState.mute` |
| Shuffle | off/shuffle/infinity | `pushState.random` + infinity event |
| Repeat | off/all/single | `pushState.repeat` + `repeatSingle` |
| Play/Pause/Stop | play/pause/stop | `pushState.status` |
| Progress | 0-100% | `pushState.seek` / `duration` |

### Display Modes

- **LED mode**: Colored shapes (circle/rectangle) with optional glow
- **Icon mode**: PNG images per state with optional glow

### Mute Indicator

LED mode:

```ini
mute.pos = 50,680
mute.led = 16,16
mute.led.shape = circle
mute.led.color = 255,0,0,64,64,64
mute.led.glow = 8
mute.led.glow.intensity = 0.7
mute.led.glow.color = 255,100,100,32,32,32
```

Icon mode:

```ini
mute.pos = 50,680
mute.icon = mute_on.png,mute_off.png
mute.icon.glow = 6
mute.icon.glow.intensity = 0.6
mute.icon.glow.color = 255,0,0,64,64,64
```

| Key | Description |
|-----|-------------|
| mute.pos | Position x,y |
| mute.led | LED size width,height (enables LED mode) |
| mute.led.shape | Shape: circle or rect |
| mute.led.color | Colors: on_r,on_g,on_b,off_r,off_g,off_b |
| mute.led.glow | Glow radius pixels (0 = no glow) |
| mute.led.glow.intensity | Glow opacity 0.0-1.0 |
| mute.led.glow.color | Glow colors (optional) |
| mute.icon | Icon files: on.png,off.png (enables icon mode) |
| mute.icon.glow | Icon glow radius |
| mute.icon.glow.intensity | Icon glow opacity |
| mute.icon.glow.color | Icon glow colors |

### Shuffle Indicator (3 states)

```ini
shuffle.pos = 50,720
shuffle.led = 16,16
shuffle.led.shape = circle
shuffle.led.color = 64,64,64,0,200,255,200,0,200
```

| Key | Description |
|-----|-------------|
| shuffle.led.color | 9 values: off_rgb, shuffle_rgb, infinity_rgb |
| shuffle.icon | 3 files: off.png,on.png,infinity.png |

### Repeat Indicator (3 states)

```ini
repeat.pos = 50,760
repeat.led = 16,16
repeat.led.shape = circle
repeat.led.color = 64,64,64,0,255,0,255,200,0
```

| Key | Description |
|-----|-------------|
| repeat.led.color | 9 values: off_rgb, all_rgb, single_rgb |
| repeat.icon | 3 files: off.png,all.png,single.png |

### Play/Pause/Stop Indicator (3 states)

```ini
playstate.pos = 50,640
playstate.led = 16,16
playstate.led.shape = circle
playstate.led.color = 64,64,64,255,200,0,0,255,0
```

| Key | Description |
|-----|-------------|
| playstate.led.color | 9 values: stop_rgb, pause_rgb, play_rgb |
| playstate.icon | 3 files: stop.png,pause.png,play.png |

### Volume Indicator

#### Numeric Style

```ini
volume.pos = 100,50
volume.style = numeric
volume.color = 255,255,255
volume.font.size = 32
```

#### Procedural Slider

```ini
volume.pos = 100,50
volume.dim = 200,20
volume.style = slider
volume.color = 0,200,255
volume.bg.color = 40,40,40
```

#### Image-Based Slider (Fader)

```ini
volume.pos = 580,150
volume.dim = 50,350
volume.style = slider
volume.slider.track = fader_track.png
volume.slider.tip = fader_tip.png
volume.slider.orientation = vertical
volume.slider.travel = 20,310
volume.slider.tip.offset = 0,0
```

| Key | Description |
|-----|-------------|
| volume.slider.track | Track/groove image (optional if in background) |
| volume.slider.tip | Tip/handle image (required for image mode) |
| volume.slider.orientation | vertical or horizontal |
| volume.slider.travel | Pixel range start,end for tip |
| volume.slider.tip.offset | Tip anchor offset x,y |

Travel: vertical 100%=top, 0%=bottom; horizontal 0%=left, 100%=right

#### Knob Style

```ini
volume.pos = 100,100
volume.dim = 80,80
volume.style = knob
volume.knob.image = volume_knob.png
volume.knob.angle.start = 225
volume.knob.angle.end = -45
```

| Key | Description |
|-----|-------------|
| volume.knob.image | Knob image filename |
| volume.knob.angle.start | Angle at volume 0% (degrees) |
| volume.knob.angle.end | Angle at volume 100% (degrees) |

#### Arc Style

```ini
volume.pos = 100,100
volume.dim = 80,80
volume.style = arc
volume.color = 0,255,100
volume.bg.color = 50,50,50
volume.arc.width = 8
volume.arc.angle.start = 225
volume.arc.angle.end = -45
```

| Key | Description |
|-----|-------------|
| volume.arc.width | Arc stroke width pixels |
| volume.arc.angle.start | Angle at volume 0% |
| volume.arc.angle.end | Angle at volume 100% |

### Progress Bar

```ini
progress.pos = 50,700
progress.dim = 400,6
progress.color = 0,200,255
progress.bg.color = 40,40,40
progress.border = 1
progress.border.color = 100,100,100
```

| Key | Description |
|-----|-------------|
| progress.pos | Position x,y |
| progress.dim | Width,height |
| progress.color | Fill color r,g,b |
| progress.bg.color | Background color r,g,b |
| progress.border | Border width (0 = none) |
| progress.border.color | Border color r,g,b |

## Render Z-Order

Bottom to top:
1. Background (bgr.filename)
2. Meters/Spectrum
3. Reels
4. Vinyl
5. Album Art
6. Tonearm
7. Playback Indicators
8. Text/Metadata
9. Foreground (fgr.filename)

## Deprecated Settings

| Setting | Replacement |
|---------|-------------|
| playinfo.maxwidth | Use playinfo.title.maxwidth, etc. |
