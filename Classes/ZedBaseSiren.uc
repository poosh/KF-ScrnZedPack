class ZedBaseSiren extends ZombieSiren
abstract;

// prevents scream canceling. Siren screams at least once per ForceScreamTime despire target is withing melee range
var float ForceScreamTime;

var transient float MeleeRangeSq, ScreamRadiusSq, MoveScreamRadiusSq;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    class'ScrnZedFunc'.static.ZedBeginPlay(self);
    MeleeRangeSq = (MeleeRange + CollisionRadius) ** 2;
    ScreamRadiusSq = ScreamRadius ** 2;
    MoveScreamRadiusSq = (ScreamRadius * 0.25) ** 2;
    ForceScreamTime += Level.TimeSeconds;

    if ( Role == ROLE_Authority ) {
        if ( Level.Game.GameDifficulty < 5 ) {
            // lower vortex pull on Hard and below
            ScreamForce *= 0.05 * Level.Game.GameDifficulty;
        }
    }
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);
    super.Destroyed();
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, vect(0,0,0));
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if ( DamType == ScreamDamageType )
        return;  // immune to scream

    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

function RemoveHead()
{
    Super(KFMonster).RemoveHead();
    KilledBy(LastDamagedBy);
}

function RangedAttack(Actor A)
{
    local float DistSq;

    if ( bShotAnim )
        return;

    DistSq = VSizeSquared(A.Location - Location);

    if ( Physics == PHYS_Swimming ) {
        SetAnimAction('Claw');
        bShotAnim = true;
    }
    else if ( DistSq < MeleeRangeSq && (bDecapitated || bZapped || Level.TimeSeconds < ForceScreamTime) ) {
        bShotAnim = true;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( DistSq <= ScreamRadiusSq && !bDecapitated && !bZapped ) {
        bShotAnim = true;
        SetAnimAction('Siren_Scream');
        if( DistSq < MoveScreamRadiusSq ) {
            // Only stop moving if we are close
            Controller.bPreparingMove = true;
            Acceleration = vect(0,0,0);
        }
        else {
            Acceleration = AccelRate * Normal(A.Location - Location);
        }
    }
}

simulated function SpawnTwoShots()
{
    if ( bDecapitated || bZapped )
        return;

    ForceScreamTime = Level.TimeSeconds + default.ForceScreamTime;
    DoShakeEffect();
    if( Controller!=None && KFDoorMover(Controller.Target)!=None )
        Controller.Target.TakeDamage(ScreamDamage*0.6, Self, Location, vect(0,0,0), ScreamDamageType);
    else
        HurtRadius(ScreamDamage, ScreamRadius, ScreamDamageType, ScreamForce, Location);
}

// fixed instigator in calling TakeDamage()
// fixed pull effect
function HurtRadius(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum,
        vector HitLocation )
{
    local actor Victim;
    local float damageScale, dist;
    local vector dir;
    local int UsedDamageAmount;
    local vector UsedMomentum;

    if( bHurtEntry )
        return;

    bHurtEntry = true;
    foreach VisibleCollidingActors( class 'Actor', Victim, DamageRadius, HitLocation ) {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        // Or Karma actors in this case. Self inflicted Death due to flying chairs is uncool for a zombie of your stature.
        if ( Victim != self && !Victim.IsA('FluidSurfaceInfo') && !Victim.IsA('ExtendedZCollision') ) {
            dir = Victim.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;

            damageScale = 1.0 - FMax(0.0, (dist - Victim.CollisionRadius)/DamageRadius);
            UsedDamageAmount = damageScale * DamageAmount;
            UsedMomentum = damageScale * Momentum * dir;

            if ( Victim.IsA('Pawn') ) {
                if ( Victim.IsA('KFMonster') ) {
                    UsedMomentum = vect(0, 0, 0);  // don't pull the vortex crap on zeds
                    UsedDamageAmount = 1;  // just a little bit to pass it into NetDamage()
                }
                else {
                    UsedMomentum = -UsedMomentum;  // vortex pull effect
                }
            }
            else if ( Victim.IsA('KFDoorMover') ) {
                UsedDamageAmount *= 0.6;
            }
            else if ( Victim.IsA('KFGlassMover') ) {
                UsedDamageAmount = 100000; // Siren always shatters glass
            }

            Victim.TakeDamage(UsedDamageAmount, self,
                    Victim.Location - 0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * dir,
                    UsedMomentum, DamageType);

            if ( Vehicle(Victim) != None && Vehicle(Victim).Health > 0)
                Vehicle(Victim).DriverRadiusDamage(UsedDamageAmount, DamageRadius, Controller, DamageType, Momentum,
                    HitLocation);
        }
    }
    bHurtEntry = false;
}


defaultproperties
{
    ControllerClass=class'ZedControllerSiren'
    ScreamForce=150000  // made positive (push), invert for pawns, 0 for zeds
    ScreamDamage=6 // lowered scream damage to compensate fixed vortex pull
    ForceScreamTime=7
    Mass=150
}
