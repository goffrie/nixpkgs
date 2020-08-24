# TODO: Resolve the issues with the Mono bindings.

{ stdenv, fetchbzr, fetchpatch, lib
, pkgconfig, autoreconfHook
, glib, dbus-glib, gtkVersion ? "3"
, gtk2 ? null, libindicator-gtk2 ? null, libdbusmenu-gtk2 ? null
, gtk3 ? null, libindicator-gtk3 ? null, libdbusmenu-gtk3 ? null
, vala, gobject-introspection
, monoSupport ? false, mono ? null, gtk-sharp-2_0 ? null
 }:

with lib;


stdenv.mkDerivation rec {
  name = let postfix = if gtkVersion == "2" && monoSupport then "sharp" else "gtk${gtkVersion}";
          in "libappindicator-${postfix}-${version}";
  version = "unstable-2020-07-06";

  outputs = [ "out" "dev" ];

  src = fetchbzr {
    url = "lp:libappindicator";
    rev = "298";
    sha256 = "0v5nkfzid0faa1k71mlm8jqaljfj2ly6d0qidb1ja79d4zmnbnb0";
  };

  nativeBuildInputs = [ pkgconfig autoreconfHook vala gobject-introspection ];

  propagatedBuildInputs =
    if gtkVersion == "2"
    then [ gtk2 libdbusmenu-gtk2 ]
    else [ gtk3 libdbusmenu-gtk3 ];

  buildInputs = [
    glib dbus-glib
  ] ++ (if gtkVersion == "2"
    then [ libindicator-gtk2 ] ++ optionals monoSupport [ mono gtk-sharp-2_0 ]
    else [ libindicator-gtk3 ]);

  configureFlags = [
    "CFLAGS=-Wno-error"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-gtk=${gtkVersion}"
  ];

  doCheck = false; # generates shebangs in check phase, too lazy to fix

  installFlags = [
    "sysconfdir=${placeholder "out"}/etc"
    "localstatedir=\${TMPDIR}"
  ];

  meta = {
    description = "A library to allow applications to export a menu into the Unity Menu bar";
    homepage = "";
    license = with licenses; [ lgpl21 lgpl3 ];
    platforms = platforms.linux;
    maintainers = [ maintainers.msteen ];
  };
}
