# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for mgg-packify-api
# Usage: pyinstaller mgg-packify-api.spec  (run from api/ directory)

from PyInstaller.utils.hooks import collect_all

block_cipher = None

# Collect the entire mgg_packify_api package (source + data)
pkg_datas, pkg_binaries, pkg_hiddenimports = collect_all('mgg_packify_api')

# Collect uvicorn fully
uv_datas, uv_binaries, uv_hiddenimports = collect_all('uvicorn')

a = Analysis(
    ['src/mgg_packify_api/main.py'],
    pathex=['src'],
    binaries=pkg_binaries + uv_binaries,
    datas=pkg_datas + uv_datas,
    hiddenimports=pkg_hiddenimports + uv_hiddenimports + [
        'anyio',
        'anyio._backends._asyncio',
        'platformdirs',
        'docx',
        'docx.oxml',
        'docx.oxml.ns',
        'h11',
        'httptools',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='mgg-packify-api',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)
