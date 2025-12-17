# Mountain Home - Project TODO

This file tracks tasks, ideas, and progress across different aspects of the project.

## Design Tasks (Game Loop & Systems)
- [ ] Define core game loop, turn structure, and pacing (month/season cadence)
- [ ] Design hex grid layout, size, and camera behavior
- [ ] Specify building types, costs, effects, and upgrade paths
- [ ] Define resource system (types, income sources, upkeep, sinks)
- [ ] Map season/month mechanics to rules, modifiers, and events
- [ ] Define win/loss conditions and failure states
- [ ] Draft UI/UX flow for all screens and in-game HUD

## Screen Architecture & Navigation
- [ ] Choose screen manager pattern (modules with enter/exit/update/draw) and event bus (pub/sub) for transitions
- [ ] Define transition events: `screen:pre_exit`, `screen:pre_enter`, `screen:entered`, `screen:request`
- [ ] Wire Love2D callbacks (update/draw/input) to current screen via screen manager
- [ ] Specify common screen context passed on transitions (save handles, audio bus, assets)
- [ ] Plan transition effects (fade/slide) and loading indicators for heavy scenes

### Screen Specs
- [ ] Introduction screens: studio logo, "presents", timed image sequence, click-to-advance/skip, intro music/SFX
- [ ] Menu screen: title + buttons (New Game, Load, Achievements, Options, Cheats/secret, Quit)
- [ ] New Game: location select on Rocky Mountains map; hover for town info; confirm selection
- [ ] Load Game: list saves, metadata preview, delete/confirm prompts
- [ ] Game screen: core HUD (resources, season/month, actions), hex interaction, tooltips
- [ ] Achievements: list with unlock criteria, progress, rewards, filters
- [ ] Options: audio, video, input bindings (if any), gameplay toggles; persist settings
- [ ] Cheats: gated visibility; list discovered cheats with toggles; validate activation flow
- [ ] Quit: confirm dialog; call `love.event.quit` with cleanup hook

## Technical Tasks (Core Architecture)
- [ ] Implement event bus module (subscribe/unsubscribe/emit) used across screens/UI/gameplay
- [ ] Implement screen manager (register screens, go_to with transition events, lifecycle hooks)
- [ ] Set up Love2D project structure (main.lua entry, screens/, lib/, assets/)
- [ ] Implement hex coordinate system (axial/cube/offset decision + converters)
- [ ] Implement hex rendering system (batching, camera/zoom, highlight/hover)
- [ ] Implement building placement validation and interaction
- [ ] Create central game state management (data model, persistence points)
- [ ] Implement month/season progression and scheduled events
- [ ] Add save/load system (slots, serialization, validation)
- [ ] Integrate JSON (lunajson) and HTTP (lua-http) for future API use; wrap in api_client module
- [ ] Set up testing framework (luaunit/busted); cover logic modules and state transitions
- [ ] Performance profiling for grid rendering and update loops

## Art Tasks
- [ ] Design hex tile sprites (base + variants)
- [ ] Create building sprites (per type and upgrade level)
- [ ] Design UI elements (buttons, panels, tooltips, HUD)
- [ ] Create icons for resources and statuses
- [ ] Design backgrounds/atmosphere per season
- [ ] Create seasonal visual variations (palette/overlays/particles)

## Audio Tasks
- [ ] Intro music and stingers for logo/presents
- [ ] Background music per season/scene
- [ ] Sound effects for UI, placement, resource changes, achievements
- [ ] Ambient loops for seasonal/weather flavor

## Documentation Tasks
- [ ] Expand README with setup, controls, and screen navigation
- [ ] Document game rules/mechanics and season/month effects
- [ ] Create architecture doc (screen manager, event bus, state modules)
- [ ] Write player guide/tutorial outline

## Future Enhancements
- [ ] Multiplayer support
- [ ] Additional building types and tech tree depth
- [ ] Weather system with gameplay impact
- [ ] Random events system with rarity and season weighting
- [ ] Achievements expansion and meta-progression

---

## Phases

### Phase 0 — Core Structure Prototype
- [ ] Set up project scaffolding (screens/, lib/, assets/, reference/)
- [ ] Implement event bus (pub/sub) and screen manager with enter/exit/update/draw
- [ ] Stub all screens (intro, menu, new_game_location, load_game, game, achievements, options, cheats, quit) with programmer art placeholders
- [ ] Wire Love2D callbacks to current screen; add basic transition events (`screen:pre_exit`, `screen:pre_enter`, `screen:entered`)
- [ ] Add simple navigation flow between screens (no gameplay logic)
- [ ] Add placeholder UI elements/text to validate layout/navigation

### Phase 1 — AI Behavior Engine Integration
- [ ] Review `reference/behaviorengine/Artificial Agency API Reference.html` and `reference/behaviorengine/openapi.json`
- [ ] Add HTTP + JSON deps (lua-http, lunajson) and package.path wiring
- [ ] Implement `api_client` module for sessions/agents/messages (wrap create session, create agent, add messages)
- [ ] Create simple in-game console/log to show API interactions and errors
- [ ] Add minimal UI flow to start a session and create an agent; display returned IDs
- [ ] Add stub to send a test ContentMessage and show the response
- [ ] Handle API key/version headers and configurable endpoints

### Phase 2 — Simple Game Loop (Hex Homestead, Card Hand)
- [ ] Design session for mechanics: hex map layout, card play flow, month/season pacing
- [ ] Implement minimal hex grid rendering and selection (placeholder art)
- [ ] Implement player hand, draw/discard, and basic card effects on hex tiles
- [ ] Advance month/turn loop with state updates and UI feedback
- [ ] Persist minimal state (local save) for hand/deck and homestead upgrades
- [ ] Add tooltips/hover info for tiles and cards

### Phase 3 — Cheats and Fun Extras
- [ ] Implement cheat activation flow (secret trigger) and cheats screen visibility
- [ ] Add toggleable cheats affecting resources/cards/map visibility
- [ ] Log cheat activation events; ensure they propagate via event bus

### Phase 4 — Visuals and Audio Polish
- [ ] Replace programmer art with final sprites, UI, and animations
- [ ] Add season-aware audio/music and UI sound set
- [ ] Add transition effects between screens; polish layout and typography
- [ ] Optimize rendering and loading; refine performance for larger maps

---

## Notes
- Add notes, ideas, or blockers here as they come up
- Move completed items to a "Completed" section at the bottom if desired

