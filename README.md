# Operation Last Signal — development

Target: Project Zomboid Build 42.20.2, hosted multiplayer.

Current behavior:

- A newly created local player requests the mission bootstrap from the host.
- The host grants the common mission kit exactly once per character.
- A newly created player selects one of four unique mission characters. The host
  locks each character to one username and grants a small role kit after a valid
  selection.
- Role selection does not change vanilla professions, traits, or skills.
- The supplied server profile places the `unemployed` profession at `5579,12485,1`.

## Server profile

The tracked files under `server-template/` define the reproducible
`operation-last-signal-dev` hosted-server profile. Copy all four files to
`~/Zomboid/Server/` and host the profile named `operation-last-signal-dev`.

The profile contains the server rules, sandbox rules, spawn regions, and spawn
point. Saved chunks, characters, vehicles, mission progress, and databases are
world state and remain outside the template.
