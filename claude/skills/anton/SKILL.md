# Skill: Early-Stage Startup Engineering & Architecture
**Author:** Anton Kropp (Distilled)
**Context:** 0 -> Series A scaling. High velocity, high safety, minimal overhead.
**Role:** Principal Engineer / Founding Engineer / CTO

## 1. Core Architectural Tenets

### The Modular Monolith
*   **Structure:** Single repository, single deployment unit initially.
*   **Boundaries:** Enforce strict module boundaries via linting (e.g., `no-restricted-imports` in ESLint).
*   **Access Rules:** Services interact via public APIs only.
    *   *Allowed:* `Gateway -> Users`, `Gateway -> Banking`.
    *   *Forbidden:* `Users -> Banking` (if Banking depends on Users). Avoid circular dependencies.
*   **Circular Dependency Resolution:** Use eventing/queues to decouple execution.
*   **Directory Structure:** Start flat (`/services/users`, `/services/banking`). Evolve to hierarchical only when complexity demands (`/banking/core/accounts`, `/banking/fraud/rules`).

### Strong Typing & Branded Types
*   **Philosophy:** "I am too dumb to be the compiler." Offload cognitive load to the type system.
*   **Primitive Obsession:** Avoid passing raw `string` or `number` for IDs.
*   **Pattern: Branded Types (Opaque Types):**
    ```typescript
    export type Brand<K, T> = K & { __brand: T };
    export type UserId = Brand<number, 'UserId'>;
    export type AccountId = Brand<number, 'AccountId'>;
    // Compiler error if AccountId is passed to function expecting UserId
    ```

### Inversion of Control (IoC)
*   **Dependency Injection:** Inject dependencies via constructors. Avoid global state/singletons.
*   **Time as a Dependency:** Never use `Date.now()` directly. Inject a `TimeProvider` to allow deterministic testing (traveling forward/backward in time).
*   **Frameworks:** Abstract frameworks (HTTP, ORM) behind interfaces. Enable "escape hatches" (e.g., raw SQL access) when the framework limits performance.

## 2. Infrastructure & Operations (DevOps)

### Buy vs. Build
*   **Rule:** Cloud Native > Self-Hosted. Use managed services (Fargate, RDS, SQS, Datadog) until cost becomes a survival issue.
*   **Anti-Pattern:** Self-hosting VPNs, Databases (Cassandra), or K8s clusters in early stages.

### Infrastructure as Code (IaC)
*   **Tooling:** Terraform/OpenTofu or CDK.
*   **Safety:** Disallow `delete` actions on stateful resources (DBs, S3) via IAM policies/Service Control Policies.
*   **Audit:** Wrap IaC execution in a CLI to log/notify (Slack) when infrastructure changes occur outside CI/CD.

### Deployment Pipeline
*   **Artifacts:** Build **once**. The same Docker image/binary moves from Dev -> Stage -> Prod. Configuration is injected at runtime (Env vars), not build time.
*   **Versioning:** Use Git Tags or Commit SHAs. Maintain a history of deployments programmatically (e.g., DynamoDB table tracking deployments) to enable instant rollbacks.
*   **Strategy:** ECS/Fargate is sufficient for long periods. Avoid K8s complexity until necessary.
*   **Rule:** Do not deploy on Fridays.

### The "Mega CLI" Pattern
*   **Concept:** Centralize all developer tasks in a single repo-scoped CLI tool (e.g., `oclif`).
*   **Capabilities:**
    *   `bin/run db:migrate`
    *   `bin/run env:check` (validates local machine versions/dependencies)
    *   `bin/run support:close-account --id=123`
*   **Benefit:** standardized developer environment; reduces onboarding friction; creates an audit trail for manual ops.

## 3. Data & Persistence

### Partner Isolation
*   **Rule:** Never leak third-party IDs (Stripe, Banking Core) into the internal domain.
*   **Mapping:** Create internal `IDs` that map to external Partner IDs.
*   **Benefit:** Enables migration to different partners without rewriting core logic. Allows local data augmentation/caching.

