# Operation Last Signal — development

Target: Project Zomboid Build 42.20.2, hosted multiplayer.

Current behavior:

- A newly created local player requests the mission bootstrap from the host.
- The host grants the common mission kit exactly once per character.
- A newly created player selects one of four unique mission characters. The host
  locks each character to one username and grants a small role kit after a valid
  selection.
- A valid selection assigns the character's mission identity and raises skills
  that are below the role profile's minimum levels. Higher levels and XP
  progress for skills already at or above their minimum are preserved.
- Role profiles do not change vanilla professions, traits, or XP multipliers.
- Characters that already own a saved role receive its profile when they
  reconnect. Profile migration does not grant the common or role kit again.
- The supplied server profile places the `unemployed` profession at `5579,12485,1`.

## Role profiles

Every role receives the following military skill minimums:

| Skill | Minimum level |
| --- | ---: |
| Fitness | 7 |
| Strength | 7 |
| Aiming | 5 |
| Reloading | 5 |
| Sprinting | 4 |
| Nimble | 3 |
| Lightfoot | 3 |
| Maintenance | 3 |
| Small Blade | 3 |
| Axe | 2 |

Each role adds its own identity and specialization. The effective target for a
skill is the greater of its military and role-specific minimums.

| Role | Mission identity | Specialized minimums |
| --- | --- | --- |
| Commander | Captain Marcus Hale | Aiming 7, Reloading 6, Nimble 5, Sprinting 5, Maintenance 5 |
| Medic | Dr. Elena Reyes | First Aid 10, Lightfoot 5, Nimble 4 |
| Engineer | Corporal Noah Bennett | Mechanics 10, Electrical 8, Metalworking 10, Maintenance 6 |
| Security | Sergeant Daniel Price | Aiming 9, Reloading 8, Nimble 6, Fitness 8, Strength 8, Maintenance 6 |

The engineer also learns the vanilla vehicle, generator, and metalworking
knowledge required by the role:

- `Basic Mechanics`, `Intermediate Mechanics`, `Advanced Mechanics`, and
  `Generator`.
- `MetalWallLvl1`, `MetalWallLvl2`, `MetalFloorLvl1`,
  `MetalWindowFrameLvl1`, `MetalWindowFrameLvl2`, `MetalWallFrame`,
  `MetalDoorFrameLvl1`, `MetalDoorFrameLvl2`, and `Metal_Stairs`.
- `Metal_Counter_Lvl1`, `Metal_Counter_Lvl2`, `Metal_CounterCorner_Lvl1`,
  `Metal_CounterCorner_Lvl2`, `Metal_Crate_Lvl1`, `Metal_Crate_Lvl2`,
  `Metal_LockerBig_Lvl1`, `Metal_LockerBig_Lvl2`,
  `Metal_LockerSmall_Lvl1`, `Metal_LockerSmall_Lvl2`,
  `Metal_Shelves_Lvl1`, and `Metal_Shelves_Lvl2`.
- `MetalPoleFenceGate`, `MetalWireFenceGate`, `MetalWireFenceGateSmall`,
  `DoubleFenceGate`, `DoubleWireGate`, `MetalBigWireFence`,
  `MetalBigMetalFence`, `MetalPoleFenceGateSmall`, `MetalSmallPoleFence`,
  `MetalFenceLvl1`, and `MetalSmallWireFence`.
- `MakeMetalSheet` and `MakeSmallMetalSheet`.

## Server profile

The tracked files under `server-template/` define the reproducible
`operation-last-signal-dev` hosted-server profile. Copy all four files to
`~/Zomboid/Server/` and host the profile named `operation-last-signal-dev`.

The server displays each mission identity's first and last name when another
player moves the pointer over the character. Login usernames remain hidden.

The profile contains the server rules, sandbox rules, spawn regions, and spawn
point. Saved chunks, characters, vehicles, mission progress, and databases are
world state and remain outside the template.
