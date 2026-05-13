# Session Index Caching with State Verification

## Technique Overview

**Session Index Caching with Explicit Verification Gates** is a memory technique that combines index-backed codebase analysis (as implemented in [analyze-repo.md](analyze-repo.md)) with timestamp-based state tracking and session-level purging policies. This reduces redundant repository scans by maintaining a verified index state across agent runs, explicitly tracking when repository structure was last validated, and triggering re-indexing only when evidence suggests staleness.

This technique bridges short-term session context (what do I know right now?) with long-term repository facts (what structure is stable?), preventing both over-retention of stale mental models and wasteful re-scanning of unchanged code.

---

## Connection to Lab 2 Agents

This memory practice directly extends the **analyze-repo.md** agent workflow:

- **Index layer**: analyze-repo.md builds and maintains agents/index/ (manifest.json, symbols.json, folders.json, hashes.json, state.json)
- **Memory addition**: Session Index Caching adds timestamp metadata and refresh rules to those indexes
- **Verification gates**: Before trusting an index for Canvas feature analysis, we check that the repository state matches known-good signatures and that the index age is within acceptable bounds

**Applies to**: Any future feature implementation (Lab 4 onwards) that must quickly locate Canvas entry points, understand the plugin system, or verify that a code change does not break the build chain.

---

## Procedure (Prompts / File Rituals)

### 1. Session Startup (First query in a new session)

**Prompt pattern used with agent**:
```
Before analyzing the Canvas repository, check agents/index/state.json.
If missing or the repository root has changed, run agents/build-index.py.
Record in state.json the ISO timestamp of index build and the file hash of agents/index/manifest.json.
Do not reuse indexes from previous sessions without verifying state matches current workspace root.
```

**File ritual**:
- Read agents/index/state.json (if present)
- Verify `repository_root` matches current workspace (c:\Users\Isaac\OneDrive\Documents\Semester_8\ai_cse290r\canvas-lms)
- If match and `index_built_at` is within 24 hours, proceed with cached indexes
- If not, trigger a full rebuild before analyzing source

### 2. Mid-Session Refresh (After git pull or significant edits)

**Trigger**: After pulling upstream Canvas changes or after editing core files (config/, gems/, ui/)

**Prompt pattern**:
```
The repository has been updated. Run agents/hash-files.py to detect which subtrees changed.
Update agents/index/hashes.json with new file hashes.
If changes span more than 15% of the codebase or touch agents/index/symbols.json, rebuild all indexes.
Otherwise, reindex only the touched subtrees.
```

**File ritual**:
- Save current session notes to agents/index/session-context.md (see Evidence section)
- Run hash-files.py to detect file changes
- Update state.json with `last_refresh_at` timestamp
- If major changes detected, rebuild indexes; otherwise refresh touched subtrees only

### 3. Analysis Task (Locating features, entry points, or risks)

**Prompt pattern**:
```
Use manifest.json and symbols.json to find [feature/component].
Do not open source files until you have:
1. Identified the top-level folder from folders.json
2. Found all relevant symbols in symbols.json
3. Consulted hashes.json to avoid re-opening unchanged files
Only load source code for the smallest slice needed to answer the question.
```

**File ritual**:
- Query agents/index/ first (state.json → folders.json → manifest.json)
- Load symbols from symbols.json (includes Canvas plugin hooks, GraphQL resolvers, etc.)
- Record any manual lookups in agents/index/session-context.md with timestamp and rationale
- Update session context if analysis reveals a new entry point or hotspot not captured in existing indexes

### 4. Session End / Long-Term Checkpoints

**Prompt pattern**:
```
Before ending the session, summarize what was verified:
- Which Canvas components are known-good? (e.g., "GraphQL resolvers in app/graphql/ unchanged for 3 days")
- Which areas have high churn? (e.g., "ui/components/Assignment.tsx edited 5 times in 1 week")
- Which indexes need rebuilding soon? (e.g., "symbols.json should be refreshed after next upstream pull")
Store this summary and the timestamp in agents/index/session-summary.md.
```

