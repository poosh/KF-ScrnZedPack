class ZedBaseBoss extends ZombieBoss
abstract;

var class<ZedAvoidArea> AvoidAreaClass;
var ZedAvoidArea AvoidArea;

var bool bEndGameBoss;  // is this the end-game boss or just spawned mid-game
var transient int NumPlayersSurrounding;
var float RadialRange;
var int RadialDamage;
var transient int ClawDamageIndex;
var transient vector ReferenceDir;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( ROLE==ROLE_Authority ) {
        SyringeCount = 3; // no healing for mid-game bosses
        Health *= 0.75; // less hp for mid-game bosses
        RadialDamage *= DifficultyDamageModifer();

        AvoidArea = Spawn(AvoidAreaClass,self);
        if ( AvoidArea != none )
            AvoidArea.InitFor(Self);
    }

    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);

    if( AvoidArea != none )
        AvoidArea.Destroy();

    super.Destroyed();
}

function bool MakeGrandEntry()
{
    bEndGameBoss = true;
    SyringeCount = 0; // restore healing for end-game boss
    Health = HealthMax; // restore original hp
    return Super.MakeGrandEntry();
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    if( AvoidArea != none ) {
        AvoidArea.Destroy();
        AvoidArea = none;
    }
    Super(KFMonster).Died(Killer,damageType,HitLocation);
    if ( bEndGameBoss )
        KFGameType(Level.Game).DoBossDeath();
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, vect(0,0,0));
}

function bool IsHeadShotNoShotAnim(vector HitLoc, vector ray, float AdditionalScale)
{
    local bool bResult, bWasShotAnim;

    bWasShotAnim = bShotAnim;
    if (bShotAnim && Level.NetMode == NM_DedicatedServer && Physics == PHYS_Walking && !bIsCrouched) {
        // temporarily disable bShotAnim to force bUseAltHeadShotLocation
        bShotAnim = false;
    }
    bResult = class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, vect(0,0,0));
    bShotAnim = bWasShotAnim;
    return bResult;
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    local float DamagerDistSq;
    local float UsedPipeBombDamScale;
    local bool bDidRadialAttack;
    local Pawn OldEnemy;
    local KFMonsterController MC;

    MC = KFMonsterController(Controller);
    OldEnemy = Controller.Enemy;

    if ( CanRadialAttack() ) {
        bDidRadialAttack = true;
        GotoState('RadialAttack');
    }

    bOnlyDamagedByCrossbow = bOnlyDamagedByCrossbow && class<DamTypeCrossbow>(DamType) != none;

    // Scale damage from the pipebomb down a bit if lots of pipe bomb damage happens
    // at around the same times. Prevent players from putting all thier pipe bombs
    // in one place and owning the patriarch in one blow.
    if ( class<DamTypePipeBomb>(DamType) != none ) {
       UsedPipeBombDamScale = FMax(0,(1.0 - PipeBombDamageScale));
       PipeBombDamageScale += 0.075;
       if( PipeBombDamageScale > 1.0 )
           PipeBombDamageScale = 1.0;
       Damage *= UsedPipeBombDamScale;
    }

    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);

    if( Health <= 0 )
        return;

    if ( KFMonster(InstigatedBy) != none ) {
        // prevent zeds from attacking their daddy
        if ( InstigatedBy.Controller.Enemy == self && KFMonsterController(InstigatedBy.Controller) != none ) {
            KFMonsterController(InstigatedBy.Controller).ChangeEnemy(OldEnemy, InstigatedBy.Controller.CanSee(OldEnemy));
        }
        // and daddy from attacking his children
        if ( MC.Enemy == InstigatedBy ) {
            MC.ChangeEnemy(OldEnemy, MC.CanSee(OldEnemy));
        }
    }

    if( Level.TimeSeconds - LastDamageTime > 10 ) {
        ChargeDamage = 0;
    }
    else {
        LastDamageTime = Level.TimeSeconds;
        ChargeDamage += Damage;
    }

    if( InstigatedBy != none && InstigatedBy.IsPlayerPawn() && ShouldChargeFromDamage() && ChargeDamage > 200 ) {
        // If someone close up is shooting us, just charge them
        DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
        if( DamagerDistSq < 490000 ) {
            SetAnimAction('transition');
            ChargeDamage=0;
            LastForceChargeTime = Level.TimeSeconds;
            GoToState('Charging');
            return;
        }
    }

    if( !bDidRadialAttack && NeedHealing() && ShouldKnockDownFromDamage() ) {
        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('KnockDown');
        HandleWaitForAnim('KnockDown');
        MC.bUseFreezeHack = True;
        GoToState('KnockDown');
    }
}

simulated function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
    super.PlayDyingAnimation(DamageType, HitLoc);
    KarmaParamsSkel(KParams).bKImportantRagdoll = true;
}

function bool CanRadialAttack()
{
    local KFHumanPawn P;

    if ( Level.Game.GameDifficulty < 4 )
        return false;  // no radial attack on Normal

    if ( Level.TimeSeconds < LastMeleeExploitCheckTime )
        return false;
    LastMeleeExploitCheckTime = Level.TimeSeconds + 0.5 + frand();
    NumPlayersSurrounding = 0;
    NumLumberJacks = 0;
    NumNinjas = 0;

    foreach CollidingActors(class'KFHumanPawn', P, 150, Location) {
        if ( P.Health <= 0 )
            continue;

        NumPlayersSurrounding++;
        if( KFMeleeGun(P.Weapon) != none ) {
            if( Axe(P.Weapon) != none || Chainsaw(P.Weapon) != none ) {
                NumLumberJacks++;
            }
            else {
                NumNinjas++;
            }
        }
    }
    return NumPlayersSurrounding >= 3;
}

