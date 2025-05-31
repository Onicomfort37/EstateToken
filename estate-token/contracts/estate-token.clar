;; Real Estate Investment Tokenization Protocol
;; Fractional ownership of real estate with rental income distribution

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-PROPERTY-NOT-ACTIVE (err u104))
(define-constant ERR-UNAUTHORIZED (err u105))
(define-constant ERR-ALREADY-EXISTS (err u106))
(define-constant ERR-INVESTMENT-CLOSED (err u107))
(define-constant ERR-MINIMUM-INVESTMENT (err u108))
(define-constant ERR-MAXIMUM-INVESTMENT (err u109))
(define-constant ERR-INVALID-PERCENTAGE (err u110))
(define-constant ERR-INSUFFICIENT-TOKENS (err u111))
(define-constant ERR-NO-INCOME-TO-DISTRIBUTE (err u112))
(define-constant ERR-ALREADY-CLAIMED (err u113))

;; Property Status Constants
(define-constant STATUS-FUNDRAISING u1)
(define-constant STATUS-ACTIVE u2)
(define-constant STATUS-SOLD u3)
(define-constant STATUS-LIQUIDATED u4)

;; Data Variables
(define-data-var next-property-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% = 250 basis points
(define-data-var minimum-investment uint u100000000) ;; 100 STX minimum
(define-data-var management-fee-rate uint u200) ;; 2% annually = 200 basis points

;; Property Tokens (one fungible token per property)
(define-map property-tokens
  uint
  principal ;; token contract address
)

;; Main Properties Data
(define-map properties
  uint
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    location: (string-ascii 128),
    property-type: (string-ascii 32), ;; "residential", "commercial", "industrial"
    total-value: uint, ;; Property valuation in micro-STX
    total-tokens: uint, ;; Total tokens representing 100% ownership
    tokens-sold: uint, ;; Tokens already sold to investors
    price-per-token: uint, ;; Price per token in micro-STX
    target-funding: uint, ;; Funding goal in micro-STX
    raised-amount: uint, ;; Amount raised so far
    status: uint, ;; 1=fundraising, 2=active, 3=sold, 4=liquidated
    created-at: uint,
    funding-deadline: uint,
    property-manager: principal,
    annual-rent-estimate: uint, ;; Expected annual rental income
    active: bool
  }
)

;; Property Financial Data
(define-map property-finances
  uint
  {
    total-rental-income: uint, ;; Lifetime rental income collected
    total-expenses: uint, ;; Lifetime property expenses
    last-income-distribution: uint, ;; Block height of last distribution
    pending-distribution: uint, ;; Income ready to be distributed
    total-distributed: uint, ;; Total amount distributed to investors
    property-appreciation: int, ;; Current property value change from initial
    occupancy-rate: uint ;; Current occupancy percentage (basis points)
  }
)

;; Investor Holdings
(define-map investor-holdings
  { investor: principal, property-id: uint }
  {
    tokens-owned: uint,
    investment-amount: uint, ;; Total STX invested
    total-dividends-received: uint,
    last-dividend-claim: uint, ;; Block height of last claim
    investment-date: uint
  }
)

;; Income Distribution Periods
(define-map income-distributions
  { property-id: uint, distribution-id: uint }
  {
    total-income: uint,
    distribution-date: uint,
    income-per-token: uint,
    claimed-amount: uint,
    total-eligible-tokens: uint
  }
)

;; Distribution Claims Tracking
(define-map distribution-claims
  { investor: principal, property-id: uint, distribution-id: uint }
  bool
)

;; Property Metadata and Documents
(define-map property-documents
  { property-id: uint, document-type: (string-ascii 32) }
  {
    document-hash: (buff 32), ;; IPFS hash or similar
    uploaded-by: principal,
    upload-date: uint,
    verified: bool
  }
)

;; Property Statistics
(define-map property-stats
  uint
  {
    total-investors: uint,
    average-investment: uint,
    monthly-rental-income: uint,
    expense-ratio: uint, ;; Expenses as percentage of income (basis points)
    roi-annualized: uint, ;; Return on investment (basis points)
    days-to-full-funding: uint
  }
)

