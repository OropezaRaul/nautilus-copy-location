# nautilus-copy-location

> ## ⚠️ Aviso de autoría — este NO es un proyecto original
>
> Este repositorio es el **código fuente completo de [GNOME Nautilus](https://gitlab.gnome.org/GNOME/nautilus)**
> (la app "Files", versión 50.3.1, licencia GPL-3.0-or-later) con **una única
> corrección** de mi parte: la entrada **"Copy Location"** ahora copia la ruta
> como texto plano. Considero que el comportamiento original era un error, pero
> **todo el crédito del programa es de la comunidad GNOME**: yo solo aporté ese
> cambio puntual y esta documentación.

GNOME Files (Nautilus) **50.3.1** con un arreglo a la entrada **"Copy Location"**
del menú contextual de la barra de ruta: ahora copia la ruta como **texto plano**,
en vez de poner en el portapapeles una transferencia de archivos.

Este repositorio contiene **el código completo del programa con el fix aplicado**,
los archivos para recompilarlo (PKGBUILD de Arch), el hook que lo reaplica en el
flujo de Omarchy y toda la documentación del problema.

## El problema

En Nautilus 50.x, la acción `view.copy-current-location` ("Copy Location" en el
menú contextual de la barra de ruta) NO copia texto. Su implementación
(`action_copy_current_location` en `src/nautilus-files-view.c`) llama a
`nautilus_clipboard_prepare_for_files()` — el **mismo portapapeles de
transferencia de archivos que Ctrl+C** — con la carpeta actual como único
archivo (`x-special/gnome-copied-files`, `text/uri-list` y
`application/vnd.portal.filetransfer`).

Al pegar ese portapapeles en un navegador basado en Chromium (caso real: el
cliente web DeepSeek Harness), el navegador materializa la transferencia como
objetos `File` y la aplicación los trata como archivos adjuntos. Si lo copiado
no es una imagen PNG/JPG/WebP/GIF, se obtiene el error:

> **Only PNG, JPG, WebP, and GIF images are supported**

Lo mismo pasa en apps de mensajería (Discord, Signal, Fractal…): pegar un
archivo copiado de Files inicia una subida de archivo en vez de insertar la ruta.
En cambio, seleccionar la ruta a mano en la barra de ubicación (Ctrl+L) copia
texto plano y funciona en todas partes.

## El fix

`action_copy_current_location` ahora copia la ubicación como texto plano con
`gdk_clipboard_set_text()`:

- Rutas locales → ruta absoluta (`g_file_get_path`), p. ej.
  `/home/user/Projects/foo` — idéntico a copiar desde la barra de ubicación.
- Ubicaciones remotas/GVFS (sin ruta local) → URI (`g_file_get_uri`), p. ej.
  `smb://server/share`.

Copiar archivos y carpetas con **Ctrl+C / Cortar sigue igual** (se conserva la
transferencia de archivos para pegar dentro de Files con Ctrl+V).

Diff exacto en [`nautilus-copy-location-text.patch`](nautilus-copy-location-text.patch):

```diff
--- a/src/nautilus-files-view.c
+++ b/src/nautilus-files-view.c
@@ -5852,18 +5852,24 @@
                               gpointer       user_data)
 {
     NautilusFilesView *self = user_data;
+    GFile *location;
+    g_autofree char *text = NULL;
     GdkClipboard *clipboard;
-    GList *files;

-    if (self->directory_as_file != NULL)
+    location = nautilus_files_view_get_location (self);
+    if (location == NULL)
     {
-        files = g_list_append (NULL, nautilus_file_ref (self->directory_as_file));
-
-        clipboard = gtk_widget_get_clipboard (GTK_WIDGET (self));
-        nautilus_clipboard_prepare_for_files (clipboard, files, FALSE);
+        return;
+    }

-        nautilus_file_list_free (files);
+    text = g_file_get_path (location);
+    if (text == NULL)
+    {
+        text = g_file_get_uri (location);
     }
+
+    clipboard = gtk_widget_get_clipboard (GTK_WIDGET (self));
+    gdk_clipboard_set_text (clipboard, text);
 }
```

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `src/nautilus-50.3.1/` | Código fuente íntegro de Nautilus **50.3.1** (tag upstream) **con el fix aplicado** |
| `nautilus-copy-location-text.patch` | El parche del fix (diff unificado) |
| `nautilus-copy-location.upstream.patch` | El commit en formato `git format-patch` (para MR a upstream) |
| `mr-description.md` | Descripción lista para un merge request de GNOME |
| `nautilus-50.3.1.tar.xz` | Source tag 50.3.1 upstream — lo usa el PKGBUILD, sin red |
| `PKGBUILD` | Empaquetado Arch (basado en el oficial + `prepare()` que aplica el parche) |
| `install.sh` | Recompila, instala y protege del repositorio (`IgnorePkg`) |
| `keep-nautilus-copy-location.hook` | Hook `post-update.d` para el flujo de Omarchy |

## Compilar e instalar (Arch / Omarchy)

```bash
./install.sh
pkill nautilus   # o reiniciar Files
```

`install.sh` hace: `makepkg --nocheck --cleanbuild --force` (fuentes locales, sin red),
`sudo pacman -U` de `nautilus`, `libnautilus-extension` y
`libnautilus-extension-docs`, y asegura en `/etc/pacman.conf` (bajo `[options]`):

```ini
[options]
...
IgnorePkg = nautilus libnautilus-extension libnautilus-extension-docs
```

### Dependencias de build

```bash
sudo pacman -S --needed base-devel meson ninja appstream blueprint-compiler \
  glib2-devel gobject-introspection gi-docgen python-gobject
```

## Integración con el flujo de modificaciones de Omarchy

Con `omarchy hook install post-update keep-nautilus-copy-location.hook` el
arreglo queda registrado como modificación del sistema: antes de cada
`omarchy update` hay snapshot de snapper (respaldo) y el hook corre tras los
paquetes/migraciones (reaplicación). Si el `/usr/bin/nautilus` instalado no es
byte-idéntico a este build, recompila desde estas fuentes y reinstala; fast path
cuando ya está parcheado (comparación `bsdtar -xOf <pkg> | cmp - /usr/bin/nautilus`).

## Estado del intento de contribución a upstream

El fix está preparado como commit para el repo oficial
(`gitlab.gnome.org/GNOME/nautilus`, público y abierto a merge requests): rama
`copy-location-plain-text`, mensaje `view: Make Copy Location put the plain
path on the clipboard`, contra `main` (`301d1849`). No se publicó porque una
cuenta recién creada en gitlab.gnome.org no puede hacer fork (usuario externo,
`projects_limit 0` → `409 Limit reached`), requisito previo de cualquier MR.
Contexto: el MR cerrado !1987 proponía un item opcional "Copy Path" por el mismo
dolor; este arreglo es más acotado (cambia la entrada existente).

Para publicar cuando se tenga acceso:

```bash
# desde este repo: generar la rama del MR sobre main de nautilus
git clone --depth 1 --branch main https://gitlab.gnome.org/GNOME/nautilus.git /tmp/nautilus-mr
cd /tmp/nautilus-mr
git apply /path/to/nautilus-copy-location.upstream.patch
git checkout -b copy-location-plain-text
git commit -m "view: Make Copy Location put the plain path on the clipboard"
git push -u origin copy-location-plain-text
# abrir el enlace de creación de MR que GitLab imprime tras el push
```

## Verificación

- Reproducido en Nautilus 50.2.2 y 50.3.1 y en `main` upstream: ambos usan
  `nautilus_clipboard_prepare_for_files`.
- El manejador de pegado del cliente web DSH eleva `UnsupportedImageMediaTypeError`
  cuando un `File` pegado no es PNG/JPG/WebP/GIF → mensaje `image.unsupportedType`.
- Build local compilado (`makepkg`), instalado y en uso diario en Omarchy; el
  binario instalado es byte-idéntico al del paquete (verificado con `cmp`).

## Licencia

El código fuente incluido es de GNOME Nautilus (GPL-3.0-or-later, ver
`src/nautilus-50.3.1/LICENSE` y `src/nautilus-50.3.1/LICENSES/`).
