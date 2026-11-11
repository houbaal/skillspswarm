# CD Technique Catalog

Techniques for delivering changes incrementally while keeping every commit deployable. Each technique addresses a specific class of change.

---

## Technique Selection

| Change type                                   | Primary technique          | Alternative              |
|-----------------------------------------------|----------------------------|--------------------------|
| New feature (incomplete, needs hiding)        | Feature Flags              | Dark Launching           |
| Database schema change                        | Expand-and-Contract        | Parallel Change          |
| API modification (breaking)                   | Expand-and-Contract        | Strangler Fig            |
| Major component replacement                   | Branch by Abstraction      | Strangler Fig            |
| Data migration between systems                | Parallel Change            | Expand-and-Contract      |
| Legacy system replacement                     | Strangler Fig              | Branch by Abstraction    |
| Risky change needing production validation    | Dark Launching             | Feature Flags            |

---

## 1. Branch by Abstraction

**When**: Replacing a major component (database, framework, library).

**Steps**:
1. Create abstraction layer over old implementation (deployable)
2. Switch all code to use abstraction (deployable)
3. Add new implementation behind abstraction (deployable)
4. Gradually migrate to new implementation (each step deployable)
5. Remove old implementation (deployable)
6. Optionally remove abstraction (deployable)

**Example** — MySQL to PostgreSQL:
```
Commit 1: Create DatabaseInterface abstraction
Commit 2: Wrap MySQL calls with DatabaseInterface
Commit 3: Add PostgreSQL implementation of DatabaseInterface
Commit 4: Add feature flag to switch between MySQL/PostgreSQL
Commit 5: Enable PostgreSQL for 5% of traffic
Commit 6: Enable PostgreSQL for 100% of traffic
Commit 7: Remove MySQL implementation
Commit 8: Remove abstraction if no longer needed
```

---

## 2. Expand-and-Contract

**When**: Database schema changes, API modifications. The workhorse of incremental delivery.

**Three phases**:
1. **EXPAND**: Add new schema/field/endpoint alongside old one
2. **MIGRATE**: Gradually move code to use new version
3. **CONTRACT**: Remove old schema/field/endpoint once unused

**Example** — Renaming a field:
```
Commit 1: Add user.full_name, keep user.name
Commit 2: Write to both user.name and user.full_name
Commit 3: Update read code to use user.full_name (fallback to user.name)
Commit 4: Backfill user.full_name from existing user.name records
Commit 5: Update all remaining code to use only user.full_name
Commit 6: Remove user.name column
```

**Multi-layer example** (DB + API + UI):
```
Deployment 1:  Expand DB (add new column, DEFAULT value)
Deployment 2:  API writes to BOTH columns
Deployment 3:  Backfill existing data
Deployment 4:  API reads from new (fallback to old)
Deployment 5:  Add new API endpoint
Deployment 6:  UI switches to new endpoint
Deployment 7:  API stops writing to old
Deployment 8:  Remove old API endpoint
Deployment 9:  Remove fallback logic
Deployment 10: Drop old DB column
```

**Multiple consumers**: When a provider has N consumers, expand provider once, then for each consumer: expand -> migrate -> contract. Contract provider last.

---

## 3. Parallel Change (Dual Writes/Dual Reads)

**When**: Migrating data between systems, changing storage.

**Steps**:
1. Write to both old and new system
2. Backfill data from old to new
3. Read from new system (with fallback to old)
4. Stop writing to old system
5. Remove old system

**Example** — Session storage to database:
```
Commit 1: Add database session storage alongside memory
Commit 2: Write sessions to both memory and database
Commit 3: Read from database (fallback to memory if missing)
Commit 4: Backfill memory sessions to database
Commit 5: Stop writing to memory
Commit 6: Remove memory session code
```

---

## 4. Feature Flags (Feature Toggles)

**When**: Large features, risky changes, A/B testing, gradual rollout.

**Types**:
- **Release flags**: Hide incomplete features in production (short-lived)
- **Ops flags**: Control system behavior, kill switches (long-lived)
- **Experiment flags**: A/B testing, gradual rollout (medium-lived)
- **Permission flags**: Enable features for specific users/roles (long-lived)

**Example** — New recommendation algorithm:
```
Commit 1: Add feature flag system if not exists
Commit 2: Add new algorithm (behind flag, default OFF)
Commit 3: Add tests for new algorithm
Commit 4: Enable flag for 1% of users
Commit 5: Monitor metrics, adjust flag to 10%
Commit 6: Enable for 100% of users
Commit 7: Remove old algorithm
Commit 8: Remove feature flag
```

**Placement rule**: Toggle in the **outermost layer only** (one `if`). Don't scatter flag checks throughout the codebase.

**Naming**: `enable_new_recommendation_v2`, `use_postgres_session_store` — never `new_feature`, `flag1`, `temp_fix`.

---

## 5. Dark Launching

**When**: Testing new code paths in production without user impact.

**Steps**:
1. Deploy new code that runs in parallel with old code
2. New code executes but results are **discarded**
3. Monitor new code's behavior (performance, errors, correctness)
4. Gradually switch to new code once validated
5. Remove old code

**Example** — New payment processor:
```
Commit 1: Add new payment processor (doesn't affect user flow)
Commit 2: Execute in parallel, discard results, log metrics
Commit 3: Compare results with old processor (shadow mode)
Commit 4: Add feature flag to switch between processors
Commit 5: Process 5% of real payments with new processor
Commit 6: Process 100% with new processor
Commit 7: Remove old processor
```

---

## 6. Strangler Fig Pattern

**When**: Replacing legacy systems incrementally.

**Steps**:
1. Build new system alongside old one
2. Route specific features/routes to new system
3. Gradually move more functionality to new system
4. Old system shrinks until it can be removed

**Example**:
```
Commit 1: Set up routing layer (can direct to old or new system)
Commit 2: Build new /api/users endpoint
Commit 3: Route /api/users to new system, rest to old
Commit 4: Build new /api/orders endpoint
Commit 5: Route /api/orders to new system
[Continue until old system is empty]
Commit N: Remove old system and routing layer
```

---

## Deployment Direction

The direction of delivery depends on whether you're building new or refactoring existing:

| Context              | Direction     | Pattern                            | Why                                              |
|----------------------|---------------|------------------------------------|--------------------------------------------------|
| **New feature**      | Outside-In    | UI -> API -> DB + Feature Flag     | Consumer drives design; flag hides incompleteness |
| **Refactoring**      | Inside-Out    | DB -> API -> UI + Expand-Contract  | Provider stability first; backward compat         |
| **Multi-consumer**   | Inside-Out    | Expand provider -> migrate each    | One expand, N migrations, one contract            |

**New feature outside-in sequence**:
1. Toggle + UI stub
2. UI with hardcoded data
3. UI calls stub API
4. API stub response
5. Database + real integration
6. Toggle cleanup

**Refactoring inside-out sequence**:
1. EXPAND: Add new alongside old (write both, read new with fallback)
2. MIGRATE: Switch consumers one by one
3. CONTRACT: Remove old when all migrated