;; Read-only functions
(define-read-only (get-property (property-id uint))
  (map-get? properties property-id)
)

(define-read-only (get-property-finances (property-id uint))
  (map-get? property-finances property-id)
)

(define-read-only (get-investor-holdings (investor principal) (property-id uint))
  (map-get? investor-holdings { investor: investor, property-id: property-id })
)

(define-read-only (get-property-stats (property-id uint))
  (map-get? property-stats property-id)
)

(define-read-only (get-income-distribution (property-id uint) (distribution-id uint))
  (map-get? income-distributions { property-id: property-id, distribution-id: distribution-id })
)

(define-read-only (get-total-properties)
  (- (var-get next-property-id) u1)
)

(define-read-only (calculate-token-value (property-id uint))
  (let (
    (property-info (unwrap! (get-property property-id) (err u0)))
    (finance-info (get-property-finances property-id))
  )
    (match finance-info
      finances
      (let (
        (current-value (+ (get total-value property-info) 
                         (if (>= (get property-appreciation finances) 0)
                           (to-uint (get property-appreciation finances))
                           u0)))
        (total-tokens (get total-tokens property-info))
      )
        (ok (if (> total-tokens u0) (/ current-value total-tokens) u0))
      )
      (ok (if (> (get total-tokens property-info) u0) 
            (/ (get total-value property-info) (get total-tokens property-info)) 
            u0))
    )
  )
)

(define-read-only (calculate-investor-ownership-percentage (investor principal) (property-id uint))
  (let (
    (holdings (get-investor-holdings investor property-id))
    (property-info (unwrap! (get-property property-id) (err u0)))
  )
    (match holdings
      holding-data
      (let (
        (tokens-owned (get tokens-owned holding-data))
        (total-tokens (get total-tokens property-info))
      )
        (ok (if (> total-tokens u0) 
              (/ (* tokens-owned u10000) total-tokens) 
              u0))
      )
      (ok u0)
    )
  )
)

(define-read-only (calculate-pending-dividends (investor principal) (property-id uint))
  (let (
    (holdings (unwrap! (get-investor-holdings investor property-id) (err u0)))
    (finances (unwrap! (get-property-finances property-id) (err u0)))
    (tokens-owned (get tokens-owned holdings))
    (pending-distribution (get pending-distribution finances))
    (property-info (unwrap! (get-property property-id) (err u0)))
    (total-tokens (get tokens-sold property-info))
  )
    (if (and (> tokens-owned u0) (> total-tokens u0))
      (ok (/ (* pending-distribution tokens-owned) total-tokens))
      (ok u0)
    )
  )
)

;; Private helper functions
(define-private (update-property-stats (property-id uint))
  (let (
    (property-info (unwrap! (get-property property-id) false))
    (current-stats (default-to 
      { total-investors: u0, average-investment: u0, monthly-rental-income: u0, 
        expense-ratio: u0, roi-annualized: u0, days-to-full-funding: u0 }
      (get-property-stats property-id)))
  )
    (map-set property-stats property-id current-stats)
    true
  )
)

;; Public functions