### Database Patterns
*   **Relational (SQL):** Default for transactional/critical data. Use Read Replicas early to avoid analyzing production queries on the primary writer.
*   **NoSQL (Dynamo/Key-Value):** Use for high-volume, ephemeral, or simple lookup data.
    *   *Partitioning:* Always partition by Tenant/User ID.
    *   *Key Hygiene:* Automatically prefix keys to prevent collisions (`marketing:has_transacted`, `banking:has_transacted`).
*   **Deletion:** Soft deletes only (`deleted_at` timestamp). Monkey-patch ORMs to throw errors on hard deletes.

### Data Warehousing
*   **Hot vs. Cold:**
    *   *Hot:* Datadog/ELK (Recent logs, expensive).
    *   *Cold:* S3 + Athena (Historical logs, cheap, map-reduce capable).
*   **Analytics:** Abstract analytic events. Use a proxy (Segment) to route to multiple destinations (Mixpanel, Braze, Warehouse).

## 4. Observability & Reliability

### Context Propagation
*   **Trace IDs:** Generate a Trace ID at ingress. Propagate it through every function, async queue, and 3rd party call.
*   **Logging:** Structured JSON logs.
    *   *Pattern:* `log.with({ userId, traceId }).info("Action")`.
    *   *Redaction:* Auto-redact sensitive fields (PII, secrets) via middleware.

### Metrics & Alerting
*   **Cardinality Warning:** Avoid high-cardinality tags (UserIDs) in metrics backends (Datadog) to prevent billing explosions.
*   **Alerting Philosophy:**
    *   *Business Hours:* Warning thresholds, non-critical anomalies.
    *   *Off-Hours:* Actionable catastrophes only. If it can wait until morning, it alerts Slack, not PagerDuty.
*   **Memory Leaks:** Monitor memory usage sawtooth patterns to identify closure retention issues in async loops.

### Feature Flags
*   **Evolution:**
    1.  Deploy-based config (Env vars).
    2.  Database-backed toggle.
    3.  **Hash Ring Pattern:** Deterministic rollout based on `hash(userId) % 100 <= percentage`.
    4.  Managed Service (LaunchDarkly).

## 5. Development Workflow & Culture

### Pull Requests (PRs)
*   **SLA:** < 24 hour turnaround.
*   **Size:** Small, atomic changes.
*   **Automation:** Linting, Formatting, and Tests run automatically.
*   **Context:** Link Jira/Linear tickets in PR title/commits via Git hooks (`prepare-commit-message`).

### Testing
*   **Hierarchy:**
    *   *Unit:* Logic verification.
    *   *Integration:* Dockerized dependencies (LocalStack for S3/SQS).
    *   *UI:* Use "Test IDs" composed hierarchically (e.g., `Page.test.ids().component.button`) rather than fragile string literals or XPath.
*   **Constraint:** Do not test in Production. Do not connect local dev environments to Production services.

### Hiring & Interviewing
*   **Anti-Pattern:** Leetcode/Binary Tree balancing.
*   **Pro-Pattern:**
    *   *Coding:* Practical data transformation/API implementation (1 hour). Focus on testability and edge cases.
    *   *System Design:* Collaborative problem solving. "How would we build X?" Focus on trade-offs (Convergence vs. Divergence).

### Customer Support Engineering
*   **Shift Left:** Expose support actions via the "Mega CLI" or a lightweight Admin Portal early.
*   **Safety:** "Read-Eval-Print-Loop" (REPL) access to production is a last resort. If used, require MFA/Confirmation tokens and broadcast usage to Slack.

## 6. Philosophy Summary
1.  **Be the Change:** Don't complain about friction; fix the tool, automate the script, improve the doc.
2.  **Done Done:** A feature is not done until it has metrics, alerts, documentation, and support tooling.
3.  **One Way Streets:** Identify decisions that are hard to reverse (Database choice, Public API contracts) and deliberate. Move fast on everything else.
4.  **Automate Boring Stuff:** If you do it twice, script it.