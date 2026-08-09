# Operation Last Signal — bootstrap 0.2.0

Target: Project Zomboid Build 42.20.2, hosted multiplayer.

Current behavior:

- A newly created local player requests the mission bootstrap from the host.
- The host grants the common mission kit exactly once per character.
- A newly created player selects one of four unique mission characters. The host
  locks each character to one username and grants a small role kit after a valid
  selection.
- Role selection does not change vanilla professions, traits, or skills.
- The supplied server spawn-point template places the `unemployed` profession at `5579,12480,0`.

The template intentionally keeps the world unchanged. It does not reset zombies, buildings, vehicles, or player deaths.
