# Spectrum Analyzer Configuration Reference

Complete reference for spectrum.txt configuration.

## File Structure

```ini
[spectrum-name]
spectrum.type = bar
channels = 2
ui.refresh.period = 0.033
size = 800,200
position = 0,280
bgr.filename = spectrum-bgr.png
bar.filename = spectrum-bar.png
bars = 40
bar.width = 16
bar.height = 180
bar.gap = 4
```

## Spectrum Types

### Bar (Vertical)

```ini
[bar-spectrum]
spectrum.type = bar
channels = 2
ui.refresh.period = 0.033
size = 800,200
position = 0,280
bgr.filename = spectrum-bgr.png
bar.filename = spectrum-bar.png
bars = 40
bar.width = 16
bar.height = 180
bar.gap = 4
max.value = 100
direction = up
```

### With Reflection

```ini
[reflected-spectrum]
spectrum.type = bar
channels = 2
size = 800,300
position = 0,180
bar.filename = spectrum-bar.png
reflection.filename = spectrum-reflection.png
bars = 32
bar.width = 20
bar.height = 150
bar.gap = 5
reflection.height = 75
reflection.gap = 5
reflection.opacity = 128
```

## Core Settings

| Key | Type | Description |
|-----|------|-------------|
| spectrum.type | string | bar or pipe |
| channels | int | 1 or 2 |
| ui.refresh.period | float | Frame time |
| size | int,int | Width,Height |
| position | int,int | X,Y position |

## Bar Layout

| Key | Description |
|-----|-------------|
| bars | Number of frequency bars |
| bar.width | Width per bar (pixels) |
| bar.height | Maximum height |
| bar.gap | Space between bars |
| direction | up, down, left, right |

## Reflection

| Key | Description |
|-----|-------------|
| reflection.filename | Reflection image |
| reflection.height | Reflection height |
| reflection.gap | Gap from main bar |
| reflection.opacity | 0-255 |

## Color Mode (no images)

```ini
base.color = 0,255,0
mid.color = 255,255,0
peak.color = 255,0,0
```

## Integration with Meters

Reference spectrum from meters.txt:

```ini
spectrum.visible = True
spectrum.name = s.1
spectrum.size = 800,150
spectrum.pos = 0,300
```

| Key | Description |
|-----|-------------|
| spectrum.visible | Enable spectrum: True/False |
| spectrum.name | Name of spectrum in spectrum.txt |
| spectrum.size | Width,height override |
| spectrum.pos | Position x,y override |

## Performance Tips

| Setting | Recommendation |
|---------|----------------|
| bars | 20-40 for Pi 3/4 |
| ui.refresh.period | 0.033 or 0.05 |
| reflection | Disable if CPU constrained |
| size | Smaller = less CPU |
