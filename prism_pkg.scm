(define-module (prism_pkg)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix derivations)
  #:use-module (guix build utils)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system ant)
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
  #:use-module (gnu packages base)
  #:use-module (gnu packages video)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages speech)
  #:use-module (mcmods_pkg)
)

(define prism-container-libs
  `(
    ("at-spi2-core" ,at-spi2-core)      ; Needed for proper mouse input capture

    ;("openjdk11" ,openjdk11)
    ;("openjdk16" ,openjdk16)
    ;("openjdk17" ,openjdk17)
    ;("openjdk21" ,openjdk21)
    ("openjdk25" ,openjdk25)

    ("glibc-locales", glibc-locales)    ;supress warning of missing locales
    
    ("alsa-lib" ,alsa-lib)  ;audio stuff might not need everything
    ("alsa-plugins:pulseaudio" , alsa-plugins "pulseaudio")
    ("openal" ,openal) 
    ("pulseaudio" ,pulseaudio)
    ("flite" ,flite)  ; needed for speech systhesis        
 
    ("font-google-noto" ,font-google-noto) ; needed for languages
    ("font-google-noto-emoji" ,font-google-noto-emoji)
    ("font-google-noto-sans-cjk" ,font-google-noto-sans-cjk)
    ("font-google-noto-serif-cjk" ,font-google-noto-serif-cjk)
    
    ;("libusb" ,libusb)                  ; controller support maybe?
    ;("usbutils", usbutils)
    
    ("libva" ,libva)                    ; Required for hardware video encoding/decoding.
    ("libvdpau" ,libvdpau)              ; Required for hardware video encoding/decoding.
    ("libvdpau-va-gl" ,libvdpau-va-gl)  ; Additional VDPAU support.
    ("llvm" ,llvm-for-mesa)             ; Required for mesa.
    ("mesa" ,mesa)                      ; Required for graphics stuff
    ("nss-certs" ,nss-certs)            ; Required for accounts and such
    ("wayland" ,wayland)                ; Needed for mesa vulcan
    ("pciutils", pciutils)              ; runs lspci at start of minecraft launch
    ("xdg-user-dirs" ,xdg-user-dirs)    ; Suppress warning of missing xdg-user-dir.
    
    ;; TODO: still missing some icons and cursor isn't hidden when running minecraft, error logs also show a render error
    ;;       missing x11 cursor, this doesn't impair functionality so fix it yourself if it annoys you, 
    ;;       the program is launched in a container with wayland as it's QT_QPA_PLATFORM environment variable which should be xcb
    ;;       additionally one would probably need some form of xwayland this probably isn't an issue on x11, hasn't been tested yet though
  )
)


(define-public prism-client
  (package
    (name "prism-client")
    (version "11.0.3")
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
	    "04dv4c849lghhqq25p58l5aq37r2kvx9297w1139x9ajab97xhhf"
	  )
	)
      )
    )
    (build-system cmake-build-system)
    (inputs
      (list 
        qtbase
        qtnetworkauth
        qtimageformats  
        qtsvg
        cmark
        libarchive
        mesa 
        qrencode 
        tomlplusplus
        zlib
        clang
        mesa-utils
        pciutils
        (list openjdk "jdk")
      )
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
            
            (add-after 'patch-dot-desktop-files 'patch-desktop-file-prism
              (lambda _
                (let ((path (string-append (assoc-ref %outputs "out") "/share/applications/")))
                  (substitute* (string-append path "org.prismlauncher.PrismLauncher.desktop")
                    (
                      ("Exec=.*/prismlauncher") 
                      "Exec=prism"
                    )
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

(define-public prism-cracked-client
  (package
    (inherit prism-client)
    (name "prism-cracked-client")
    (version "11.0.3")
    (source
      (origin
        (method git-fetch)
        (uri
          (git-reference
            (url "https://github.com/Diegiwg/PrismLauncher-Cracked")
            (commit version)
            (recursive? #t)
          )
        )
        (file-name (git-file-name name version))
        (sha256
          (base32
            "1v00ff5w94l6zi22p3kp4cjcijm0ws8s5v3di2c41lv3f9cyfwaw"
          )
        )
      )
    )
    (arguments
      (substitute-keyword-arguments arguments
        (
          (#:phases prism-phases)
          #~(modify-phases #$prism-phases
            (delete 'patch-desktop-file-prism)
            (add-after 'patch-dot-desktop-files 'patch-desktop-file-prism-cracked
              (lambda _
                (let ((path (string-append (assoc-ref %outputs "out") "/share/applications/")))
                  (substitute* (string-append path "org.prismlauncher.PrismLauncher.desktop")
                    (
                      ("Exec=.*/prismlauncher")  
                      "Exec=prism-cracked"
                    )
                  )
                  (rename-file (string-append path "org.prismlauncher.PrismLauncher.desktop") (string-append path "org.prismlaunchercracked.PrismLauncherCracked.desktop"))
                )
              )
            )
          )
        )
      )
    )
    (synopsis "cracked version of Prism, so you don't need an mc account")
    (home-page "https://github.com/Diegiwg/PrismLauncher-Cracked")
  )
)


(define-public (prism-container-for package-name driver launcher game-mods path)
  (nonguix-container
    (name package-name)
    (sandbox-home path)
    (wrap-package launcher)
    (run "/bin/prismlauncher")
    (packages
      (modify-inputs prism-container-libs
        (replace "mesa" driver)
      )
    )
    (union32
      (fhs-union
        (append 
          (modify-inputs prism-container-libs
            ;; The first java found will be used and it needs to be
            ;; 64-bit.
            ;; TODO: Find a better solution, this solution was taken from nonguix game-clients
            ;;       They have the same goal so waiting till they solve it should be fine
            (delete "openjdk25")

            (replace "mesa" driver)
          )
          game-mods
        )
        #:name "fhs-union-32"
        #:system "i686-linux"
      )
    )
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

(define-public (prism-driverless-pathless driver path)
  (prism-for "prism" driver prism-client `() path)
)


(define-public (prism-cracked-driverless-pathless driver path)
  (prism-for "prism-cracked" driver prism-cracked-client `(("anarchymod" ,anarchymod)) path)
)

(define-public prism
  (prism-driverless-pathless mesa ".local/share/guix-sandbox-home")
)

(define-public prism-cracked
  (prism-cracked-driverless-pathless mesa ".local/share/guix-sandbox-home")
)
