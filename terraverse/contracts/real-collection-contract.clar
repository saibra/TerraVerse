;; Digital Real Estate Marketplace - Virtual Property Trading
;; SIP-009 compliant property marketplace with location-based pricing

;; Define the property deed token
(define-non-fungible-token property-deed uint)

;; Contract constants
(define-constant city-mayor tx-sender)
(define-constant err-mayor-only (err u300))
(define-constant err-not-property-owner (err u301))
(define-constant err-insufficient-funds (err u302))
(define-constant err-listing-not-found (err u303))
(define-constant err-property-not-found (err u304))
(define-constant err-invalid-price (err u305))
(define-constant err-development-failed (err u306))

;; Data variables
(define-data-var last-property-id uint u0)
(define-data-var city-registry (string-utf8 256) u"")

;; Property types
(define-constant RESIDENTIAL u1)
(define-constant COMMERCIAL u2)
(define-constant INDUSTRIAL u3)
(define-constant LUXURY u4)
(define-constant LANDMARK u5)

;; Data maps
(define-map property-details uint {
  address: (string-utf8 64),
  blueprint: (string-utf8 256),
  virtual-tour: (string-utf8 256),
  developer: principal,
  zone-type: uint,
  square-footage: uint
})

(define-map real-estate-listings uint {
  landlord: principal,
  asking-price: uint,
  available: bool
})

(define-map development-commission uint {
  developer: principal,
  commission-rate: uint
})

;; Get property URI (SIP-009 requirement)
(define-read-only (get-token-uri (property-id uint))
  (ok (some (var-get city-registry)))
)

;; Get last property ID (SIP-009 requirement)
(define-read-only (get-last-token-id)
  (ok (var-get last-property-id))
)

;; Get property owner (SIP-009 requirement)
(define-read-only (get-owner (property-id uint))
  (ok (nft-get-owner? property-deed property-id))
)

;; Transfer function (SIP-009 requirement)
(define-public (transfer (property-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-property-owner)
    (nft-transfer? property-deed property-id sender recipient)
  )
)

;; Develop new property (mayor only)
(define-public (develop-property (new-owner principal) (address (string-utf8 64)) (blueprint (string-utf8 256)) (virtual-tour (string-utf8 256)) (zone-type uint) (square-footage uint))
  (let ((new-property-id (+ (var-get last-property-id) u1)))
    (asserts! (is-eq tx-sender city-mayor) err-mayor-only)
    (asserts! (<= zone-type LANDMARK) err-invalid-price)
    (asserts! (>= zone-type RESIDENTIAL) err-invalid-price)
    (asserts! (> square-footage u0) err-invalid-price)
    (try! (nft-mint? property-deed new-property-id new-owner))
    (map-set property-details new-property-id {
      address: address,
      blueprint: blueprint,
      virtual-tour: virtual-tour,
      developer: tx-sender,
      zone-type: zone-type,
      square-footage: square-footage
    })
    (map-set development-commission new-property-id {
      developer: tx-sender,
      commission-rate: (get-commission-rate zone-type)
    })
    (var-set last-property-id new-property-id)
    (ok new-property-id)
  )
)

;; Calculate commission rate based on zone type
(define-private (get-commission-rate (zone-type uint))
  (if (is-eq zone-type LANDMARK) u15
    (if (is-eq zone-type LUXURY) u12
      (if (is-eq zone-type COMMERCIAL) u8
        (if (is-eq zone-type INDUSTRIAL) u6
          u4))))
)

;; Get property details
(define-read-only (get-property-details (property-id uint))
  (map-get? property-details property-id)
)

;; List property for sale
(define-public (list-property (property-id uint) (asking-price uint))
  (let ((property-owner (unwrap! (nft-get-owner? property-deed property-id) err-property-not-found)))
    (asserts! (is-eq tx-sender property-owner) err-not-property-owner)
    (asserts! (> asking-price u0) err-invalid-price)
    (try! (nft-transfer? property-deed property-id tx-sender (as-contract tx-sender)))
    (map-set real-estate-listings property-id {
      landlord: tx-sender,
      asking-price: asking-price,
      available: true
    })
    (ok true)
  )
)

;; Purchase property
(define-public (purchase-property (property-id uint))
  (let ((listing (unwrap! (map-get? real-estate-listings property-id) err-listing-not-found)))
    (asserts! (get available listing) err-listing-not-found)
    (asserts! (>= (stx-get-balance tx-sender) (get asking-price listing)) err-insufficient-funds)
    
    ;; Calculate development commission
    (let ((commission-info (unwrap! (map-get? development-commission property-id) err-property-not-found))
          (sale-price (get asking-price listing))
          (commission-amount (/ (* sale-price (get commission-rate commission-info)) u100))
          (landlord-payment (- sale-price commission-amount)))
      
      ;; Transfer payment to landlord
      (try! (stx-transfer? landlord-payment tx-sender (get landlord listing)))
      
      ;; Transfer commission to developer
      (try! (stx-transfer? commission-amount tx-sender (get developer commission-info)))
      
      ;; Transfer property deed to buyer
      (try! (nft-transfer? property-deed property-id (as-contract tx-sender) tx-sender))
      
      ;; Remove listing
      (map-delete real-estate-listings property-id)
      (ok true)
    )
  )
)

