(define-module (mcmods_pkg)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build utils)
  #:use-module (guix build-system copy)
  #:use-module (guix licenses)
  #:use-module (guix gexp)
)

(define-public (anarchymod-builder mcversion)
  (package
    (name "anarchymod")
    (version "1.3.2")
    (source
      (origin
        (method url-fetch)
        (uri 
          (string-append "https://github.com/6b6t/AnarchyMod/releases/download/" version "/anarchymod-mc-" mcversion "-" version ".jar")
        )
        (sha256
          (base32
            "00fy1cs1nk85mzqrchklx3hx4rkljj8day3svcgwgq3j434zkl60"
          )
        )
      )
    )
    (build-system copy-build-system)
    (arguments
      (list
        #:phases 
          #~(modify-phases %standard-phases
            (add-after 'install 'move-files
              (lambda _
                (let 
                  (
                    (path (string-append (assoc-ref %outputs "out")))
                  )
                  ;; HORRIBLE SOLUTION REQUIRES LOOKING IN LIB FIX AT SOME POINT
                  (mkdir-p (string-append path "/lib/minecraft"))
                  (copy-recursively "." (string-append path "/lib/minecraft"))                 
                )
              )
            )
            (delete 'install)
          )
        ;; END PHASES
      )
    )
    (home-page "https://6b6t.org")
    (license gpl3+)
    (synopsis "A Minecraft Fabric Utility Mod to access blacklisted servers")
    (description "A Minecraft Mod to access blacklisted servers")
  )  
)

(define-public anarchymod
  (let ((version "26.2"))
    (package
      (inherit (anarchymod-builder version))
      (name (string-append "anarchymod-" version))
    )
  )
)