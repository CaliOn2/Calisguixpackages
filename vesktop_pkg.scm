(define-module (vesktop_pkg)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module ((guix licenses))
  #:use-module (guix download)
  #:use-module (nonguix build-system chromium-binary)
  #:use-module (nonguix multiarch-container)
  #:use-module (guix gexp)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
)

(define vesktop-client-libs
  `(
    ("pulseaudio", pulseaudio)
    ("dbus-glib", dbus-glib)
  )
)


(define-public vesktop-client
  (package
    (name "vesktop-client")
    (version "1.6.5") ;Do not fuck with this
    (source
      (origin
        (method url-fetch)
	(uri
	  (string-append
	    "https://github.com/Vencord/Vesktop/releases/download/v" version "/vesktop_" version "_amd64.deb"
	  )
	)
	(file-name (string-append "vesktop_" version "_amd64.deb"))
	(sha256
	  (base32
	    "1x8wqdn6rdjdj6gbzqhzzs8za9hr5fqkrijr3mb061w1wjmrfk1d" ;Do not fuck with this
	  )
	)
      )
    )
    (build-system chromium-binary-build-system)
    (arguments
      (list
        #:validate-runpath? #f 
           #:wrapper-plan
           #~(map 
             (lambda (file)
               (string-append "lib/Vesktop/" file)   
             )
             '(
               "vesktop"
               "chrome-sandbox"
               "chrome_crashpad_handler"
               "libEGL.so"
               "libffmpeg.so"
               "libGLESv2.so"
               "libvk_swiftshader.so"
               "libvulkan.so.1"
             )
           )
           ;#~'(("lib/Vesktop/vesktop" (("out" "/lib/Vesktop"))) "lib/Vesktop/chrome_crashpad_handler" )
           #:phases
             #~(modify-phases %standard-phases
               (add-after 'binary-unpack 'setup-cwd
                 (lambda _
                   (copy-recursively "usr/" ".")
                   ;; Use the more standard lib directory for everything.
                   (rename-file "opt/" "lib")
                   ;; Remove unneeded files.
                   (delete-file-recursively "usr")
                 )
               )
               ;; Fix the .desktop file "Exec" line to just be "vesktop" in
               ;; order for this desktop file to be useful to launch vesktop in
               ;; the container (vesktop package) as well.
               (add-after 'patch-dot-desktop-files 'fix-desktop-file
                 (lambda _
                   (substitute*
                     (string-append #$output "/share/applications/vesktop.desktop")
                     (("Exec=.*/vesktop") "Exec=vesktop --disable-gpu-compositing")
                   )
                 )
               )
               (delete 'patch-dot-desktop-files)
               (add-after 'install 'symlink-binary-file
                 (lambda _
                   (mkdir-p (string-append #$output "/bin"))
                   (symlink 
                     (string-append #$output "/lib/Vesktop/vesktop")
                     (string-append #$output "/bin/vesktop")
                   )
                 )
              )
           )
        ;unphase
      )
    )
    (synopsis "Vesktop is a customizable and privacy friendly Discord desktop app!")
    (description
      "Vesktop is a custom Discord App aiming to give you better performance and improve linux support"
    )
    (home-page "https://vesktop.dev/")
    (license gpl3+)
    (supported-systems '("x86_64-linux"))
  )
)

(define-public (vesktop-container)
  (nonguix-container
    (name "vesktop")
    (wrap-package vesktop-client)
    (run "/bin/vesktop")
    (packages 
      vesktop-client-libs
    )
    (link-files '("share"))
    (description "Vesktop is a discord client. This package provides a script for launching vesktop in a Guix container
which will use the directory @file{$HOME/.local/share/guix-sandbox-home} whereall games will be installed."
    )
  )
)

(define-public vesktop-composer
  (compose nonguix-container->package vesktop-container)
)

(define-public vesktop
  (vesktop-composer)
)