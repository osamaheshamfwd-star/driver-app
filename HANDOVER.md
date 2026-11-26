# Delivery Man Wallet — Handover Context

## Project
StackFood (CodeCanyon) Flutter food delivery template — 3 apps (customer, 
delivery man, restaurant) + Laravel backend (maintained by separate backend 
developer). This handover covers ONLY the delivery man wallet module.

## Relevant Files
- Screen: `lib/feature/my_account/screens/my_account_screen.dart`
- Controller: `lib/feature/my_account/controllers/my_account_controller.dart`
- Repository: `lib/feature/my_account/domain/repositories/my_account_repository.dart` 
  (+ interface)
- Service: `lib/feature/my_account/domain/services/my_account_service.dart` 
  (+ interface)
- Models: `lib/feature/my_account/domain/models/wallet_summary_model.dart`, 
  `withdraw_list_model.dart`, `wallet_payment_model.dart`
- Localization: `assets/language/ar.json`, `en.json`
- Possibly dead/broken: `lib/feature/my_account/screens/transaction_history_screen.dart` 
  — still references OLD controller API (pre-rewrite), causes build errors. 
  NOT YET FIXED — was mid-investigation when session ended (need to check if 
  it's still reachable via a "view_all" button, or if it's dead code to delete).

## Business Logic Context (why the design is this way)
- Delivery man wallet has TWO fundamentally different transaction types 
  (not two states of the same money):
  1. Cash he collected from customers (COD) that he owes the admin → 
     tracked via `wallet-payment-list` endpoint, tab "الفلوس اللي دفعتها"
  2. His own withdraw requests from the admin (his earnings) → tracked via 
     `get-withdraw-list` endpoint, tab "طلبات السحب"
- This mirrors (but is distinct from) the restaurant wallet, which uses a 
  single commission-owed model with مستحق/مدفوع tabs (do NOT reuse that 
  pattern here — confirmed as a design error earlier in the project).

## Confirmed API Endpoints (backend dev provided these specs)
1. `GET api/v1/delivery-man/wallet-summary` — balance summary: total_earning, 
   withdrawn, pending_withdraw, cash_in_hand, withdrawable_balance, 
   total_orders, net_profit (net_profit == total_earning, no extra 
   deduction needed, NOT displayed in UI per our decision).
2. `GET api/v1/delivery-man/wallet-payment-list` — paginated cash-handover 
   transactions. Params: limit (default 25), offset (default 1), from/to 
   (date), search (keyword).
3. `GET api/v1/delivery-man/get-withdraw-list` — paginated withdraw requests 
   with status (pending/approved/denied). Params: limit, offset, from/to.

## UI Design (confirmed, implemented)
- Orange summary banner (net amount due) — reused restaurant wallet's visual 
  style
- Two white cards side by side: "الفلوس اللي ليك" (withdrawable balance) / 
  "الفلوس اللي عليك" (cash in hand)
- Two tabs: "الفلوس اللي دفعتها" (cash_handed_over) / "طلبات السحب" 
  (withdraw_requests) — NOT مستحق/مدفوع
- Date filter icon scoped PER-TAB only (does not affect banner/cards)
- Free-delivery compensation renders as a normal transaction row, no 
  special badge/label
- pay_now / adjust_payments buttons moved BELOW the orange banner (not 
  inside it)

## What's Done (as of last working session)
- ar.json / en.json: all new keys added (cash_handed_over, withdraw_requests, 
  money_owed_to_you, money_you_owe, approved, denied, pending, etc.)
- app_constants.dart: walletSummaryUri, getWithdrawListUri added
- Repository + Service (interface + impl): getWalletSummary(), 
  getWalletPaymentList(), getWithdrawList() all implemented with 
  token + limit/offset + from/to params
- Controller: full rewrite — wallet summary state, per-tab payment/withdraw 
  lists, per-tab date range state, pagination, fallback getters to 
  ProfileModel where wallet-summary fields might be missing
- Screen: full rewrite — tabs relabeled, banner/cards bound to wallet-summary, 
  both tabs wired to their endpoints, per-tab date filter, per-tab 
  loading/error/empty states
- `dart analyze` on the my_account feature folder previously returned ZERO 
  errors (before the two bugs below were discovered) — this was BEFORE 
  transaction_history_screen.dart's break was found, so re-verify.

## 🐞 ACTIVE BUGS — fix these first
1. **pay_now button does nothing on tap.** Need to check: is an 
   onTap/onPressed handler even attached anymore after the rewrite? Is it 
   silently disabled because a flag (e.g. show_pay_now_button) from the new 
   wallet-summary response is null/false when it shouldn't be? Compare 
   against pre-rewrite behavior (see `.backup` files in the same folders if 
   present) to know what it used to do.
2. **"الفلوس اللي دفعتها" tab shows "something_went_wrong"** instead of 
   data. Suspect a response-envelope key mismatch (same class of bug found 
   earlier in WithdrawListModel, which tries multiple possible keys like 
   `withdraw_requests`/`data`/`withdraws` — WalletPaymentModel/parsing code 
   may need the same defensive handling). Need to log the raw HTTP response 
   to confirm actual key names before patching the model.
3. **transaction_history_screen.dart build errors** (separate old screen, 
   references removed controller API) — not yet resolved, may need deletion 
   if it's dead code (nothing navigates to it anymore since the new tabs 
   replaced its purpose) — needs verification first.

## Immediate Next Steps for You (Cursor)
1. Do a QUICK verification pass — read the current state of the 6 files 
   listed under "Relevant Files" to confirm they match what's described 
   above (things may have shifted slightly in the last session).
2. Investigate and report on Bugs #1 and #2 above (root cause) BEFORE 
   fixing — log raw API responses where relevant.
3. Investigate transaction_history_screen.dart reachability (Bug #3) and 
   report whether it's dead code or still in use.
4. Wait for confirmation, then fix all three.
5. `.backup` files should already exist for touched files — do not overwrite 
   them; create new ones only for files not yet backed up before your first 
   edit.

## Out of scope for this session (do not touch)
- Order sorting (separate pending item, backend coordination needed)
- Checkout address auto-fill clearing (not started, separate scope item)
- Restaurant wallet (already complete)