;; Create new real estate investment property
(define-public (create-property
  (name (string-ascii 64))
  (description (string-ascii 256))
  (location (string-ascii 128))
  (property-type (string-ascii 32))
  (total-value uint)
  (total-tokens uint)
  (target-funding uint)
  (funding-deadline uint)
  (property-manager principal)
  (annual-rent-estimate uint)
)
  (let (
    (property-id (var-get next-property-id))
    (price-per-token (/ total-value total-tokens))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> total-value u0) ERR-INVALID-AMOUNT)
    (asserts! (> total-tokens u0) ERR-INVALID-AMOUNT)
    (asserts! (> target-funding u0) ERR-INVALID-AMOUNT)
    (asserts! (> funding-deadline stacks-block-height) ERR-INVALID-AMOUNT)
    (asserts! (<= target-funding total-value) ERR-INVALID-AMOUNT)
    
    ;; Create property record
    (map-set properties property-id {
      name: name,
      description: description,
      location: location,
      property-type: property-type,
      total-value: total-value,
      total-tokens: total-tokens,
      tokens-sold: u0,
      price-per-token: price-per-token,
      target-funding: target-funding,
      raised-amount: u0,
      status: STATUS-FUNDRAISING,
      created-at: stacks-block-height,
      funding-deadline: funding-deadline,
      property-manager: property-manager,
      annual-rent-estimate: annual-rent-estimate,
      active: true
    })
    
    ;; Initialize financial tracking
    (map-set property-finances property-id {
      total-rental-income: u0,
      total-expenses: u0,
      last-income-distribution: u0,
      pending-distribution: u0,
      total-distributed: u0,
      property-appreciation: 0,
      occupancy-rate: u0
    })
    
    ;; Initialize statistics
    (map-set property-stats property-id {
      total-investors: u0,
      average-investment: u0,
      monthly-rental-income: u0,
      expense-ratio: u0,
      roi-annualized: u0,
      days-to-full-funding: u0
    })
    
    (var-set next-property-id (+ property-id u1))
    (ok property-id)
  )
)

;; Invest in a property (buy tokens)
(define-public (invest-in-property (property-id uint) (stx-amount uint))
  (let (
    (property-info (unwrap! (get-property property-id) ERR-NOT-FOUND))
    (price-per-token (get price-per-token property-info))
    (tokens-to-buy (/ stx-amount price-per-token))
    (actual-cost (* tokens-to-buy price-per-token))
    (platform-fee (/ (* actual-cost (var-get platform-fee-rate)) u10000))
    (net-investment (- actual-cost platform-fee))
    (current-holdings (default-to
      { tokens-owned: u0, investment-amount: u0, total-dividends-received: u0,
        last-dividend-claim: u0, investment-date: u0 }
      (get-investor-holdings tx-sender property-id)))
    (current-stats (default-to
      { total-investors: u0, average-investment: u0, monthly-rental-income: u0,
        expense-ratio: u0, roi-annualized: u0, days-to-full-funding: u0 }
      (get-property-stats property-id)))
  )
    (asserts! (get active property-info) ERR-PROPERTY-NOT-ACTIVE)
    (asserts! (is-eq (get status property-info) STATUS-FUNDRAISING) ERR-INVESTMENT-CLOSED)
    (asserts! (>= stx-amount (var-get minimum-investment)) ERR-MINIMUM-INVESTMENT)
    (asserts! (> tokens-to-buy u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (get tokens-sold property-info) tokens-to-buy) (get total-tokens property-info)) ERR-INSUFFICIENT-TOKENS)
    (asserts! (<= stacks-block-height (get funding-deadline property-info)) ERR-INVESTMENT-CLOSED)
    
    ;; Transfer STX from investor
    (try! (stx-transfer? actual-cost tx-sender (as-contract tx-sender)))
    
    ;; Update property with new investment
    (map-set properties property-id
      (merge property-info {
        tokens-sold: (+ (get tokens-sold property-info) tokens-to-buy),
        raised-amount: (+ (get raised-amount property-info) net-investment)
      })
    )
    
    ;; Update investor holdings
    (map-set investor-holdings { investor: tx-sender, property-id: property-id }
      (merge current-holdings {
        tokens-owned: (+ (get tokens-owned current-holdings) tokens-to-buy),
        investment-amount: (+ (get investment-amount current-holdings) net-investment),
        investment-date: (if (is-eq (get tokens-owned current-holdings) u0) 
                          stacks-block-height 
                          (get investment-date current-holdings))
      })
    )
    
    ;; Update statistics
    (map-set property-stats property-id
      (merge current-stats {
        total-investors: (if (is-eq (get tokens-owned current-holdings) u0)
                          (+ (get total-investors current-stats) u1)
                          (get total-investors current-stats))
      })
    )
    
    ;; Check if funding target is reached and activate property
    (if (>= (+ (get raised-amount property-info) net-investment) (get target-funding property-info))
      (map-set properties property-id
        (merge property-info {
          status: STATUS-ACTIVE,
          tokens-sold: (+ (get tokens-sold property-info) tokens-to-buy),
          raised-amount: (+ (get raised-amount property-info) net-investment)
        }))
      true
    )
    
    (ok tokens-to-buy)
  )
)