**File ritual**:
- Write to agents/index/session-summary.md:
  - Verified components and signatures (what you trust without re-checking)
  - Risky or changed areas (what needs re-verification before committing)
  - Next refresh time (when to rebuild indexes)
  - Current session end timestamp
- Update state.json with `last_session_end_at` for next session's startup check

---

## Purge / Refresh / Last Verified

### Purge Policy

Indexes are considered **stale** if:

1. **Age threshold**: More than 7 days since `index_built_at` (long session break)
2. **Upstream drift**: Repository root or major configuration changed
3. **Symbol churn**: More than 5 significant files added/removed in Canvas components (app/, ui/, gems/)
4. **Explicit invalidation**: Developer manually runs `agents/build-index.py --force`

When an index is stale:
- Discard old manifest.json, symbols.json, folders.json
- Keep hashes.json for change detection
- Run agents/build-index.py to regenerate from scratch
- Record new timestamp in state.json

### Refresh Policy

For **unchanged** repository state:
- Use cached indexes for up to 7 days
- Before each session, verify `last_verified_at` timestamp in state.json
- If within 24 hours, trust indexes without rechecking
- If beyond 24 hours but within 7 days, spot-check a few key files (hashes) before trusting

### Last Verified Metadata (in state.json)

```json
{
  "repository_root": "c:\\Users\\Isaac\\OneDrive\\Documents\\Semester_8\\ai_cse290r\\canvas-lms",
  "schema_version": "1.0",
  "index_built_at": "2026-05-13T14:30:00Z",
  "last_session_end_at": "2026-05-13T16:00:00Z",
  "last_refresh_at": "2026-05-13T16:00:00Z",
  "manifest_hash": "sha256:abc123...",
  "next_purge_candidate_date": "2026-05-20T14:30:00Z",
  "notes": "All indexes valid; ui/ untouched for 3 days; app/graphql/ refreshed after upstream pull"
}
```

---

## Failure Modes and Mitigations

| Failure Mode | Impact | Mitigation |
|---|---|---|
| **Stale symbol map**: Old version of function X still in cache, but it moved to new module | Agent suggests wrong file for feature; wastes time on misdirection | Check `last_verified_at` in state.json; if >7 days, rebuild. Cross-check symbols.json against analyze-repo.md before major analysis. |
| **Index built from partial clone**: git history incomplete or vendor/ not synced | manifest.json misses plugins or dependencies; agent can't find entry points | Add pre-build check in agents/build-index.py to verify git refs and key directories exist. Fail loudly if state looks incomplete. |
| **Over-trust of cached indexes**: Developer merges upstream Canvas without rebuilding | Agent uses old symbols; suggests changes to deprecated API | Document refresh triggers: always rebuild after `git pull` from upstream canvas-lms. Add state.json `upstream_merge_detected` flag. |
| **Session context bloat**: agents/index/session-context.md grows unbounded with every query | Token budget wasted on session notes; slower agent response | Purge session context at session boundary (every 24 hours). Archive old summaries to agents/index/archive/. Keep only last 5 sessions worth. |
| **Hash collisions or skipped files**: agents/hash-files.py misses a file change | Agent trusts old index; may not detect Canvas breaking change | Run hash-files.py twice on contentious areas. Use both SHA256 and file size for collision detection. Log any skipped files in state.json. |

### Key Mitigations in Practice

1. **Always rebuild after upstream pull**:
   - Add git hook (if allowed) or explicit prompt: "Did you pull Canvas upstream? If yes, rebuild indexes."
   
2. **Timestamp gates before trust**:
   - Never use index older than 7 days without explicit re-verification.
   - If `last_verified_at` is missing, treat as invalid.

3. **Spot-check critical paths**:
   - Before analyzing Canvas entry points, manually verify at least one symbol from symbols.json exists in the source.
   - Example: Grep for "GraphQLMutation" in app/graphql/ to confirm symbols map is current.

4. **Session boundary discipline**:
   - End each long session with a summary in agents/index/session-summary.md.
   - Start next session by reading that summary and state.json.
   - If either is missing or stale, rebuild everything.

---

## Evidence Excerpt (No Secrets)

### Session Context Entry (agents/index/session-context.md)

