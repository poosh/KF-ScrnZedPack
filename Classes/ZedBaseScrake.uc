class ZedBaseScrake extends ZombieScrake
abstract;

var int SawDamage;
var int OriginalMeleeDamage; // default melee damage, adjusted by game's difficulty
var transient bool bFlippedOver, bWasFlippedOver;
var transient float LastFlipOverTime;
var float FlipOverDuration;
var name ChargeAnim;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    OriginalMeleeDamage = MeleeDamage;
    // fixed bug when saw damage didn't scale by diufficulty
    SawDamage = Max((DifficultyDamageModifer() * SawDamage),1);
    FlipOverDuration = GetAnimDuration('KnockDown');
    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);
    super.Destroyed();
}

simulated function PostNetReceive()
{
    // Slowmo burn bug! Considered a feature.
    if (bCharging) {
        MovementAnims[0] = ChargeAnim;
    }
    else if (!bCrispified && !bBurnified) {
        MovementAnims[0] = default.MovementAnims[0];
    }
}

simulated function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    if (bFlippedOver && Level.TimeSeconds > LastFlipOverTime + FlipOverDuration)
        bFlippedOver = false;
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, vect(0,0,0));
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum, optional int HitIdx )
{
    super.PlayHit(Damage, InstigatedBy, HitLocation, damageType, Momentum, HitIdx);

    if (bFlippedOver && Level.TimeSeconds - LastFlipOverTime > 0.5 && Damage < (Default.Health / 1.5) && Health > 0
            && ShouldDamageUnstun(Damage, damageType)) {
        Unstun();
        RangedAttack(InstigatedBy);
    }
}

simulated function bool HitCanInterruptAction()
{
    return !bFlippedOver;
}

simulated function ProcessHitFX()
{
    super.ProcessHitFX();

    // make sure the head is removed from decapitated zeds
    if (bDecapitated && !bHeadGibbed && Health > 0) {
        DecapFX(GetBoneCoords(HeadBone).Origin, rot(0,0,0), false, true);
    }
}

function bool CanAttack(Actor A)
{
    return class'ScrnZedFunc'.static.CanAttack(self, A);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
    return class'ScrnZedFunc'.static.MeleeDamageTarget(self, hitdamage, pushdir);
}

function bool CanRestun()
{
    return true;
}

function bool FlipOver()
{
    if (bWasFlippedOver && !CanRestun())
        return false;

    bFlippedOver = class'ScrnZedFunc'.static.FlipOver(self);
    if (bFlippedOver) {
        StunsRemaining = default.StunsRemaining;  // restore the default flich count on stun
        bWasFlippedOver = true;
        LastFlipOverTime = Level.TimeSeconds;
    }
    return bFlippedOver;
}

function bool ShouldDamageUnstun(int Damage, class<DamageType> DamType)
{
    return false;
}

function bool ShouldRage()
{
    local float f;

    f = float(Health) / HealthMax;
    return f < 0.5 || (f < 0.75 &&  Level.Game.GameDifficulty >= 5.0);
}

function Unstun()
{
    if (!bFlippedOver)
        return;

    bShotAnim = false;
    bFlippedOver = false;
    if (ShouldRage()) {
        SetAnimAction(ChargeAnim);
    }
    else {
        SetAnimAction(default.MovementAnims[0]);
    }
    ZedControllerScrake(Controller).GoToState('ZombieHunt');
}

function bool CanGetOutOfWay()
{
    return !bFlippedOver; // can't dodge husk fireballs while stunned
}

State SawingLoop
{
    function RangedAttack(Actor A)
    {
        super.RangedAttack(A);
        if ( bShotAnim ) {
            MeleeDamage = SawDamage;
        }
    }

    function EndState()
    {
        super.EndState();
        MeleeDamage = OriginalMeleeDamage;
    }
}

State ZombieDying
{
    function KVelDropBelow() {
        // Don't shorten the LifeSpan after landed on high physiscs setting
        if (Level.PhysicsDetailLevel != PDL_High) {
            super.KVelDropBelow();
        }
    }
}

defaultproperties
{
    ControllerClass=class'ZedControllerScrake'
    SawDamage=10
    RagdollLifeSpan=30
    ChargeAnim="ChargeF"
}
