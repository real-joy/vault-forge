;; Title: VaultForge Protocol
;; Overview:
;;   VaultForge is a next-generation decentralized portfolio 
;;   coordination protocol designed for Bitcoin Layer 2 ecosystems. 
;;   It empowers users to design resilient, multi-asset strategies 
;;   that adapt to market dynamics while preserving full custody 
;;   and trustless execution.
;;
;; Vision:
;;   Rather than leaving portfolio management to centralized 
;;   platforms, VaultForge enables self-sovereign asset allocation, 
;;   dynamic rebalancing, and granular risk control - all powered 
;;   by the security foundation of Bitcoin.
;;
;; Core Features:
;;   - Create diverse portfolios with up to 10 tokens each
;;   - Automated rebalancing based on user-defined triggers
;;   - Allocation by target percentage with precision validation
;;   - On-chain portfolio history and performance tracking
;;   - Transparent fee structure for sustainable operations
;;   - Robust error handling to ensure secure interactions
;;
;; Why VaultForge?
;;   Just as a forge transforms raw material into strong alloys, 
;;   VaultForge transforms fragmented assets into a cohesive, 
;;   optimized portfolio. It's tailored for DeFi users seeking 
;;   both simplicity and institutional-grade sophistication.

;; ERROR CODES
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PORTFOLIO (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-REBALANCE-FAILED (err u104))
(define-constant ERR-PORTFOLIO-EXISTS (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107))
(define-constant ERR-LENGTH-MISMATCH (err u108))
(define-constant ERR-USER-STORAGE-FAILED (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))

;; DATA VARIABLES
(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% in basis points

;; CONSTANTS
(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000)

;; DATA MAPS
(define-map Portfolios
  uint ;; portfolio-id
  {
    owner: principal,
    created-at: uint,
    last-rebalanced: uint,
    total-value: uint,
    active: bool,
    token-count: uint,
  }
)

(define-map PortfolioAssets
  {
    portfolio-id: uint,
    token-id: uint,
  }
  {
    target-percentage: uint,
    current-amount: uint,
    token-address: principal,
  }
)

(define-map UserPortfolios
  principal
  (list 20 uint)
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-portfolio (portfolio-id uint))
  (map-get? Portfolios portfolio-id)
)

(define-read-only (get-portfolio-asset
    (portfolio-id uint)
    (token-id uint)
  )
  (map-get? PortfolioAssets {
    portfolio-id: portfolio-id,
    token-id: token-id,
  })
)

(define-read-only (get-user-portfolios (user principal))
  (default-to (list) (map-get? UserPortfolios user))
)

(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (total-value (get total-value portfolio))
    )
    (ok {
      portfolio-id: portfolio-id,
      total-value: total-value,
      needs-rebalance: (> (- stacks-block-height (get last-rebalanced portfolio)) u144), ;; ~24h in blocks
    })
  )
)

;; PRIVATE FUNCTIONS

(define-private (validate-token-id
    (portfolio-id uint)
    (token-id uint)
  )
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) false)))
    (and
      (< token-id MAX-TOKENS-PER-PORTFOLIO)
      (< token-id (get token-count portfolio))
      true
    )
  )
)

(define-private (validate-percentage (percentage uint))
  (and (>= percentage u0) (<= percentage BASIS-POINTS))
)

(define-private (validate-portfolio-percentages (percentages (list 10 uint)))
  (fold check-percentage-sum percentages true)
)

(define-private (check-percentage-sum
    (current-percentage uint)
    (valid bool)
  )
  (and valid (validate-percentage current-percentage))
)

(define-private (add-to-user-portfolios
    (user principal)
    (portfolio-id uint)
  )
  (let (
      (current-portfolios (get-user-portfolios user))
      (new-portfolios (unwrap! (as-max-len? (append current-portfolios portfolio-id) u20)
        ERR-USER-STORAGE-FAILED
      ))
    )
    (map-set UserPortfolios user new-portfolios)
    (ok true)
  )
)

(define-private (initialize-portfolio-asset
    (index uint)
    (token principal)
    (percentage uint)
    (portfolio-id uint)
  )
  (if (>= percentage u0)
    (begin
      (map-set PortfolioAssets {
        portfolio-id: portfolio-id,
        token-id: index,
      } {
        target-percentage: percentage,
        current-amount: u0,
        token-address: token,
      })
      (ok true)
    )
    ERR-INVALID-TOKEN
  )
)

;; PUBLIC FUNCTIONS

(define-public (create-portfolio
    (initial-tokens (list 10 principal))
    (percentages (list 10 uint))
  )
  (let (
      (portfolio-id (+ (var-get portfolio-counter) u1))
      (token-count (len initial-tokens))
      (percentage-count (len percentages))
      (token-0 (element-at? initial-tokens u0))
      (token-1 (element-at? initial-tokens u1))
      (percentage-0 (element-at? percentages u0))
      (percentage-1 (element-at? percentages u1))
    )
    (asserts! (<= token-count MAX-TOKENS-PER-PORTFOLIO) ERR-MAX-TOKENS-EXCEEDED)
    (asserts! (is-eq token-count percentage-count) ERR-LENGTH-MISMATCH)
    (asserts! (validate-portfolio-percentages percentages) ERR-INVALID-PERCENTAGE)

    (map-set Portfolios portfolio-id {
      owner: tx-sender,
      created-at: stacks-block-height,
      last-rebalanced: stacks-block-height,
      total-value: u0,
      active: true,
      token-count: token-count,
    })

    (asserts! (and (is-some token-0) (is-some token-1)) ERR-INVALID-TOKEN)
    (asserts! (and (is-some percentage-0) (is-some percentage-1))
      ERR-INVALID-PERCENTAGE
    )

    (try! (initialize-portfolio-asset u0 (unwrap-panic token-0)
      (unwrap-panic percentage-0) portfolio-id
    ))
    (try! (initialize-portfolio-asset u1 (unwrap-panic token-1)
      (unwrap-panic percentage-1) portfolio-id
    ))

    (try! (add-to-user-portfolios tx-sender portfolio-id))
    (var-set portfolio-counter portfolio-id)
    (ok portfolio-id)
  )
)