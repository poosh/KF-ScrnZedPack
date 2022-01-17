# Changelog

> [go back to README](../README.md 'go back to Table of Content')

<!-- steam link shortcuts -->
[NikC-]: http://steamcommunity.com/profiles/76561198044316328
[Vrana]: https://steamcommunity.com/profiles/76561198021913290

## v9.69.09 - FINAL

- Fixed an issue where **Tesla Husk** EMP explosion did too little or no damage to players
- Fixed Tesla's healing ability
- Sui/HoE: Fixed Tesla's ability to use zeds in-between to build an electrical chain to players

## v9.69.07

- **HardPat** gets 50% damage resistance during the healing process on HoE
- HardPat cannot be knocked down while shooting the first rocket on Suicidal/HoE
- Fixed "NoiseMaker" warning

## v9.69.06

- **HardPat** can fire chaingun on escaping when low on health
- Players cannot interrupt HardPat's healing process by dealing damage on Suicidal/HoE

## v9.69.01

- Fixed a bug that prevented **FP** raging from damage < 300 (behaved like FFP)
- Pat/HardPat's **Radial Attack**:
  - Removed ridiculous double damage to players with >50 armor
  - Made radial damage more consistent and scaled across difficulties.
    Originally, Pat did 54-108 damage to unarmored players, 108 - 216 to armored.
    Now, Pat does 52-87 damage on Hard, Suicidal: 63-105, Hoe: 73-122
  - Radial Attack can be performed only on Hard+ difficulty
  - Damage delivery matches the animation: first, Pat attacks players on the left, then on the right.
    Players straightly in front and at the back are attacked twice.
- Sui/HoE **HardPat**, when low on health, can perform Radial Attack against a single player (thanks [Vrana])
- Increased HardPat impale strike range from 0.9 to ~1.9m (thanks [NikC-])

## v2.00

- Added and reworked all vanilla zeds to ScrnZedPack
- Renamed most zed classes inside ScrnZedPack (check *ScrnWaves.ini*)
- Enhanced head detection
- Fixed projection of laser sights on big zed heads

### Bloat

- Doubled head health (25 -> 50 base)
- Head health increases by 20% per extra player. 6p HoE Bloat now has 175hp
  Not too much, but cannot be decapitated with just two off-perk 9mm shots
- Bloat cannot puke while decapitated
- Decapitating a Bloat immediately stops him from vomiting

### Siren

- Removed the scream canceling exploit
- Siren cannot scream when decapitated
- Decapitating Siren during screaming eliminates any further damage.
- Fixed vortex pull effect (it has been bugged in vanilla since the very beginning didn't work in the most cases).
- Reduced scream damage by 25% to compensate for fixed vortex pull.
- Siren scream shatters frozen zeds nearby, turning their bodies into deadly ice shards

### Scrake

- Saw loop damage now scales per difficulty. In vanilla it did not change, that why SC did so little damage on HoE.
- Base saw loop damage reduced by 20% to compensate fixed difficulty scaling. HoE saw damage is higher by ~40% now.

## v1.23

- Fixed FFP rage stop on Hard and below. On easier difficulties she always calms down after the hit no matter if she
  hits something or not.

## v1.22

### Female Fleshpound

- Fixed an issue where FFP completely stopped while preparing for the heavy attack
- It is still possible to dodge the heavy attack by jumping backward while holding a knife or having a perk with
  speed bonus
- Increased heavy attack damage
- FFP deals 25% more damage when enraged
- FFP makes the heavy attack only when enraged
- Fixed an issue when burning FFP couldn't start raging. Now setting FFP on fire can delay raging but not avoid it.
- Auto-rage timer lowered from 30-35s to 20-30s. Same as before, breaking the line of sight does not reset the timer
  but pauses it. Only damaging a player or breaking a door resets the auto-rage time.

## v1.21

- Improved headshot detection for all zeds in the pack, including the Grittier ones

### Female Fleshpound

- Fixed headbox of the attacking FFP. Now you need to shoot her in the head instead of boobs.
- Fixed an issue when FFP could do double damage on the heavy attack
- Increased base damage of the heavy attack to compensate the fixed double damage.
  Previously the heavy attack made 150% damage + (extra 100% due to bug). Now it always 175% damage.
- FFP slows down when preparing for an attack, but still continues to move.

## v1.20

### Female Fleshpound

- Fixed hitbox during the rage run
- Adjusted head collision, so it can be shot from a side
- Known issue: when she lowers her head while walking (not raged), her head still remains up on the server.

### Jason

- Removed auto-rage on bodyshots while stunned. It didn't work reliably on the server anyway.
- On HoE, Jason can be stunned only once.
- Flinch counter gets reset on stun. Now you can flich-lock him up to 5 times, then stun, then do 5 flinches again.

## v1.11

- Fixed an issue when **Shiver** could teleport if he did not see the player.
- Added slight randomness in Shiver's teleport cooldown preventing 4-pack squad to teleport at the same time

## v1.10

- **HardPat** made weaker on lower difficulties:
  - Chaingun burst proportionally lowered according to difficulty. HoE remained the same.
  - Chaingun Charging allowed only on Suicical and HoE.
  - Chaingun Charging stops on killing the player. HardPat may still may continue firing while walking though.
  - Moving while shooting the Chaingun is allowed on Hard and above. On Normal, HardPat stands still like the original.
  - Fires less rockets on Hard and below.
- Raised bounty for killing **HardPat**
- Fixed a bug when sometimes **HardPat** didn't fire a rocket while being at full health.
- **Shiver** cannot teleport while taking damage
