;; Button Press Confidence Erosion Algorithm Smart Contract
;; Creates doubt about button effectiveness requiring compulsive re-pressing for psychological comfort

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_FLOOR (err u101))
(define-constant ERR_INVALID_USER (err u102))
(define-constant ERR_PRESS_LIMIT_EXCEEDED (err u103))
(define-constant ERR_CONFIDENCE_TOO_HIGH (err u104))
(define-constant ERR_INVALID_TIMING (err u105))
(define-constant ERR_SYSTEM_OVERLOAD (err u106))

;; Maximum number of floors and users
(define-constant MAX_FLOORS u50)
(define-constant MAX_USERS u1000)
(define-constant MAX_PRESSES_PER_FLOOR u10)
(define-constant CONFIDENCE_THRESHOLD u75)
(define-constant EROSION_FACTOR u15)
(define-constant PSYCHOLOGICAL_DELAY u3000)

;; Data Variables
(define-data-var total-button-presses uint u0)
(define-data-var active-users uint u0)
(define-data-var system-confidence-level uint u50)
(define-data-var erosion-active bool true)
(define-data-var contract-version uint u1)

;; Maps for tracking button press data
(define-map button-press-history
  { user: principal, floor: uint }
  { 
    press-count: uint,
    last-press-time: uint,
    confidence-level: uint,
    psychological-state: (string-ascii 20),
    requires-additional-presses: bool,
    total-session-time: uint
  }
)

;; Map for floor-specific confidence erosion settings
(define-map floor-erosion-config
  { floor: uint }
  {
    erosion-rate: uint,
    minimum-presses: uint,
    confidence-threshold: uint,
    active: bool,
    last-calibration: uint
  }
)

;; Map for user confidence profiles
(define-map user-confidence-profile
  { user: principal }
  {
    base-confidence: uint,
    erosion-susceptibility: uint,
    total-presses: uint,
    anxiety-level: uint,
    last-interaction: uint,
    profile-active: bool
  }
)

;; Map for press sequence validation
(define-map press-sequence-tracker
  { user: principal, session-id: uint }
  {
    sequence-valid: bool,
    required-presses: uint,
    completed-presses: uint,
    sequence-start-time: uint,
    confidence-erosion-applied: uint
  }
)

;; Map for psychological manipulation parameters
(define-map psychological-parameters
  { floor: uint }
  {
    doubt-amplifier: uint,
    uncertainty-factor: uint,
    compulsion-trigger: uint,
    satisfaction-delay: uint,
    effectiveness-illusion: bool
  }
)

;; Read-only functions

;; Get button press history for a user and floor
(define-read-only (get-press-history (user principal) (floor uint))
  (map-get? button-press-history { user: user, floor: floor })
)

;; Get floor erosion configuration
(define-read-only (get-floor-config (floor uint))
  (map-get? floor-erosion-config { floor: floor })
)

;; Get user confidence profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-confidence-profile { user: user })
)

;; Calculate confidence erosion for a user
(define-read-only (calculate-confidence-erosion (user principal) (floor uint))
  (let (
    (user-profile (default-to 
      { base-confidence: u50, erosion-susceptibility: u20, total-presses: u0, 
        anxiety-level: u30, last-interaction: u0, profile-active: true }
      (map-get? user-confidence-profile { user: user })
    ))
    (floor-config (default-to
      { erosion-rate: u10, minimum-presses: u2, confidence-threshold: u60,
        active: true, last-calibration: u0 }
      (map-get? floor-erosion-config { floor: floor })
    ))
    (base-confidence (get base-confidence user-profile))
    (susceptibility (get erosion-susceptibility user-profile))
    (erosion-rate (get erosion-rate floor-config))
  )
    (if (< base-confidence CONFIDENCE_THRESHOLD)
      (* (* erosion-rate susceptibility) EROSION_FACTOR)
      (* erosion-rate EROSION_FACTOR)
    )
  )
)

;; Determine if additional button presses are required
(define-read-only (requires-additional-presses (user principal) (floor uint))
  (let (
    (erosion-level (calculate-confidence-erosion user floor))
    (user-confidence (default-to u50 
      (get base-confidence (map-get? user-confidence-profile { user: user }))
    ))
  )
    (> erosion-level (/ user-confidence u2))
  )
)

;; Get current system confidence level
(define-read-only (get-system-confidence)
  (var-get system-confidence-level)
)

;; Get total button presses in system
(define-read-only (get-total-presses)
  (var-get total-button-presses)
)

;; Check if erosion is currently active
(define-read-only (is-erosion-active)
  (var-get erosion-active)
)

;; Get psychological parameters for a floor
(define-read-only (get-psychological-parameters (floor uint))
  (map-get? psychological-parameters { floor: floor })
)

;; Public functions

