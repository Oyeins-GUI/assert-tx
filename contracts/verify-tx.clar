(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-not-found (err u102))
(define-constant err-unsupported-tx (err u103))
(define-constant err-out-not-found (err u104))
(define-constant err-in-not-found (err u105))
(define-constant err-tx-not-mined (err u106))

(define-non-fungible-token bitbadge uint)

(define-data-var last-token-id uint u0)

(define-read-only (get-last-token-id)
   (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
   (ok none)
)

(define-read-only (get-owner (token-id uint))
   (ok (nft-get-owner? bitbadge token-id))
)

(define-read-only (p2pkh-to-principal (scriptSig (buff 256)))
   (let 
      (
         (pk (unwrap! (as-max-len? (unwrap! (slice? scriptSig (- (len scriptSig) u33) (len scriptSig)) none) u33) none))
      )
      (some (unwrap! (principal-of? pk) none))
   )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
   (begin
      ;; #[filter(token-id, recipient)]
      (asserts! (is-eq tx-sender sender) err-not-token-owner)
      (nft-transfer? bitbadge token-id sender recipient)
   )
)

(define-public (mint (recipient principal) (height uint) (tx (buff 1024)) (header (buff 80)) (proof { tx-index: uint, hashes: (list 14 (buff 32)), tree-depth: uint}))
   (let
      (
         (token-id (+ (var-get last-token-id) u1))
         (tx-obj (try! (contract-call? 'ST3QFME3CANQFQNR86TYVKQYCFT7QX4PRXM1V9W6H.clarity-bitcoin parse-tx tx)))
         (tx-was-mined (try! (contract-call? 'ST3QFME3CANQFQNR86TYVKQYCFT7QX4PRXM1V9W6H.clarity-bitcoin was-tx-mined-compact height tx header proof)))
         (first-output (unwrap! (element-at (get outs tx-obj) u0) err-out-not-found))
         (first-input (unwrap! (element-at (get ins tx-obj) u0) err-in-not-found))
      )
      (asserts! (is-eq tx-was-mined true) err-tx-not-mined)
      (asserts! (is-eq u100 (get value first-output)) err-amount-mismatch)
      (try! (nft-mint? bitbadge token-id recipient))
      (var-set last-token-id token-id)
      (ok token-id)
   )
)
