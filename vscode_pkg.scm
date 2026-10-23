(define-module (vscode_pkg)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gtk)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (nonguix build-system chromium-binary)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gdb)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages file)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages video)
  #:use-module (gnu packages python)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages graphviz)
  #:use-module (nonguix multiarch-container)
)

;;ONLY USE IF YOU MUST THERE ARE A MILLION GOOD EDITORS AND THIS AIN'T ONE OF THEM GOD IS DEAD HERE


(define-public vscode-client
  (package
    (name "vscode-client")
    (version "1.141.2")
    (source
      (origin
        (method url-fetch)
        (uri
          (string-append 
            "https://update.code.visualstudio.com/" version "/linux-x64/stable"
          )
        )
        ;(file-name (string-append "vscode_v" version "_x64.tar.gz"))
        (sha256
          (base32
           "0v6ymyrh24lgrwsymw6c2l76n02avsyllfzmn1bnx4zyml1q44p4" 
          )
        )
      )
    )
    (build-system chromium-binary-build-system)
    (arguments
      (list 
        #:validate-runpath? #f ; TODO: fails on wrapped binary and included other files
        #:substitutable? #f
        #:wrapper-plan
          #~'(("lib/vscode/code" (("out" "/lib/vscode"))) "lib/vscode/chrome_crashpad_handler")
        #:phases
          #~(modify-phases %standard-phases
            (replace 'binary-unpack
              (lambda* (#:key source #:allow-other-keys)
                (mkdir-p "vscodedump")
                (invoke "tar" "-xvf" source "-C" "vscodedump")
                (mkdir-p "lib/vscode")
                (copy-recursively "vscodedump/VSCode-linux-x64/" "lib/vscode")
                (delete-file-recursively "vscodedump")
              )
            )
            ;(add-after 'binary-unpack 'setup
            ;  (lambda _
            ;    (mkdir-p "lib/vscode")
            ;    (invoke "ls")
            ;    (copy-recursively "vscodedump/VSCODE-linux-x64/" "lib/vscode")
            ;    (delete-file-recursively "vscodedump")
            ;  )
            ;)
            (add-after 'install 'symlink-binary-file
              (lambda _
                (let* ((bin (string-append #$output "/bin")))
                  (mkdir-p bin)
                  (symlink
                    (string-append #$output "/lib/vscode/code")
                    (string-append bin "/vscode")
                  )
                )
              ) 
            ) 
            (add-after 'install 'install-resources
              (lambda _
                (let*
                  (
                    (icons
                      (string-append #$output "/share/icons/hicolor/512x512/apps")
                    )
                    (icon.png
                      (string-append #$output "/share/icons/vscode.png")
                    )
                    (apps (string-append #$output "/share/applications"))
                  )

                  (mkdir-p icons)
                  (symlink icon.png
                     (string-append icons "/code.png")
                  )
                  (mkdir-p apps)
                  (make-desktop-entry-file
                    (string-append apps "/" #$name ".desktop")
                    #:name "VSCode"
                    #:generic-name "Text Editor"
                    #:exec (string-append #$output "/bin/vscode --ozone-platform-hint=auto")
                    #:icon "code"
                    #:type "Application"
                    #:actions '("new-empty-window")
                    #:keywords '("vscode")
                    #:categories '("TextEditor" "Development" "IDE")
                    #:startup-notify #t
                    #:startup-w-m-class "Code"
                    #:comment '(("en" "Code Editing. HAZARD.") (#f "Code Editing. HAZARD."))
                  )
                )
              )
            ) 
          )
       ); eend of list
    );end of args
                  
    (supported-systems '("x86_64-linux"))
    (native-inputs
      (list tar)
    )
    (inputs
      (list 
        gdk-pixbuf
      )
    )
    (home-page "https://code.visualstudio.com/")
    (synopsis "VSCode evil nasty microsoft editor probably gives you some kind of std when you use it")
    (description "VSCode if you don't know what it is you don't want it")
    (license expat)
  )
)

(define vscode-container-libs
 `(
   ("gtk", gtk+)
   ("egl", egl-wayland)
   ("glvnd", libglvnd)
   ("nss-certs", nss-certs)
   ("dbus-glib", dbus-glib)
   ("curl" ,curl)
   ("gcc" , gcc)
   ("bash", bash)
   ("coreutils", coreutils)
   ("file", file)
   ("libusb", libusb) ;;ADD USERPERMS dialout
   ("mesa", mesa)
   ("llvm", llvm-for-mesa)
   ("make", gnu-make)
   ("gdb", gdb)
   ;; UNIVERSITY LIBS
   ("python", python)
   ("git", git)
   ("doxygen", doxygen)
   ("tar", tar)
   ("graphviz", graphviz)
   ("libx11", libx11)
   ("libxinerama", libxinerama)
   ("libxi", libxi)
   ("libxcursor", libxcursor)
   ("libxrandr", libxrandr)
  )
)

(define-public (vscode-container path)
  (nonguix-container
    (name "vscode")
    (sandbox-home path)
    (wrap-package vscode-client)
    (run "/bin/vscode")
    (packages
      vscode-container-libs
    )
    (link-files '("share"))
    (description
      "vscode is a evil editor by the nasty microsoft"
    )
  )
)

(define-public vscode-packager
  (compose nonguix-container->package
    vscode-container
  )
)

(define-public vscode
  (vscode-packager "./local/share/guix-sandbox-home")
)



