;; InstrumentHeritage: Musical Instrument Authentication and Registry Platform
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INSTRUMENT-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-CRAFTED-YEAR (err u5))
(define-constant ERR-INVALID-INSTRUMENT-TYPE (err u6))
(define-constant ERR-INVALID-PLAYABILITY (err u7))
(define-constant ERR-INVALID-INSTRUMENT-NAME (err u8))
(define-constant ERR-INVALID-CRAFTSMANSHIP (err u9))
(define-constant MIN-CRAFTED-YEAR u1600)
(define-data-var next-instrument-id uint u1)
(define-map musical-instruments
    uint
    {
        musician: principal,
        instrument-name: (string-utf8 50),
        craftsmanship: (string-utf8 200),
        instrument-type: (string-utf8 15),
        playability: (string-utf8 15),
        collection-status: (string-utf8 10),
        crafted-year: uint
    }
)
(define-private (validate-instrument-type (instrument-type (string-utf8 15)))
    (or 
        (is-eq instrument-type u"Violin")
        (is-eq instrument-type u"Piano")
        (is-eq instrument-type u"Guitar")
        (is-eq instrument-type u"Cello")
        (is-eq instrument-type u"Trumpet")
        (is-eq instrument-type u"Flute")
    )
)
(define-private (validate-playability (playability (string-utf8 15)))
    (or 
        (is-eq playability u"Concert")
        (is-eq playability u"Professional")
        (is-eq playability u"Playable")
        (is-eq playability u"Restoration")
        (is-eq playability u"Display Only")
    )
)
(define-private (validate-text-structure (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (register-instrument 
    (instrument-name (string-utf8 50))
    (craftsmanship (string-utf8 200))
    (instrument-type (string-utf8 15))
    (playability (string-utf8 15))
    (crafted-year uint)
)
    (let
        (
            (instrument-id (var-get next-instrument-id))
        )
        (asserts! (validate-text-structure instrument-name u3 u50) ERR-INVALID-INSTRUMENT-NAME)
        (asserts! (validate-text-structure craftsmanship u10 u200) ERR-INVALID-CRAFTSMANSHIP)
        (asserts! (>= crafted-year MIN-CRAFTED-YEAR) ERR-INVALID-CRAFTED-YEAR)
        (asserts! (validate-instrument-type instrument-type) ERR-INVALID-INSTRUMENT-TYPE)
        (asserts! (validate-playability playability) ERR-INVALID-PLAYABILITY)
        
        (map-set musical-instruments instrument-id {
            musician: tx-sender,
            instrument-name: instrument-name,
            craftsmanship: craftsmanship,
            instrument-type: instrument-type,
            playability: playability,
            collection-status: u"collected",
            crafted-year: crafted-year
        })
        (var-set next-instrument-id (+ instrument-id u1))
        (ok instrument-id)
    )
)
(define-public (donate-instrument (instrument-id uint))
    (let
        (
            (instrument (unwrap! (map-get? musical-instruments instrument-id) ERR-INSTRUMENT-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get musician instrument)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get collection-status instrument) u"collected") ERR-INVALID-STATUS)
        (ok (map-set musical-instruments instrument-id (merge instrument { collection-status: u"donated" })))
    )
)
(define-read-only (get-instrument (instrument-id uint))
    (ok (map-get? musical-instruments instrument-id))
)
(define-read-only (get-musician (instrument-id uint))
    (ok (get musician (unwrap! (map-get? musical-instruments instrument-id) ERR-INSTRUMENT-NOT-FOUND)))
)