# Changelog

> [go back to README](../README.md 'go back to Table of Content')

<!-- steam link shortcuts -->
[Joe]: http://steamcommunity.com/profiles/76561198005354377
[NikC-]: http://steamcommunity.com/profiles/76561198044316328
[Vrana]: https://steamcommunity.com/profiles/76561198021913290

## v9.74
- Fixed an issue when a **Shiver** could teleport and get stuck inside a shop.

## v9.71.09
- Fixed **Tesla Husk** ability to *unweld* doors
- Fixed HardPat's head hitbox while firing minigun or multiple rockets.
- ScrnZedPack.ini: `bCommandoRevealsStalkers=true` by default (you can still change it)
- ScrnZedPack.ini: added `bLegacyHusk` and `bLegacyFleshpound`
- Legacy Fleshpound starts raging immediately after taking enough damage, while the new one tries to attack the player first if the latter is in melee range.
- **Grittier Fleshpound** always has the new behaviour, regardless of the `bLegacyFleshpound` setting.
- The New FP behaviour was hardcoded since v9.69.39. Now, it is configurable.
- The New **Husk** has the same fireballs as the Grittier Husk, but the former fires only one at a time.
- New Husk fireballs have collision and can hit players or zeds. Legacy fireballs rely on the splash damage only.
- **Grittier Scrake** unstuns from 150+ explosive damage. Don't nade Scrakes!
- **Grittier Scrake** no longer has the slomo rage exploit.
- **Jason** code cleanup.

## v9.71
- Pat dead body stays longer on the map
- SC/FP dead bodies stay longer at high quality physics settings.

## v9.70.12
### Hard Pat
- lowered charging minigun speed multiplier (x2.3 => x1.75)
- always charges player with minigun after the final healing (previously, it was 40% chance)
- when firing multiple rockers, reduced the splash radius of subsequent rockets by 20%

## v9.69.50
-- **Husk** and **Tesla Husk** bounty raised to 35 (up from 17 and 25, respectively) to match `ScrnBalance.MarkZedBounty`. The original bounty was ridiculously low. For instance Siren has 25.

## v9.69.45
- Enhanced headshot detection (again).
- New config option `bHeadshotSrvFixAttackAndMove` - fixes headshot detection if the zed is attacking while keep moving. Enabled by default.
- `bHeadshotSrvAnim` replaced by `bHeadshotSrvFixWalk`. The latter does the same but has a more meaningful name.
- Fixed a warning: "PlayAnim: Sequence 'Jump' not found for mesh 'Patriarch_Freak'"
- Fixed a network replication bug where sometimes a decapitated **Bloat** kept his head client-side.

## v9.69.40
- Added `bCommandoRevealsStalkers` config option for Commando to reveal Stalkers for all teammates (like in KF2)
- bCommandoRevealsStalkers does not affect Ghosts
- Refactored Stalker and Ghost code

## v9.69.39
- Restored the original **Circus Husk** (Dancing Robot) - community request
- Improved headshot detection for jumping/falling zeds on dedicated servers
- Fixed an exploit when Fleshpound did not rage when dealing a massive damage during attack animation.
- Now, FP rages immediately after finishing the attack animation (on Suicidal and HoE)

## v9.69.38
- Fixed a network replication bug where sometimes decapitated zeds kept their heads client-side

## v9.69.11 - POST-MORTEM UPDATE

- **Husk** cannot shoot while falling, dying, or evading other Husk's fireball (by [NikC-])
- **Siren** stops screaming immediately after dying (by [NikC-])
- **Crawler** cannot attack more than once per second. That fixes instant-kill issues where Crawlers were hitting
  again and again by jumping off each other's back.
- **HardPat** gets 33% damage resistance from Flare iDoT
- **HardPat** gets 25% damage resistance from melee body hits (no resistance to head hits)
- Fixed **FleshPound** dealing insane amount of damage when enraged while performing a hit (thanks [Joe])
- **TeslaHusk** now uses energy on repairing FP/FFP/TH head too. Previously, TH used energy to repair body health only,
  while the head was repaired for "free". On HoE, a fully charged TH can repair up to 3500hp, or 1750 body + 1750 head
  if the head is severely damaged. In previous versions, TH could repair 3500hp body + 3500hp head.
- **TeslaHusk** energy restore rate lowered by 25%. Previously, it took 10s to restore full energy up from 0. Now, it
  takes 12.5s.
- Fixed an issue where sometimes **TeslaHusk** could repair multiple targets in a raw, bypassing the cooldown timer.


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
