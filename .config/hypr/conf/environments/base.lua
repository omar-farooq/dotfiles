---@module 'hl'

-- -----------------------------------------------------
-- Environment Variables -- name: "Base"
-- -----------------------------------------------------
--
-- The always-on half of the environment. These came out of ml4w.conf, which is
-- what the "Default Settings in ml4w.conf" line in default.lua / nvidia.lua /
-- kvm.lua was pointing at -- upstream kept the shared variables in ml4w.conf
-- and left this directory for the hardware-specific overlay only.
--
-- That split is why this file exists rather than the contents being folded into
-- environments/default.lua: default, nvidia and kvm are ALTERNATIVES, one of
-- which conf/environment.lua picks. Putting XDG/QT/GDK in default.lua would
-- silently drop every one of them the day this machine switches to nvidia.lua.
-- conf/environment.lua requires this file first, then the chosen overlay.

-- -----------------------------------------------------
-- XDG Desktop Portal
-- -----------------------------------------------------

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- -----------------------------------------------------
-- QT
-- -----------------------------------------------------

-- Wayland where the toolkit can, xcb as the fallback for Qt apps built without
-- Wayland support.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- qt6ct, NOT qt5ct. ml4w.conf set this twice -- qt6ct and then qt5ct on the
-- next line, so qt5ct silently won -- which meant Qt apps were asking for a
-- platform theme that is not installed on this machine and falling back to
-- unstyled defaults. Only qt6ct is installed, and .config/qt6ct is tracked in
-- this repo (Breeze, breeze-dark icons, Noto Sans 11), so it is the one that
-- should win. If a Qt5 app ever needs theming, install qt5ct and set
-- QT_QPA_PLATFORMTHEME per-app rather than globally -- one global value cannot
-- serve both generations.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", 1)
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", 1)

-- -----------------------------------------------------
-- GDK / GTK
-- -----------------------------------------------------

hl.env("GDK_SCALE", 1)
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- -----------------------------------------------------
-- Mozilla
-- -----------------------------------------------------

hl.env("MOZ_ENABLE_WAYLAND", 1)

-- -----------------------------------------------------
-- Cursor
-- -----------------------------------------------------

-- For XWayland and toolkits that read the X cursor size. Native Wayland clients
-- get theirs from conf/cursor.lua's `hyprctl setcursor Bibata-Modern-Ice 24` --
-- the 24 here has to match the 24 there or the cursor changes size as the
-- pointer crosses from an XWayland window into a Wayland one.
hl.env("XCURSOR_SIZE", 24)

-- -----------------------------------------------------
-- Chromium / Electron
-- -----------------------------------------------------

hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- Dropped with ml4w: APPIMAGELAUNCHER_DISABLE=1. It existed to stop
-- appimagelauncher intercepting the ML4W Welcome and Dotfiles Settings
-- AppImages, both of which are deleted; appimagelauncher is not installed here
-- either, so the variable had nothing left to disable.
