;; Knowledge Graph Marketplace - Trade structured knowledge and data insights
;; A decentralized marketplace for buying and selling knowledge graphs and data insights

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_PRICE (err u400))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_INPUT (err u422))
(define-constant MARKETPLACE_FEE u250) ;; 2.5% fee in basis points

;; Data Variables
(define-data-var next-knowledge-id uint u1)
(define-data-var marketplace-fee-recipient principal CONTRACT_OWNER)
(define-data-var marketplace-active bool true)

;; Data Maps
(define-map knowledge-graphs
  { knowledge-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    price: uint,
    data-hash: (string-ascii 64),
    metadata-uri: (optional (string-ascii 200)),
    tags: (list 10 (string-ascii 30)),
    created-at: uint,
    is-active: bool,
    total-sales: uint,
    rating-sum: uint,
    rating-count: uint
  }
)

(define-map user-profiles
  { user: principal }
  {
    username: (string-ascii 50),
    reputation-score: uint,
    total-purchases: uint,
    total-sales: uint,
    created-at: uint
  }
)

(define-map purchases
  { buyer: principal, knowledge-id: uint }
  {
    purchased-at: uint,
    price-paid: uint,
    access-granted: bool
  }
)

(define-map reviews
  { reviewer: principal, knowledge-id: uint }
  {
    rating: uint,
    comment: (string-ascii 300),
    created-at: uint
  }
)

(define-map access-permissions
  { user: principal, knowledge-id: uint }
  bool
)

;; Private Functions
(define-private (calculate-marketplace-fee (price uint))
  (/ (* price MARKETPLACE_FEE) u10000)
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

(define-private (update-knowledge-rating (knowledge-id uint) (new-rating uint))
  (let (
    (knowledge-data (unwrap! (map-get? knowledge-graphs { knowledge-id: knowledge-id }) false))
    (current-sum (get rating-sum knowledge-data))
    (current-count (get rating-count knowledge-data))
    (new-sum (+ current-sum new-rating))
    (new-count (+ current-count u1))
  )
    (map-set knowledge-graphs
      { knowledge-id: knowledge-id }
      (merge knowledge-data {
        rating-sum: new-sum,
        rating-count: new-count
      })
    )
  )
)

;; Public Functions

;; Create user profile
(define-public (create-user-profile (username (string-ascii 50)))
  (begin
    (asserts! (is-eq none (map-get? user-profiles { user: tx-sender })) ERR_ALREADY_EXISTS)
    (asserts! (> (len username) u0) ERR_INVALID_INPUT)
    (ok (map-set user-profiles
      { user: tx-sender }
      {
        username: username,
        reputation-score: u100,
        total-purchases: u0,
        total-sales: u0,
        created-at: block-height
      }
    ))
  )
)

;; List a new knowledge graph
(define-public (list-knowledge-graph 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (price uint)
  (data-hash (string-ascii 64))
  (metadata-uri (optional (string-ascii 200)))
  (tags (list 10 (string-ascii 30)))
)
  (let (
    (knowledge-id (var-get next-knowledge-id))
  )
    (asserts! (var-get marketplace-active) ERR_NOT_AUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (> (len title) u0) ERR_INVALID_INPUT)
    (asserts! (> (len description) u0) ERR_INVALID_INPUT)
    (asserts! (> (len data-hash) u0) ERR_INVALID_INPUT)
    
    (map-set knowledge-graphs
      { knowledge-id: knowledge-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        category: category,
        price: price,
        data-hash: data-hash,
        metadata-uri: metadata-uri,
        tags: tags,
        created-at: block-height,
        is-active: true,
        total-sales: u0,
        rating-sum: u0,
        rating-count: u0
      }
    )
    
    (var-set next-knowledge-id (+ knowledge-id u1))
    (print { 
      event: "knowledge-graph-listed", 
      knowledge-id: knowledge-id, 
      owner: tx-sender,
      title: title,
      price: price
    })
    (ok knowledge-id)
  )
)

;; Purchase knowledge graph
(define-public (purchase-knowledge-graph (knowledge-id uint))
  (let (
    (knowledge-data (unwrap! (map-get? knowledge-graphs { knowledge-id: knowledge-id }) ERR_NOT_FOUND))
    (price (get price knowledge-data))
    (owner (get owner knowledge-data))
    (marketplace-fee (calculate-marketplace-fee price))
    (seller-amount (- price marketplace-fee))
  )
    (asserts! (var-get marketplace-active) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active knowledge-data) ERR_NOT_FOUND)
    (asserts! (not (is-eq tx-sender owner)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? purchases { buyer: tx-sender, knowledge-id: knowledge-id })) ERR_ALREADY_EXISTS)
    
    ;; Transfer payment
    (try! (stx-transfer? seller-amount tx-sender owner))
    (try! (stx-transfer? marketplace-fee tx-sender (var-get marketplace-fee-recipient)))
    
    ;; Record purchase
    (map-set purchases
      { buyer: tx-sender, knowledge-id: knowledge-id }
      {
        purchased-at: block-height,
        price-paid: price,
        access-granted: true
      }
    )
    
    ;; Grant access
    (map-set access-permissions
      { user: tx-sender, knowledge-id: knowledge-id }
      true
    )
    
    ;; Update knowledge graph stats
    (map-set knowledge-graphs
      { knowledge-id: knowledge-id }
      (merge knowledge-data { total-sales: (+ (get total-sales knowledge-data) u1) })
    )
    
    ;; Update user profiles
    (match (map-get? user-profiles { user: tx-sender })
      buyer-profile (map-set user-profiles
        { user: tx-sender }
        (merge buyer-profile { total-purchases: (+ (get total-purchases buyer-profile) u1) })
      )
      true
    )
    
    (match (map-get? user-profiles { user: owner })
      seller-profile (map-set user-profiles
        { user: owner }
        (merge seller-profile { total-sales: (+ (get total-sales seller-profile) u1) })
      )
      true
    )
    
    (print { 
      event: "knowledge-graph-purchased", 
      knowledge-id: knowledge-id, 
      buyer: tx-sender,
      seller: owner,
      price: price
    })
    (ok true)
  )
)

