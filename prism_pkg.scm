(define-module (prism_pkg)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix derivations)
  #:use-module (guix build-system cmake)
  #:use-module (guix licenses)
  #:use-module (guix gexp)
  #:use-module (nonguix multiarch-container)
  #:use-module (gnu packages)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages markup)
  #:use-module (gnu packages java)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages man)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages file)
  #:use-module (gnu packages video)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages freedesktop)
)

(define prism-container-libs
  `(
    ;("openjdk11" ,openjdk11)
    ;("openjdk16" ,openjdk16)
    ;("openjdk17" ,openjdk17)
    ;("openjdk21" ,openjdk21)
    ("openjdk25" ,openjdk25)
    ("at-spi2-core" ,at-spi2-core)      ; Required (often) for SteamVR interface.
    ("bash" ,bash)                      ; Required for steam startup.
    ("coreutils" ,coreutils)
    ("diffutils" ,diffutils)
    ("dbus-glib" ,dbus-glib)            ; Required for steam browser.
    ("glibc-locales", glibc-locales)
    ;("elfutils" ,elfutils)              ; Required for capturing library dependencies in pv.
    ("eudev" ,eudev)                    ; Required for steamwebhelper/heavy runtime.
    ("file" ,file)                      ; Used for steam installation.
    ("find" ,findutils)                 ; Required at least for some logging.

    ;; These next three fonts are to cover emoji and Chinese/Japanese/Korean
    ;; and related scripts.



    ;("freetype" ,freetype)              ; Required for steam login.
    ;("gawk" ,gawk)
    ;("grep" ,grep)
    ;("libbsd" ,libbsd)
    ;("libcap" ,libcap)                  ; Required for SteamVR, but needs pkexec too.
    ;("libusb" ,libusb)                  ; Required for SteamVR.
    ("libva" ,libva)                    ; Required for hardware video encoding/decoding.
    ("libvdpau" ,libvdpau)              ; Required for hardware video encoding/decoding.
    ("libvdpau-va-gl" ,libvdpau-va-gl)  ; Additional VDPAU support.
    ("llvm" ,llvm-for-mesa)             ; Required for mesa.
    ;("lsof" ,lsof)                      ; Required for some friend's list actions.
    ("mesa" ,mesa)                      ; Required for steam startup.
    ("nss-certs" ,nss-certs)            ; Required for steam login.
    ;("pciutils" ,pciutils)              ; Tries to run lspci at steam startup.
    ;("procps" ,procps)
    ;("sed" ,sed)
    ("tar" ,tar)
    ;("usbutils" ,usbutils)              ; Required for SteamVR.
    ("util-linux" ,util-linux)          ; Required for steam login.
    ("wayland" ,wayland)                ; Required for mesa vulkan (e.g. libvulkan_radeon).
    ("xdg-user-dirs" ,xdg-user-dirs)    ; Suppress warning of missing xdg-user-dir.
    ("xz" ,xz)
  )
)                ; Required for progress dialogs.



(define-public prism-client
  (package
    (name "prism-client")
    (version "11.0.3") ;Do not fuck with this
    (source
      (origin
        (method git-fetch)
	(uri
	  (git-reference
	    (url "https://github.com/PrismLauncher/PrismLauncher")
            (commit version)
            (recursive? #t)
	  )
	)
	(file-name (git-file-name name version))
	(sha256
	  (base32
	    "04dv4c849lghhqq25p58l5aq37r2kvx9297w1139x9ajab97xhhf" ;Do not fuck with this
	  )
	)
      )
    )
    (build-system cmake-build-system)
    (inputs
      ;(append
        (list 
          qtbase
          qtnetworkauth
          qtimageformats  
          qtsvg
          cmark
          libarchive
          mesa ; libgl? 
          qrencode ;might not exist?
          tomlplusplus
          zlib
          clang
          mesa-utils
          pciutils
          (list openjdk "jdk")
        )
        ;(specifications->packages '(
        ;  "openjdk:jdk"
        ;))  
      ;)
    )
    (arguments
      `(
        #:build-type "Release"
        #:phases ;%standard-phases 
          (modify-phases %standard-phases
            (add-before 'configure 'patch-java-flagsnconfig
              (lambda _
                (map
                  (lambda path
                    (substitute* (string-append (car path) "/CMakeLists.txt")
                      (
                        ("-target 7 -source 7")
                        "--release 11"
                      )
                    )
                  )
                  (list
                    "libraries/launcher"
                    "libraries/javacheck"
                  )
                )
              )
            )

            (add-before 'configure 'remWerr
              (lambda _
                (substitute* "launcher/CMakeLists.txt"
                  (
                    ("-Werror")
                    ""
                  )
                )
              )
            )
          )          
        ;end phases
      )
    )
    (native-inputs
      (list
        gamemode
        scdoc
        pkg-config
        mesa-headers
        vulkan-headers
        extra-cmake-modules
      )
    )
    (synopsis "Prism is a minecraft launcher with modpack support")
    (description
      "A custom launcher for Minecraft that allows you to easily manage multiple installations of Minecraft at once (Fork of MultiMC)"
    )
    (home-page "https://prismlauncher.org/")
    (license gpl3+)
    (supported-systems '("x86_64-linux"))
  )
)

(define-public (prism-container-for driver)
  (nonguix-container
    (name "prism")
    (wrap-package prism-client)
    (run "/bin/prismlauncher")
    (packages
      (modify-inputs prism-container-libs
        (replace "mesa" driver)
      )
    )
     (union32
    (fhs-union (modify-inputs prism-container-libs
                 (replace "mesa" driver)
                 ;; The first java found will be used and it needs to be
                 ;; 64-bit.
                 ;; TODO: Change order in manifest, or set PATH, but prism
                 ;; needs a 32-bit ldd (found first?).
                 (delete "openjdk25"))
               #:name "fhs-union-32"
               #:system "i686-linux"))
    (link-files '("share"))
    (description
       "Prism is a minecraft mod platform.This package provides a script for launching prism in a Guix container
which will use the directory @file{$HOME/.local/share/guix-sandbox-home} where
all games will be installed."
    )
  )
)

(define-public prism-for
  (compose nonguix-container->package prism-container-for)
)

(define-public prism 
  (prism-for mesa)
)