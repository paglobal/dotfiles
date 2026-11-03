# Connection Environments — implementation plan

Status: planning only. Agreed requirements below are not claims of implemented behavior. Implement in small, user-reviewed steps; resolve blocking decisions before dependent work. Ask before writing/running tests.

## Product and audience

Connection Environments hosts untrusted browser extensions. Host supplies graph editing, persistence, UI primitives, and communication; extensions define domain behavior.

Serve extension builders and consumers. Consumers must meet initial terminal/project bootstrap baseline. Extensions distributed through npm from day one. Consumer project installs host and extensions; `apps/test-playground` models this arrangement. Planned `create-connection-environment` package scaffolds projects. CLI expands over time; UI alternatives may follow.

## Existing foundation

- pnpm/Turbo workspace; client/server/demo packages; integration playground in apps.
- Dependency chain: playground → CLI umbrella → Hono server → Svelte client. Separate API SDK package.
- Umbrella is CLI-only; Commander; API consumed independently.
- Hono serves client assets in production and development. Development uses package-owned build watchers, Node restart, and SSE full-page reload—not Vite dev server/HMR.
- Existing API source is essentially empty; extension runtime/isolation, graph editor, and product workflows are not implemented.
- Earlier build/check passed before latest cleanup. Recent checks/dependency additions have not been installed/validated yet; do not assume lockfile current.
- Latest cleanup: project READMEs removed, `.changeset/README.md` preserved; nested server pnpm config removed; root `allowBuilds.esbuild: true`; demo and playground checks added; playground JavaScript checking configured through TypeScript. Verify actual files before continuing.

## Agreed architecture

### Client and documents

- Keep plain Svelte SPA. No router/SvelteKit needed currently.
- Primarily one workspace page with panels/dialogs. Query params represent shareable UI state; transient UI remains local. Exact parameter schema/history policy not specified.
- One active graph per browser tab. Other graphs can open in fresh tabs.
- Exactly one runtime iframe per activated extension per host browser tab, shared by all its node instances. Not per node or graph.
- Each extension has one movable/resizable custom-UI panel containing its iframe; extension conditionally renders content there. No additional custom-UI iframes assumed.
- Host also offers bounded declarative UI through API, not arbitrary extension HTML/JS/CSS in host DOM.

### Extension loading and trust

- Installed packages are not automatically activated. Explicit project configuration selects enabled extensions.
- All extension code runs in browser isolation, never imported/executed inside host Node process. Discover metadata/assets without executing extension code.
- Capabilities exposed through API; elevated access explicitly approved in project configuration. Activation is not blanket access.
- Baseline extension receives its own nodes' inputs and publishes their outputs. Broader graph access requires elevated permission; precise scope/grant model remains unresolved.
- Runtime SDK uses direct imports rather than injected activation-function API.
- Planned MessageChannel bridge: asynchronous typed methods, validated handshake/messages, capability enforcement; no functions crossing iframe boundary. Protocol details not finalized.
- npm installation has separate lifecycle-script risk; iframe isolation does not protect installation. Scaffold/package-consumption policy still needs design.
- CLI binds loopback by default. Remote access not initial target.

### Graph model

- Host owns canonical graph state, validates structural integrity, and relays changes to extensions.
- Extensions register node types; users create instances with stable IDs and independent properties.
- Editable properties are separate from connected input values; both changes notify node behavior.
- Node ports can change dynamically through host primitives. Behavior for removing a port needs explicit design consistent with dangling-wire preservation.
- Connections are plain wires, without host-defined uni/bidirectional domain types. Extensions interpret semantics.
- Domain connection equipment (electrical lines/transformers, etc.) is represented as extension-defined nodes.
- One wire per output port; wire has one source and may branch through tappable routing points to many destination input ports. One incoming wire per input port.
- Taps are host-owned visual routing points, not executable/domain nodes.
- No joining two output sources onto one wire. Explicit extension-defined merge nodes handle combining values.
- Users can delete individual branch or entire wire, with clear selection scope.
- Deleting node preserves attached wire endpoints as dangling endpoints at former attachment positions. Preserve remaining branches and geometry; do not automatically delete attached wires.
- Dangling endpoints can reconnect, respecting one-source/one-wire constraints and extension rules.
- Host provides extension connection-validation primitives; extension determines domain compatibility/contracts. Exact protocol deferred. Do not assume host-enforced semantic type system.