function bool NeedHealing()
{
    return SyringeCount < 3 && Health > 0 && Health < HealingLevels[SyringeCount];
}

function bool ShouldKnockDownFromDamage()
{
    return true;
}

function CheckBuddySquads()
{
    if ( bEndGameBoss && KFGameType(Level.Game).FinalSquadNum <= SyringeCount ) {
       KFGameType(Level.Game).AddBossBuddySquad();
    }
}

function GotoNextState()
{
    if ( NeedHealing() ) {
        GotoState('Escaping');
    }
    else if ( Health > 0 ) {
        GotoState('');
    }
}

state RadialAttack
{
    function BeginState()
    {
        super.BeginState();

        // there are two ClawDamageTarget() calls during RadialAttack animation
        // 0. Hit targets on the right
        // 1. Hit targets on the left
        ClawDamageIndex = 0;
        ReferenceDir = vector(Rotation);
    }

    function EndState()
    {
        super.EndState();

        LastMeleeExploitCheckTime = Level.TimeSeconds + 5.0 + 5.0*frand();
    }

    function bool CanRadialAttack()
    {
        return false;
    }

    function bool ShouldKnockDownFromDamage()
    {
        return false;
    }

    function ClawDamageTarget()
    {
        local Actor OldTarget;
        local float OldMeleeRange;
        local int UsedMeleeDamage;
        local Pawn P;
        local bool bPlayer;
        local bool bDamagedSomeone;
        local float ZedTimePossibility;
        local vector PlayerDir, LeftDir;
        local float FrontCos, LeftCos;

        OldTarget = Controller.Target;
        OldMeleeRange = MeleeRange;
        CurrentDamtype = ZombieDamType[0];

        foreach VisibleCollidingActors(class'Pawn', P, RadialRange) {
            if ( P == self )
                continue;
            PlayerDir = Normal(P.Location - Location);
            FrontCos = ReferenceDir dot PlayerDir;
            if ( abs(FrontCos) < 0.9 ) {
                // not directly in front or back. First hit to the right, second - to the left.
                LeftDir = ReferenceDir cross vect(0,0,1);
                LeftCos = PlayerDir dot LeftDir;
                if ( (LeftCos > 0) != (ClawDamageIndex == 1) )
                    continue;
            }
            bPlayer = P.Health > 0 && P.IsPlayerPawn();
            Controller.Target = P;
            MeleeRange = RadialRange;
            UsedMeleeDamage = RadialDamage * (0.6 + 0.4*frand());
            if ( MeleeDamageTarget(UsedMeleeDamage, damageForce * Normal(P.Location - Location)) ) {
                bDamagedSomeone = true;
                if ( bPlayer ) {
                    ZedTimePossibility += 0.3;
                }
            }
        }

        Controller.Target = OldTarget;
        MeleeRange = OldMeleeRange;

        if ( bDamagedSomeone ) {
            KFGameType(Level.Game).DramaticEvent(ZedTimePossibility);
            PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);
        }
        ++ClawDamageIndex;
    }

Begin:
    // Don't let the zed move and play the radial attack
    bShotAnim = true;
    Acceleration = vect(0,0,0);
    SetAnimAction('RadialAttack');
    KFMonsterController(Controller).bUseFreezeHack = True;
    HandleWaitForAnim('RadialAttack');
    Sleep(GetAnimDuration('RadialAttack'));
    GotoNextState();
}

state FireMissile
{
    // Pat fires rocket on AnimEnd() - prevent hit animations from triggering it
    function bool HitCanInterruptAction()
    {
        return false;
    }

    function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
    {
        return IsHeadShotNoShotAnim(HitLoc, ray, AdditionalScale);
    }
}

state FireChaingun
{
    function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
    {
        return IsHeadShotNoShotAnim(HitLoc, ray, AdditionalScale);
    }
}

state KnockDown // Knocked
{
    function bool ShouldKnockDownFromDamage()
    {
        return false;
    }
}

State Escaping
{
    function BeginState()
    {
        super.BeginState();
        CheckBuddySquads();
    }

    function bool ShouldKnockDownFromDamage()
    {
        return false;
    }
}

State ZombieDying
{
    // Don't shorten the LifeSpan after landed
    function KVelDropBelow() {}
}


defaultproperties
{
    ControllerClass=class'ZedControllerBoss'
    // BurnEffect=Class'ScrnMonsterFlame'
    AvoidAreaClass=class'ZedAvoidArea'
    RadialRange=150
    RadialDamage=70
    RagdollLifeSpan=120

    // not sure if DoubleJump or Dodge anims are used, but Pat doesn't have "Jump" anim
    DoubleJumpAnims(0)="JumpTakeOff"
    DoubleJumpAnims(1)="JumpTakeOff"
    DoubleJumpAnims(2)="JumpTakeOff"
    DoubleJumpAnims(3)="JumpTakeOff"
    DodgeAnims(0)="JumpTakeOff"
    DodgeAnims(1)="JumpTakeOff"
    DodgeAnims(2)="JumpTakeOff"
    DodgeAnims(3)="JumpTakeOff"
}