```markdown
## Session: 2026-05-13 14:00 UTC

### Index Verification
- Read state.json: last_verified_at = 2026-05-13T08:00:00Z (6 hours ago, within 24h threshold) ✓
- Repository root matches: c:\Users\Isaac\...\canvas-lms ✓
- manifest.json hash: abc123def456 (unchanged from state) ✓
- Proceeded with cached indexes

### Queries in Session
1. **Query**: Where is the GraphQL mutation for creating an assignment?
   - Used symbols.json → found "CreateAssignmentMutation" in app/graphql/mutations/
   - Verified with grep: 1 result in app/graphql/mutations/create_assignment.rb
   - Time saved vs full repo search: ~90 seconds
   - Added to session-summary.md as verified location

2. **Query**: What Canvas plugins are active?
   - Used folders.json → gems/plugins/ has 12 subdirectories
   - Consulted manifest.json → identified plugin load order
   - Found plugin_manifest.json in each plugin; verified 8 plugins active
   - No source code needed; index lookup sufficient

### Changes Detected
- bin/setup.sh: timestamp changed, hash different
- ui/components/Assignment.tsx: hash different (likely under development)
- Run agents/hash-files.py before next session to update hashes

### Session End Summary Saved
- Location: agents/index/session-summary.md
- Timestamp: 2026-05-13T16:00:00Z
- Next refresh candidate: 2026-05-20 (7 days ahead)
```

### Example Session Summary (agents/index/session-summary.md)

```markdown
## Summary: 2026-05-13

### Verified Components (Trust without re-check for 3 days)
- GraphQL mutations: manifest verified, symbols current, 3 mutations analyzed
- Plugin system: gems/plugins/ unchanged, 8 active plugins confirmed
- React component tree: ui/components/ structure stable, no major refactoring

### High-Churn Areas (Re-verify before committing)
- ui/components/Assignment.tsx: 3 edits in past 48h (under active development)
- config/boot.strap.rb: hash changed today (likely dependency update)

### Recommended Actions
- Before Lab 4 feature work: Run `agents/build-index.py` after next upstream Canvas pull
- Before major commits: Spot-check symbols.json against app/graphql/ and gems/plugins/

### Index Metadata
- Built: 2026-05-13T08:00:00Z
- Purge date: 2026-05-20T08:00:00Z
- Session count since build: 2
```

### Actual Session Conversation Excerpt (redacted)

```
[User]: "Where does Canvas initialize feature flags?"

[Agent - with memory practice]:
1. Checked state.json: indexes 6h old, within threshold ✓
2. Queried symbols.json: found "FeatureFlag" class in lib/feature_flags.rb
3. Queried manifest.json: identified app/models/feature_flag.rb (model)
4. Did NOT open full app/ folder; looked only at the 2 files symbols pointed to
5. Found feature_flags initialization in config/initializers/feature_flags.rb
6. Answered in <30 seconds using only index lookups + 3 small file opens

[Time saved]: vs. full repository scan, avoided ~500KB of irrelevant context
[Recorded]: In session-context.md as verified pattern for future sessions
```

---

## Integration with Future Agent Runs

When Lab 4 feature work begins:

1. **Startup**: analyze-repo.md will check agents/index/state.json and session-summary.md
2. **Skip rebuild** if both exist, are current, and verify-gate passes
3. **Use cached indexes** to quickly navigate Canvas plugin system, GraphQL resolvers, and React components
4. **Avoid re-scanning** thousands of lines of LMS business logic already indexed in previous sessions
5. **Record any new discoveries** in session-context.md for the next session to learn from

This memory practice will save hundreds of tokens per session during intensive feature development.

---

## Related Files

- [agents/analyze-repo.md](analyze-repo.md) — Base agent that builds and uses indexes
- agents/index/state.json — Repository state tracking (timestamp, hash, validation)
- agents/index/manifest.json — File inventory (auto-generated)
- agents/index/symbols.json — Code symbol map (auto-generated)
- agents/index/session-context.md — Current session query log (maintained by procedure)
- agents/index/session-summary.md — End-of-session verification summary (maintained by procedure)
