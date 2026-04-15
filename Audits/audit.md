# Audit: swift-defunctionalize

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/modularization-audit-foundations-batch-B.md (2026-03-20)

**Modularization audit — MOD-001 through MOD-014**

1 product: Defunctionalize. 3 targets: Defunctionalize, Defunctionalize Macros, Defunctionalize Macros Implementation (macro target).

| Rule | Status | Notes |
|------|--------|-------|
| MOD-001 | N/A | Main + Macros pattern |
| MOD-002 | PASS | Optic/Finite Primitives only on Macros (which needs them), swift-syntax only on Implementation |
| MOD-003 | N/A | Macros Implementation is a build-tool target, not a semantic variant |
| MOD-004 | N/A | No ~Copyable concerns |
| MOD-005 | N/A | Single product |
| MOD-006 | PASS | Minimal deps per target |
| MOD-007 | PASS | Depth 2 (Defunctionalize → Macros → Implementation) |
| MOD-008 | PASS | Main: 1, Macros: 1, Implementation: 7 |
| MOD-009 | N/A | No inline variants |
| MOD-010 | N/A | No stdlib extensions |
| MOD-011 | **FAIL** | No Test Support product |
| MOD-012 | PASS | `Defunctionalize`, `Defunctionalize Macros` — correct L3 naming |
| MOD-013 | N/A | 4 targets, threshold is 5 |
| MOD-014 | N/A | No cross-package optional integration |

**Findings**: 1 FAIL (MOD-011). No test support product. Given that this is a macro package, a test support product is less critical than for data-type packages but still required by the rule.