### Dataflow

- Host routes published node output values to connected inputs.
- Changed inputs notify owning extension so node can recalculate and publish outputs.
- Cycles allowed. Unchanged input values suppress unnecessary recalculation/propagation.
- Host transports values; extensions own calculations and domain meaning.
- Distinguish absent input from explicit null. Disconnecting/removing source clears downstream values and emits input-change notifications.
- Full graph/topology access is elevated, not baseline.

Provisional, explicitly revisit before implementation:
- JSON-compatible payload restriction and structural/value equality.
- Runaway-cycle/update budgets: equality does not stop oscillating/diverging cycles.
- Batching input changes/current snapshots without premature evaluation.
- Input revisions/stale asynchronous output rejection.
- Exact scheduling, initial evaluation, output lifetime, transport limits, and serialization remain unresolved.

### Persistence and concurrent tabs

- One server serves one consumer-project directory. Graph files confined to configured workspace location; no arbitrary browser-supplied filesystem paths.
- Multiple saved graph documents.
- Explicit Save, dirty indicator, unsaved-change warning. No autosave initially.
- Save nodes, properties, wires, routing/layout; exclude transient inputs/outputs and running computations by default.
- Missing/unavailable extensions preserve nodes/properties as disabled placeholders; no user-data deletion.
- Host undo/redo covers graph edits and property changes, not arbitrary extension side effects. Extensions receive resulting changes/recalculate.
- Tabs have independent in-memory working copies.
- Server watches saved graph files and notifies relevant tabs.
- Clean tabs reload saved changes. Dirty tabs preserve local edits and display conflict, offering Reload or Save As; no automatic merge.
- Revision-checked saves reject stale writes. Notification alone is insufficient. Server coordinates revision check/write to avoid competing host saves; guarantees against external writers need explicit design.
- Same-graph tabs receive advisory presence notice, not edit lock. Server tracks sessions using live connections and expires disconnected sessions; exact transport/timing undecided.
- Explicit overwrite-anyway option was not agreed.

## First reference extension: electrical load flow

- Buses, generators, loads, lines, transformers, etc. are extension-defined nodes.
- Example topology: bus → line node → bus; generator/load nodes attached to buses. Ports do not dictate physical power direction.
- User builds small network, enters equipment properties, clicks Solve, inspects bus voltages and branch power flows.
- Extension obtains approved relevant network topology/properties and solves coupled electrical model as whole.
- General node dataflow is not electrical solver/convergence algorithm.
- Initial host surfaces: canvas, add-node picker, property inspector, extension-contributed toolbar actions (including Solve). Custom UI not required for first useful workflow.
- Solver method, units, equipment schemas, validation, and result presentation not yet specified.
- Load-flow implementation location/new package name not decided; existing vanilla demo remains available for protocol smoke checks.

## Implementation sequence

### 0. Verify foundation and close current cleanup

Inspect actual manifests/config/source and pending user commentary. Review dependency/lockfile updates, then obtain permission for installation/check commands. Verify recent dev readiness/reload changes with user. Keep package boundaries and existing watcher workflow.

Exit: baseline builds/checks and development smoke behavior verified, or blockers explicitly recorded.

### 1. Define minimal contracts and invariants

Agree minimal node-type/instance, properties, port, branchable-wire/dangling-endpoint, and graph-document structures. Define stable IDs and document format version. Specify structural constraints independently of domain compatibility.

Resolve blocking dataflow choices incrementally: values/equality, event shapes, scheduling, revisions, limits. Define minimum permission and declaration schemas. Avoid freezing full SDK up front.