;; Record rental income (called by property manager)
(define-public (record-rental-income (property-id uint) (income-amount uint))
  (let (
    (property-info (unwrap! (get-property property-id) ERR-NOT-FOUND))
    (current-finances (unwrap! (get-property-finances property-id) ERR-NOT-FOUND))
    (management-fee (/ (* income-amount (var-get management-fee-rate)) u10000))
    (net-income (- income-amount management-fee))
  )
    (asserts! (is-eq tx-sender (get property-manager property-info)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status property-info) STATUS-ACTIVE) ERR-PROPERTY-NOT-ACTIVE)
    (asserts! (> income-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer income to contract
    (try! (stx-transfer? income-amount tx-sender (as-contract tx-sender)))
    
    ;; Update financial records
    (map-set property-finances property-id
      (merge current-finances {
        total-rental-income: (+ (get total-rental-income current-finances) net-income),
        pending-distribution: (+ (get pending-distribution current-finances) net-income)
      })
    )
    
    (ok net-income)
  )
)

;; Record property expenses
(define-public (record-expense (property-id uint) (expense-amount uint) (description (string-ascii 128)))
  (let (
    (property-info (unwrap! (get-property property-id) ERR-NOT-FOUND))
    (current-finances (unwrap! (get-property-finances property-id) ERR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get property-manager property-info)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status property-info) STATUS-ACTIVE) ERR-PROPERTY-NOT-ACTIVE)
    (asserts! (> expense-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Deduct expense from pending distribution
    (let (
      (new-pending (if (>= (get pending-distribution current-finances) expense-amount)
                     (- (get pending-distribution current-finances) expense-amount)
                     u0))
    )
      (map-set property-finances property-id
        (merge current-finances {
          total-expenses: (+ (get total-expenses current-finances) expense-amount),
          pending-distribution: new-pending
        })
      )
    )
    
    (ok true)
  )
)

;; Distribute rental income to token holders
(define-public (distribute-income (property-id uint) (distribution-id uint))
  (let (
    (property-info (unwrap! (get-property property-id) ERR-NOT-FOUND))
    (current-finances (unwrap! (get-property-finances property-id) ERR-NOT-FOUND))
    (pending-amount (get pending-distribution current-finances))
    (tokens-in-circulation (get tokens-sold property-info))
    (income-per-token (if (> tokens-in-circulation u0) 
                       (/ pending-amount tokens-in-circulation) 
                       u0))
  )
    (asserts! (is-eq tx-sender (get property-manager property-info)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status property-info) STATUS-ACTIVE) ERR-PROPERTY-NOT-ACTIVE)
    (asserts! (> pending-amount u0) ERR-NO-INCOME-TO-DISTRIBUTE)
    (asserts! (is-none (get-income-distribution property-id distribution-id)) ERR-ALREADY-EXISTS)
    
    ;; Create income distribution record
    (map-set income-distributions { property-id: property-id, distribution-id: distribution-id }
      {
        total-income: pending-amount,
        distribution-date: stacks-block-height,
        income-per-token: income-per-token,
        claimed-amount: u0,
        total-eligible-tokens: tokens-in-circulation
      }
    )
    
    ;; Update finances to mark income as distributed
    (map-set property-finances property-id
      (merge current-finances {
        pending-distribution: u0,
        last-income-distribution: stacks-block-height,
        total-distributed: (+ (get total-distributed current-finances) pending-amount)
      })
    )
    
    (ok distribution-id)
  )
)

;; Claim dividend from income distribution
(define-public (claim-dividend (property-id uint) (distribution-id uint))
  (let (
    (holdings (unwrap! (get-investor-holdings tx-sender property-id) ERR-NOT-FOUND))
    (distribution (unwrap! (get-income-distribution property-id distribution-id) ERR-NOT-FOUND))
    (already-claimed (default-to false 
      (map-get? distribution-claims { investor: tx-sender, property-id: property-id, distribution-id: distribution-id })))
    (tokens-owned (get tokens-owned holdings))
    (dividend-amount (* tokens-owned (get income-per-token distribution)))
  )
    (asserts! (not already-claimed) ERR-ALREADY-CLAIMED)
    (asserts! (> tokens-owned u0) ERR-INSUFFICIENT-TOKENS)
    (asserts! (> dividend-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer dividend to investor
    (try! (as-contract (stx-transfer? dividend-amount tx-sender tx-sender)))
    
    ;; Mark as claimed
    (map-set distribution-claims 
      { investor: tx-sender, property-id: property-id, distribution-id: distribution-id } 
      true)
    
    ;; Update distribution record
    (map-set income-distributions { property-id: property-id, distribution-id: distribution-id }
      (merge distribution {
        claimed-amount: (+ (get claimed-amount distribution) dividend-amount)
      })
    )
    
    ;; Update investor holdings
    (map-set investor-holdings { investor: tx-sender, property-id: property-id }
      (merge holdings {
        total-dividends-received: (+ (get total-dividends-received holdings) dividend-amount),
        last-dividend-claim: stacks-block-height
      })
    )
    
    (ok dividend-amount)
  )
)

;; Update property valuation (affects token value)
(define-public (update-property-valuation (property-id uint) (new-valuation uint))
  (let (
    (property-info (unwrap! (get-property property-id) ERR-NOT-FOUND))
    (current-finances (unwrap! (get-property-finances property-id) ERR-NOT-FOUND))
    (original-value (get total-value property-info))
    (appreciation (- (to-int new-valuation) (to-int original-value)))
  )
    (asserts! (is-eq tx-sender (get property-manager property-info)) ERR-UNAUTHORIZED)
    (asserts! (> new-valuation u0) ERR-INVALID-AMOUNT)
    
    ;; Update property value
    (map-set properties property-id
      (merge property-info {
        total-value: new-valuation
      })
    )
    
    ;; Update appreciation tracking
    (map-set property-finances property-id
      (merge current-finances {
        property-appreciation: appreciation
      })
    )
    
    (ok new-valuation)
  )
)

;; Sell property tokens on secondary market
(define-public (sell-tokens (property-id uint) (tokens-to-sell uint) (price-per-token uint))
  (let (
    (holdings (unwrap! (get-investor-holdings tx-sender property-id) ERR-NOT-FOUND))
    (tokens-owned (get tokens-owned holdings))
  )
    (asserts! (>= tokens-owned tokens-to-sell) ERR-INSUFFICIENT-TOKENS)
    (asserts! (> tokens-to-sell u0) ERR-INVALID-AMOUNT)
    (asserts! (> price-per-token u0) ERR-INVALID-AMOUNT)
    
    ;; This would integrate with a secondary market contract
    ;; For now, we'll just update the holdings to show tokens are listed
    
    (ok true)
  )
)

;; Administrative functions

;; Update platform fee
(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-fee u1000) ERR-INVALID-PERCENTAGE) ;; Max 10%
    (var-set platform-fee-rate new-fee)
    (ok true)
  )
)

;; Update management fee
(define-public (update-management-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-fee u500) ERR-INVALID-PERCENTAGE) ;; Max 5%
    (var-set management-fee-rate new-fee)
    (ok true)
  )
)

;; Emergency property status change
(define-public (update-property-status (property-id uint) (new-status uint))
  (let (
    (property-info (unwrap! (get-property property-id) ERR-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-status u4) ERR-INVALID-AMOUNT)
    
    (map-set properties property-id
      (merge property-info {
        status: new-status
      })
    )
    
    (ok true)
  )
)