;; Add review for purchased knowledge graph
(define-public (add-review (knowledge-id uint) (rating uint) (comment (string-ascii 300)))
  (begin
    (asserts! (is-some (map-get? purchases { buyer: tx-sender, knowledge-id: knowledge-id })) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-rating rating) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? reviews { reviewer: tx-sender, knowledge-id: knowledge-id })) ERR_ALREADY_EXISTS)
    
    (map-set reviews
      { reviewer: tx-sender, knowledge-id: knowledge-id }
      {
        rating: rating,
        comment: comment,
        created-at: block-height
      }
    )
    
    (update-knowledge-rating knowledge-id rating)
    
    (print { 
      event: "review-added", 
      knowledge-id: knowledge-id, 
      reviewer: tx-sender,
      rating: rating
    })
    (ok true)
  )
)

;; Update knowledge graph (owner only)
(define-public (update-knowledge-graph 
  (knowledge-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (price uint)
  (is-active bool)
)
  (let (
    (knowledge-data (unwrap! (map-get? knowledge-graphs { knowledge-id: knowledge-id }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get owner knowledge-data)) ERR_NOT_AUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (> (len title) u0) ERR_INVALID_INPUT)
    
    (map-set knowledge-graphs
      { knowledge-id: knowledge-id }
      (merge knowledge-data {
        title: title,
        description: description,
        price: price,
        is-active: is-active
      })
    )
    
    (print { 
      event: "knowledge-graph-updated", 
      knowledge-id: knowledge-id, 
      owner: tx-sender
    })
    (ok true)
  )
)

;; Read-only functions

;; Get knowledge graph details
(define-read-only (get-knowledge-graph (knowledge-id uint))
  (map-get? knowledge-graphs { knowledge-id: knowledge-id })
)

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

;; Check if user has access to knowledge graph
(define-read-only (has-access (user principal) (knowledge-id uint))
  (default-to false (map-get? access-permissions { user: user, knowledge-id: knowledge-id }))
)

;; Get purchase details
(define-read-only (get-purchase (buyer principal) (knowledge-id uint))
  (map-get? purchases { buyer: buyer, knowledge-id: knowledge-id })
)

;; Get review
(define-read-only (get-review (reviewer principal) (knowledge-id uint))
  (map-get? reviews { reviewer: reviewer, knowledge-id: knowledge-id })
)

;; Get average rating for knowledge graph
(define-read-only (get-average-rating (knowledge-id uint))
  (match (map-get? knowledge-graphs { knowledge-id: knowledge-id })
    knowledge-data (if (> (get rating-count knowledge-data) u0)
      (some (/ (get rating-sum knowledge-data) (get rating-count knowledge-data)))
      none
    )
    none
  )
)

;; Get next knowledge ID
(define-read-only (get-next-knowledge-id)
  (var-get next-knowledge-id)
)

;; Admin functions (Contract owner only)

;; Set marketplace fee recipient
(define-public (set-marketplace-fee-recipient (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set marketplace-fee-recipient recipient)
    (ok true)
  )
)

;; Toggle marketplace active status
(define-public (toggle-marketplace-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set marketplace-active (not (var-get marketplace-active)))
    (ok (var-get marketplace-active))
  )
)