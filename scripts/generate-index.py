#!/usr/bin/env python3
"""Write catalog/index.json, the machine-readable catalog of every template
zip in the repository, and a thumbnail of each preview under catalog/thumbs/.

Each entry names the zip (path under the raw base URL), its size and SHA-256,
its preview and thumbnail, and its units: the folders a player installs from
it. A unit is a directory in the zip that holds meters.txt (a PeppyMeter
template, installed under templates/) or spectrum.txt (a PeppySpectrum
template, installed under templates_spectrum/). The zips in this repository
are laid out in several ways (one folder, files at the root, a templates/
prefix, or a bundle of folders), and the units describe each one so the
installer needs no guessing: everything under a unit's "from" prefix lands in
"<install>/<folder>/", with paths kept relative to the prefix.

Run from the repository root after the READMEs generator. Thumbnails need
ImageMagick; without it the index still lists the previews.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RAW = 'https://raw.githubusercontent.com/foonerd/peppy_templates/main/'
CATEGORIES = ['template_peppy', 'templates_peppy_spectrum', 'templates_spectrum']
UNIT_FILES = {'meters.txt': ('meter', 'templates'), 'spectrum.txt': ('spectrum', 'templates_spectrum')}
CONTAINERS = {'', 'templates', 'templates_spectrum'}
THUMB_WIDTH = 320
FOLDER_NAME = re.compile(r'^[A-Za-z0-9][A-Za-z0-9 ._()+-]*$')


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def sections(text):
    """The [section] names of a PeppyMeter or PeppySpectrum config, without the [current] bookmark."""
    names = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('[') and line.endswith(']'):
            name = line[1:-1].strip()
            if name.lower() != 'current':
                names.append(name)
    return names


def units_of(path, default_folder):
    """The installable units of a template zip and any reasons it cannot be installed as is."""
    units = []
    problems = []
    with zipfile.ZipFile(path) as z:
        entries = [i for i in z.infolist() if not i.filename.startswith('__MACOSX/')]
        for info in entries:
            name = info.filename
            if name.startswith('/') or '..' in name.split('/') or '\\' in name:
                problems.append('unsafe entry %r' % name)
        for info in entries:
            head, _, base = info.filename.rpartition('/')
            if base not in UNIT_FILES:
                continue
            kind, install = UNIT_FILES[base]
            leaf = head.rpartition('/')[2]
            folder = default_folder if leaf in CONTAINERS else leaf
            if not FOLDER_NAME.match(folder):
                problems.append('folder name %r' % folder)
            units.append({
                'kind': kind,
                'install': install,
                'from': head + '/' if head else '',
                'folder': folder,
                'names': sections(z.read(info).decode('utf-8', 'replace')),
            })
    seen = set()
    for u in units:
        key = (u['install'], u['folder'])
        if key in seen:
            problems.append('two units install to %s/%s' % key)
        seen.add(key)
    if not units:
        problems.append('no meters.txt or spectrum.txt')
    return units, problems


def thumbnail(preview, thumb):
    if not shutil.which('convert'):
        return False
    try:
        subprocess.run(['convert', preview, '-resize', '%dx' % THUMB_WIDTH, '-quality', '82', '-strip', thumb],
                       check=True, capture_output=True)
        return True
    except (subprocess.CalledProcessError, OSError):
        return False


def tree_time():
    """When the template trees last changed, so the index only changes when they do."""
    try:
        out = subprocess.run(['git', 'log', '-1', '--format=%cI', '--'] + CATEGORIES,
                             check=True, capture_output=True, text=True).stdout.strip()
        return out or None
    except (subprocess.CalledProcessError, OSError):
        return None


def main():
    os.chdir(ROOT)
    thumbs_dir = os.path.join('catalog', 'thumbs')
    os.makedirs(thumbs_dir, exist_ok=True)
    templates = []
    warnings = []
    for category in CATEGORIES:
        if not os.path.isdir(category):
            continue
        for width in sorted(os.listdir(category)):
            if not width.isdigit() or not os.path.isdir(os.path.join(category, width)):
                continue
            for height in sorted(os.listdir(os.path.join(category, width))):
                folder = os.path.join(category, width, height)
                if not height.isdigit() or not os.path.isdir(folder):
                    continue
                for entry in sorted(os.listdir(folder)):
                    if not entry.lower().endswith('.zip'):
                        continue
                    path = os.path.join(folder, entry)
                    name = entry[:-4]
                    units, problems = units_of(path, name)
                    for p in problems:
                        warnings.append('%s: %s' % (path, p))
                    kinds = sorted({u['kind'] for u in units})
                    preview = os.path.join(folder, 'previews', name + '.png')
                    thumb = os.path.join(thumbs_dir, name + '.jpg')
                    has_preview = os.path.isfile(preview)
                    has_thumb = has_preview and thumbnail(preview, thumb)
                    templates.append({
                        'name': name,
                        'category': category,
                        'kind': '+'.join(kinds) if kinds else None,
                        'width': int(width),
                        'height': int(height),
                        'zip': path.replace(os.sep, '/'),
                        'bytes': os.path.getsize(path),
                        'sha256': sha256(path),
                        'units': units,
                        'preview': preview.replace(os.sep, '/') if has_preview else None,
                        'thumb': thumb.replace(os.sep, '/') if has_thumb else None,
                    })
    index = {
        'version': 1,
        'updated': tree_time(),
        'base': RAW,
        'templates': templates,
    }
    with open(os.path.join('catalog', 'index.json'), 'w') as f:
        json.dump(index, f, indent=1)
        f.write('\n')
    keep = {os.path.basename(t['thumb']) for t in templates if t['thumb']}
    for entry in os.listdir(thumbs_dir):
        if entry not in keep:
            os.remove(os.path.join(thumbs_dir, entry))
    print('catalog/index.json: %d templates, %d units, %d previews, %d thumbnails' % (
        len(templates), sum(len(t['units']) for t in templates),
        sum(1 for t in templates if t['preview']), sum(1 for t in templates if t['thumb'])))
    for w in warnings:
        print('warning:', w)
    return 0


if __name__ == '__main__':
    sys.exit(main())