Exit: smallest contracts needed for sandbox and graph slice reviewed.

### 2. Browser extension loading and isolation

Add explicit project extension configuration and static metadata/asset resolution without server-side execution. Serve isolated extension assets; implement one iframe/runtime per extension/tab and one custom panel. Establish validated handshake and MessageChannel lifecycle, identities, scoped capabilities, and errors. SDK exposes direct runtime imports.

Before implementation: choose origins, sandbox flags, CSP/network policy, asset delivery, and custom-panel hiding behavior. Verify iframe actually remains isolated; browser-only execution alone is not sufficient.

Exit: demo registers safely and exchanges permitted messages; unauthorized operations rejected. Testing only after user approval.

### 3. First graph editing vertical slice

Implement host graph state and minimal canvas: register type, create node instance, position/select node, inspect/edit properties, expose ports, connect output to input. Add branching/taps, selection scopes, dangling endpoints, reconnection, and dynamic-port behavior in reviewed increments. Add structural undo/redo.

Exit: representative bus–line–bus graph editable with required wire semantics.

### 4. Node dataflow and declarative UI

Implement publication/routing, changed-input events, absence/null semantics, disconnect clearing, and agreed stale-result/batching/cycle protections. Add bounded inspector/forms/actions contributions and explicit cross-extension messaging/contracts as required. Keep computations extension-owned.

Exit: simple demo calculates values through branches/cycles under defined limits; host remains responsive.

### 5. Document persistence and tab coordination

Implement constrained list/open/save/save-as APIs, document validation, missing-extension placeholders, dirty tracking, and unsaved-change protection. Add coordinated revision saves, file watching, clean reload/dirty conflict behavior, and advisory tab presence. Persist model/layout only; complete persistence-aware undo/redo behavior.

Exit: two-tab save/conflict workflows preserve user work without automatic merge.

### 6. Load-flow vertical slice

Agree smallest electrical model and units; implement node definitions, parameter UI, elevated topology access, Solve action, solver integration, and voltage/branch-result presentation. Keep solver in browser extension. Pick numerical library/algorithm only after requirements review.

Exit: small reference network yields inspectable results and useful validation/errors.

### 7. Consumer bootstrap and release path

Implement `create-connection-environment`, explicit activation/permission configuration, and necessary CLI helpers. Ensure generated project mirrors playground package boundaries. Verify npm package contents, browser assets, exports/bin, compatible versions, and independent API consumption. In-app alternatives follow later.

Exit: fresh consumer can install published host/extensions, configure activation, run locally, edit/solve/save graph.

## Deferred questions — not accepted requirements

Final grilling round Q71–76 was unanswered:
- Precise project activation/runtime startup and graph-switch lifecycle.
- Extension crash detection, containment, restart, and graph editability.
- Whether failure clears published outputs.
- Node-level calculation errors/retry semantics.
- Network access defaults and host-mediated network capability.
- Extension/node saved-data versioning and migrations.

Other decisions to revisit when needed:
- Extension identifiers/versions, dependency and cross-extension contract discovery.
- Declarative UI schema/actions and custom-panel lifecycle.
- Elevated graph visibility scope and user approval UX.
- Dynamic-port removal and dangling endpoint identity.
- Dataflow equality, scheduling, initial values, cancellation, limits, error propagation.
- Document naming/location/schema evolution, external writer races, watcher failures.
- Numerical solver requirements and result persistence/export.
- Query-param schema/history behavior, keyboard/accessibility and canvas library selection.
- Automatic browser opening desired previously, not implemented.

## Working approach

No implementation authorized by this document alone. Review one small root-to-leaf slice at a time; stub dependencies only explicitly. Preserve reviewed formatting. Request permission before shell commands and before writing/running tests. Use temporary file commentary for implementation review, removing resolved notes. Update plan as decisions change; do not treat provisional/deferred choices as commitments.
