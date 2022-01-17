// used for Tesla Husk self-destruct explosion on decapitation
class TeslaHuskEMPCharge extends Nade;

var() class<Emitter> ExplosionEffect;
var() float ZedDamageScale, FPDamageScale;
var() float PlayerDamageRadius;
var class<KFWeaponDamageType> SelfDestructDamType;

var Pawn Killer;
var Controller KillerController;

function Timer()
{
    if ( bHidden )
        Destroy();
    else if ( Instigator != none && Instigator.Health > 0 )
        Explode(Location, vect(0,0,1));
    else
        Disintegrate(Location, vect(0,0,1));
}


// don't get destroyed by a Siren
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local PlayerController LocalPlayer;

    bHasExploded = True;
    BlowUp(HitLocation);

    PlaySound(ExplodeSounds[rand(ExplodeSounds.length)],,2.0);

    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(ExplosionEffect,,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    if ( Instigator != none ) {
        // blow up the TeslaHusk
        Instigator.TakeDamage(Instigator.Health * 4, Killer, Instigator.Location, vect(0,0,1), SelfDestructDamType);
    }

    Destroy();
}

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local Pawn DamageDealer;
    local Controller DamageDealerC;
    local actor Victim;
    local KFMonster M;
    local KFPawn KFP;
    local vector dir;
    local float damageScale, dist;
    local int ActualDamage;

    if ( Instigator == none || Instigator.Health <= 0 )
        return;  // deactivate self explosion on death

    if ( bHurtEntry )
        return;
    bHurtEntry = true;

    // prevent TeslaHusk to block traces
    Instigator.SetCollision(false, false);

    foreach CollidingActors (class 'Actor', Victim, DamageRadius, HitLocation) {
        if ( Victim == self || Victim == Instigator || Victim == Hurtwall || Victim.Role != ROLE_Authority
                || Victim.IsA('FluidSurfaceInfo') || Victim.IsA('ExtendedZCollision') )
        {
            continue;
        }

        M = KFMonster(Victim);
        KFP = KFPawn(Victim);
        // TeslaHusk instigate damage to humans - to prevent friendly fire scale apply
        // Otherwise use Killer as instigator to count kill score
        if ( KFP == none && KillerController != none ) {
            DamageDealer = Killer;
            DamageDealerC = KillerController;
        }
        else {
            DamageDealer = Instigator;
            DamageDealerC = Instigator.Controller;
        }
        if ( DamageDealer == none ) {
            Victim.SetDelayedDamageInstigatorController(DamageDealerC);
        }

        dir = Victim.Location - HitLocation;
        dist = fmax(1.0, VSize(dir));
        dir = dir / dist;
        damageScale = 1.0 - fmax(0, (dist - Victim.CollisionRadius - Instigator.CollisionRadius) / DamageRadius);
        if ( M != none ) {
            if ( M.IsA('ZombieFleshpound') || M.IsA('FemaleFP') ) {
                damageScale *= FPDamageScale;
            }
            else {
                damageScale *= ZedDamageScale;
            }
            damageScale *= M.GetExposureTo(HitLocation);
        }
        else if ( KFP != none ) {
            if ( dist > PlayerDamageRadius )
                continue;
            damageScale = 1.0 - fmax(0, (dist - Victim.CollisionRadius - Instigator.CollisionRadius) / PlayerDamageRadius);
            damageScale *= KFP.GetExposureTo(HitLocation);
        }

        ActualDamage = damageScale * DamageAmount;
        if ( ActualDamage <= 0 )
            continue;

        Victim.TakeDamage(ActualDamage, DamageDealer,
                Victim.Location - 0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * dir,
                damageScale * Momentum * dir,
                DamageType);

        if ( Vehicle(Victim) != None && Vehicle(Victim).Health > 0 ) {
            Vehicle(Victim).DriverRadiusDamage(ActualDamage, DamageRadius, DamageDealerC, DamageType, Momentum, HitLocation);
        }
    }

    Instigator.SetCollision(true, true);
    bHurtEntry = false;
}


defaultproperties
{
    ShrapnelClass=none

    ExplodeSounds(0)=Sound'KF_FY_ZEDV2SND.Fire.WEP_ZEDV2_Secondary_Fire_S'
    ExplodeSounds(1)=Sound'KF_FY_ZEDV2SND.Fire.WEP_ZEDV2_Secondary_Fire_S'
    ExplodeSounds(2)=Sound'KF_FY_ZEDV2SND.Fire.WEP_ZEDV2_Secondary_Fire_S'

    DrawType=DT_None

    bCollideActors=false
    bBlockActors=false
    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=false
    bBlockHitPointTraces=false

    MyDamageType=class'DamTypeEMP'
    SelfDestructDamType=class'DamTypeEMPSelfDestruct'
    ExplosionEffect=class'KFMod.ZEDMKIISecondaryProjectileExplosion'

    Speed=0
    Physics=PHYS_None

    Damage=50  // replaced by TeslaHusk.EmpDamagePerEnergy
    DamageRadius=400 // 8 meters
    PlayerDamageRadius=300 // 6 meters. Lower damage radius vs/ players to match ExplosionEffect
    ZedDamageScale=20.0
    FPDamageScale=40.0
}
