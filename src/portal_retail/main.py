"""
Punto de entrada de Portal Retail v2.

Ejecutar con:
    python -m portal_retail
    portal-retail   (si está instalado con pip install -e .)
"""

from __future__ import annotations

_BANNER = r"""
  _ _ _  __ _  __ _   _ __   __ _  ___| | ______ ___ _ __
 | ' ' |/ _` |/ _` | | '_ \ / _` |/ __| |/ / _` / _ \ '_ \
 | | | | (_| | (_| | | |_) | (_| | (__|   < (_| |  __/ | | |
 |_|_|_|\__, |\__, | | .__/ \__,_|\___|_|\_\__, |\___|_| |_|
        |___/ |___/ |_|                    |___/
                mgg-packgen v2  —  Portal Retail  —  Skandia México
"""


def main() -> None:
    """
    Función principal: lanza la TUI de mgg-packgen.

    Imprime el banner ASCII, luego arranca PortalRetailApp.
    Maneja KeyboardInterrupt limpiamente.
    """
    print(_BANNER)

    try:
        from portal_retail.tui.app import PortalRetailApp
        app = PortalRetailApp()
        app.run()
    except KeyboardInterrupt:
        print("\nmgg-packgen cerrado. ¡Hasta luego!")
    except Exception as exc:  # noqa: BLE001
        print(f"\nError inesperado al iniciar mgg-packgen: {exc}")
        raise


if __name__ == "__main__":
    main()
