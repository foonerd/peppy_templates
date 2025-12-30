# PeppyMeter Templates

Community collection of meter skins and spectrum visualizations for [PeppyMeter Screensaver](https://github.com/foonerd/peppy_screensaver).

## Browse Templates

**[View Template Catalog](catalog/README.md)** - Browse all templates organized by resolution.

## Repository Structure

```
template_peppy/           - VU meters only
templates_peppy_spectrum/ - Combined VU meters + spectrum
templates_spectrum/       - Spectrum analyzers only
catalog/                  - Auto-generated browsing catalog

Each category contains:
  [width]/
    [height]/
      [template-name].zip
      previews/
      README.md (auto-generated)
```

## Categories

| Category | Content | Install Location |
|----------|---------|------------------|
| `template_peppy` | VU meters only | `templates/` |
| `templates_spectrum` | Spectrum only | `templates_spectrum/` |
| `templates_peppy_spectrum` | Both combined | Both folders (see below) |

All paths relative to `/data/INTERNAL/peppy_screensaver/`

## Installation

### VU Meter Only (from template_peppy)

1. Download the zip file
2. Extract the zip file
3. Copy the extracted folder to `/data/INTERNAL/peppy_screensaver/templates/`

**Example:**
```
Download: 800x480_retro_wood.zip
Extract:  800x480_retro_wood/
Copy to:  /data/INTERNAL/peppy_screensaver/templates/800x480_retro_wood/
```

### Spectrum Only (from templates_spectrum)

1. Download the zip file
2. Extract the zip file
3. Copy the extracted folder to `/data/INTERNAL/peppy_screensaver/templates_spectrum/`

**Example:**
```
Download: 800x480_retro_wood.zip
Extract:  800x480_retro_wood/
Copy to:  /data/INTERNAL/peppy_screensaver/templates_spectrum/800x480_retro_wood/
```

### Combined VU + Spectrum (from templates_peppy_spectrum)

1. Download the zip file
2. Extract the zip file
3. Open the extracted folder - you will see `templates/` and `templates_spectrum/` subfolders
4. Copy the contents of `templates/` to `/data/INTERNAL/peppy_screensaver/templates/`
5. Copy the contents of `templates_spectrum/` to `/data/INTERNAL/peppy_screensaver/templates_spectrum/`

**Example:**
```
Download: 800x480_retro_wood.zip
Extract:  800x480_retro_wood/
Inside:   800x480_retro_wood/templates/800x480_retro_wood/
          800x480_retro_wood/templates_spectrum/800x480_retro_wood/

Copy:     templates/800x480_retro_wood/ 
      to: /data/INTERNAL/peppy_screensaver/templates/800x480_retro_wood/

Copy:     templates_spectrum/800x480_retro_wood/
      to: /data/INTERNAL/peppy_screensaver/templates_spectrum/800x480_retro_wood/
```

## Available Resolutions

| Width | Heights | Common Displays |
|-------|---------|-----------------|
| 0800 | 480, 600 | 7" RPi displays |
| 1024 | 600, 768 | 10" tablets |
| 1280 | 720, 800 | HD displays |
| 1920 | 1080 | Full HD |
| 3840 | 2160 | 4K displays |

## Documentation

- [Template Catalog](catalog/README.md) - Browse all templates
- [VU Meter Configuration](docs/METERS.md)
- [Spectrum Configuration](docs/SPECTRUM.md)
- [Contributing Guide](CONTRIBUTING.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for submission guidelines.

### Quick Start

1. Create your template as a zip file
2. Upload to correct category/resolution folder
3. Automation generates README and catalog entries

## Credits

- Original PeppyMeter: [project-owner](https://github.com/project-owner)
- Original PeppySpectrum: [project-owner](https://github.com/project-owner)
- Volumio adaptation: [foonerd](https://github.com/foonerd)

## License

Individual templates may have their own licenses. See each template's README.

## Related

- [PeppyMeter Screensaver Plugin](https://github.com/foonerd/peppy_screensaver)
- [PeppyMeter Build Tools](https://github.com/foonerd/peppy_builds)