;; Register a button press and apply confidence erosion
(define-public (register-button-press (floor uint) (user principal))
  (let (
    (current-time stacks-block-height)
    (current-history (default-to
      { press-count: u0, last-press-time: u0, confidence-level: u50,
        psychological-state: "stable", requires-additional-presses: false,
        total-session-time: u0 }
      (map-get? button-press-history { user: user, floor: floor })
    ))
    (press-count (+ (get press-count current-history) u1))
    (erosion-amount (calculate-confidence-erosion user floor))
    (new-confidence (if (> (get confidence-level current-history) erosion-amount)
                     (- (get confidence-level current-history) erosion-amount)
                     u0))
    (needs-more-presses (requires-additional-presses user floor))
  )
    (asserts! (<= floor MAX_FLOORS) ERR_INVALID_FLOOR)
    (asserts! (<= press-count MAX_PRESSES_PER_FLOOR) ERR_PRESS_LIMIT_EXCEEDED)
    (asserts! (var-get erosion-active) ERR_SYSTEM_OVERLOAD)
    
    ;; Update button press history
    (map-set button-press-history
      { user: user, floor: floor }
      {
        press-count: press-count,
        last-press-time: current-time,
        confidence-level: new-confidence,
        psychological-state: (if (< new-confidence u30) "anxious" "stable"),
        requires-additional-presses: needs-more-presses,
        total-session-time: (+ (get total-session-time current-history) PSYCHOLOGICAL_DELAY)
      }
    )
    
    ;; Update system statistics
    (var-set total-button-presses (+ (var-get total-button-presses) u1))
    
    ;; Update user confidence profile
    (update-user-confidence-profile user erosion-amount)
    
    ;; Apply psychological manipulation
    (apply-psychological-manipulation user floor)
    
    (ok press-count)
  )
)

;; Initialize floor erosion configuration
(define-public (initialize-floor-config (floor uint) (erosion-rate uint) (min-presses uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= floor MAX_FLOORS) ERR_INVALID_FLOOR)
    (asserts! (> erosion-rate u0) ERR_INVALID_TIMING)
    
    (map-set floor-erosion-config
      { floor: floor }
      {
        erosion-rate: erosion-rate,
        minimum-presses: min-presses,
        confidence-threshold: CONFIDENCE_THRESHOLD,
        active: true,
        last-calibration: stacks-block-height
      }
    )
    
    (ok true)
  )
)

;; Update user confidence profile
(define-private (update-user-confidence-profile (user principal) (erosion-applied uint))
  (let (
    (current-profile (default-to
      { base-confidence: u50, erosion-susceptibility: u20, total-presses: u0,
        anxiety-level: u30, last-interaction: u0, profile-active: true }
      (map-get? user-confidence-profile { user: user })
    ))
    (new-confidence (if (> (get base-confidence current-profile) erosion-applied)
                     (- (get base-confidence current-profile) (/ erosion-applied u2))
                     u10))
    (new-anxiety (let ((calc-anxiety (+ (get anxiety-level current-profile) (/ erosion-applied u3))))
                   (if (> calc-anxiety u100) u100 calc-anxiety)))
  )
    (map-set user-confidence-profile
      { user: user }
      {
        base-confidence: new-confidence,
        erosion-susceptibility: (get erosion-susceptibility current-profile),
        total-presses: (+ (get total-presses current-profile) u1),
        anxiety-level: new-anxiety,
        last-interaction: stacks-block-height,
        profile-active: true
      }
    )
  )
)

;; Apply psychological manipulation parameters
(define-private (apply-psychological-manipulation (user principal) (floor uint))
  (let (
    (current-params (default-to
      { doubt-amplifier: u20, uncertainty-factor: u15, compulsion-trigger: u25,
        satisfaction-delay: PSYCHOLOGICAL_DELAY, effectiveness-illusion: false }
      (map-get? psychological-parameters { floor: floor })
    ))
    (manipulation-strength (+ (get doubt-amplifier current-params) 
                             (get uncertainty-factor current-params)))
  )
    (map-set psychological-parameters
      { floor: floor }
      {
        doubt-amplifier: (get doubt-amplifier current-params),
        uncertainty-factor: (get uncertainty-factor current-params),
        compulsion-trigger: manipulation-strength,
        satisfaction-delay: (* PSYCHOLOGICAL_DELAY u2),
        effectiveness-illusion: (> manipulation-strength u30)
      }
    )
  )
)

;; Validate button press sequence
(define-public (validate-press-sequence (user principal) (session-id uint) (expected-presses uint))
  (let (
    (sequence-data (default-to
      { sequence-valid: false, required-presses: u2, completed-presses: u0,
        sequence-start-time: u0, confidence-erosion-applied: u0 }
      (map-get? press-sequence-tracker { user: user, session-id: session-id })
    ))
    (completed (get completed-presses sequence-data))
    (required (get required-presses sequence-data))
  )
    (asserts! (> expected-presses u0) ERR_INVALID_TIMING)
    
    (map-set press-sequence-tracker
      { user: user, session-id: session-id }
      {
        sequence-valid: (>= completed required),
        required-presses: expected-presses,
        completed-presses: completed,
        sequence-start-time: (get sequence-start-time sequence-data),
        confidence-erosion-applied: (calculate-confidence-erosion user u1)
      }
    )
    
    (ok (>= completed required))
  )
)

;; Toggle erosion system active state
(define-public (toggle-erosion-system)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set erosion-active (not (var-get erosion-active)))
    (ok (var-get erosion-active))
  )
)

;; Emergency reset of user confidence
(define-public (emergency-confidence-reset (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set user-confidence-profile
      { user: user }
      {
        base-confidence: u50,
        erosion-susceptibility: u20,
        total-presses: u0,
        anxiety-level: u30,
        last-interaction: stacks-block-height,
        profile-active: true
      }
    )
    
    (ok true)
  )
)

;; title: button-press-confidence-erosion-algorithm
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