;; Remove property from market
(define-public (remove-listing (property-id uint))
  (let ((listing (unwrap! (map-get? real-estate-listings property-id) err-listing-not-found)))
    (asserts! (is-eq tx-sender (get landlord listing)) err-not-property-owner)
    (asserts! (get available listing) err-listing-not-found)
    (try! (nft-transfer? property-deed property-id (as-contract tx-sender) tx-sender))
    (map-delete real-estate-listings property-id)
    (ok true)
  )
)

;; Get listing information
(define-read-only (get-listing-info (property-id uint))
  (map-get? real-estate-listings property-id)
)

;; Get comprehensive property info
(define-read-only (get-property-market-data (property-id uint))
  (let ((listing (map-get? real-estate-listings property-id))
        (details (map-get? property-details property-id)))
    {
      listing: listing,
      details: details
    }
  )
)

;; Update city registry URI (mayor only)
(define-public (update-city-registry (new-registry (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender city-mayor) err-mayor-only)
    (var-set city-registry new-registry)
    (ok true)
  )
)

;; Get city registry URI
(define-read-only (get-city-registry)
  (var-get city-registry)
)

;; Emergency property reclaim (mayor only)
(define-public (emergency-reclaim (property-id uint))
  (begin
    (asserts! (is-eq tx-sender city-mayor) err-mayor-only)
    (nft-transfer? property-deed property-id (as-contract tx-sender) tx-sender)
  )
)

;; Batch property development
(define-public (batch-develop (owners (list 10 principal)) (addresses (list 10 (string-utf8 64))) (blueprints (list 10 (string-utf8 256))) (tours (list 10 (string-utf8 256))) (zones (list 10 uint)) (footages (list 10 uint)))
  (begin
    (asserts! (is-eq tx-sender city-mayor) err-mayor-only)
    (asserts! (is-eq (len owners) (len addresses)) err-invalid-price)
    (asserts! (is-eq (len addresses) (len blueprints)) err-invalid-price)
    (asserts! (is-eq (len blueprints) (len tours)) err-invalid-price)
    (asserts! (is-eq (len tours) (len zones)) err-invalid-price)
    (asserts! (is-eq (len zones) (len footages)) err-invalid-price)
    (ok (map batch-develop-helper owners addresses blueprints tours zones footages))
  )
)

(define-private (batch-develop-helper (owner principal) (address (string-utf8 64)) (blueprint (string-utf8 256)) (tour (string-utf8 256)) (zone uint) (footage uint))
  (develop-property owner address blueprint tour zone footage)
)

;; Utility functions
(define-read-only (get-total-properties)
  (var-get last-property-id)
)

(define-read-only (get-properties-by-owner (owner principal))
  (let ((total-properties (var-get last-property-id)))
    (fold check-property-ownership (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) (list))
  )
)

(define-private (check-property-ownership (property-id uint) (owned-list (list 10 uint)))
  (if (is-eq (nft-get-owner? property-deed property-id) (some tx-sender))
    (unwrap! (as-max-len? (append owned-list property-id) u10) owned-list)
    owned-list
  )
)

;; Get properties by zone type
(define-read-only (get-zone-count (zone-type uint))
  (let ((total-properties (var-get last-property-id)))
    (fold count-zone-properties (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) {target: zone-type, count: u0})
  )
)

(define-private (count-zone-properties (property-id uint) (acc {target: uint, count: uint}))
  (let ((details (map-get? property-details property-id)))
    (match details
      property-data 
        (if (is-eq (get zone-type property-data) (get target acc))
          {target: (get target acc), count: (+ (get count acc) u1)}
          acc)
      acc
    )
  )
)

;; Calculate property value based on zone and footage
(define-read-only (estimate-property-value (property-id uint))
  (match (map-get? property-details property-id)
    details 
      (let ((base-rate (get-zone-base-rate (get zone-type details)))
            (footage (get square-footage details)))
        (ok (* base-rate footage)))
    (err err-property-not-found)
  )
)

(define-private (get-zone-base-rate (zone-type uint))
  (if (is-eq zone-type LANDMARK) u1000
    (if (is-eq zone-type LUXURY) u500
      (if (is-eq zone-type COMMERCIAL) u200
        (if (is-eq zone-type INDUSTRIAL) u100
          u50))))
)