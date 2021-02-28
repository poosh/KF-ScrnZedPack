# KF-ScrnZedPack
ScrN modification of custom monsters, adjusting game balance and bug fixes.

# Version History
### v1.20
#### Female Fleshpound
- Fixed hitbox during the rage run
- Adjusted head collision, so it can be shot from a side
- Known issue: when she lowers her head while walking (not raged), her head still remains up on the server.
#### Jason
- Removed auto-rage on bodyshots while stunned. It didn't work reliably on the server anyway.
- On HoE, Jason can be stunned only once.
- Flinch counter gets reset on stun. Now you can flich-lock him up to 5 times, then stun, then do 5 flinches again.

### v1.11
- Fixed an issue when **Shiver** could teleport if he did not see the player.
- Added slight randomness in Shiver's teleport cooldown preventing 4-pack squad to teleport at the same time

### v1.10
- **HardPat** made weaker on lower difficulties:
  - Chaingun burst proportionally lowered according to difficulty. HoE remained the same.
  - Chaingun Charging allowed only on Suicical and HoE.
  - Chaingun Charging stops on killing the player. HardPat may still may continue firing while walking though.
  - Moving while shooting the Chaingun is allowed on Hard and above. On Normal, HardPat stands still like the original.
  - Fires less rockets on Hard and below.
- Raised bounty for killing **HardPat**
- Fixed a bug when sometimes **HardPat** didn't fire a rocket while being at full health.
- **Shiver** cannot teleport while taking damage
