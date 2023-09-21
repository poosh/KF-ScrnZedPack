////////////////////////////////////////////////////////////////////////////
// Female Flesh Pound
// A more dainty and gentle fleshpound... pfft! NOT!
// Written by Whisky & Poosh, (Although it's mostly TWI's code in the first place.)
// Scary Ghost's code used with permission.
////////////////////////////////////////////////////////////////////////////

class FemaleFP extends KFMonster;

#exec load obj file=ScrnZedPack_T.utx
#exec load obj file=ScrnZedPack_S.uax
#exec load obj file=ScrnZedPack_A.ukx

var transient bool bChargingPlayer,bClientCharge,bFrustrated;
var transient bool bRageMegaHit;  // superior damage on the first attack after rage
var float RageMegaHitCounter;  // rate time until resetting
var float RageMegaHitDamageMult;
var float Attack1DamageMult, Attack2DamageMult, RageDamageMult;
var float RageEndTime;
var class<ZedAvoidArea> AvoidAreaClass;
var ZedAvoidArea AvoidArea;
var name ChargingAnim;
var float ChargingSpeedMult;
var transient name LastAttackAnim;
var transient float LastAttack3Time;

var() class<VehicleExhaustEffect>    VentEffectClass; // Effect class for the vent emitter
var() VehicleExhaustEffect         VentEffect,VentEffect2; //Dual venting baby!
var() float BlockDamageReduction;
var() vector RotMag;
var() vector RotRate;
var() float RotTime;
var() vector OffsetMag;
var() vector OffsetRate;
var() float OffsetTime;
var() int RageDamageThreshold;
var() vector OnlineHeadshotOffsetCharging;   // Headshot offset for when a zed isn't animating online and charging
var float AttackSpeedMult, HeavyAttackSpeedMult;

replication
{
    reliable if(Role==ROLE_Authority)
        bChargingPlayer;
}


simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( ROLE==ROLE_Authority ) {
        StunsRemaining = fmax(8 - Level.Game.GameDifficulty, 1);

        AvoidArea=Spawn(AvoidAreaClass, self);
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
    StopVenting();

    Super.Destroyed();
}

simulated function PostNetBeginPlay()
{
    EnableChannelNotify(1,1);
    AnimBlendParams(1,1.0,0.0,,SpineBone2);
    super.PostNetBeginPlay();
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if( bClientCharge != bChargingPlayer ) {
        bClientCharge = bChargingPlayer;
        ClientChargingAnims();
    }
}

// This zed has been taken control of. Boost its health and speed
function SetMindControlled(bool bNewMindControlled)
{
    if( bNewMindControlled )
    {
        NumZCDHits++;

        // if we hit him a couple of times, make him rage!
        if( NumZCDHits > 1 )
        {
            if( !IsInState('ChargeToMarker') )
            {
                GotoState('ChargeToMarker');
            }
            else
            {
                NumZCDHits = 1;
                if( IsInState('ChargeToMarker') )
                {
                    GotoState('');
                }
            }
        }
        else
        {
            if( IsInState('ChargeToMarker') )
            {
                GotoState('');
            }
        }

        if( bNewMindControlled != bZedUnderControl )
        {
            SetGroundSpeed(OriginalGroundSpeed * 1.25);
            Health *= 1.25;
            HealthMax *= 1.25;
        }
    }
    else
    {
        NumZCDHits=0;
    }

    bZedUnderControl = bNewMindControlled;
}

// Handle the zed being commanded to move to a new location
function GivenNewMarker()
{
    if( bChargingPlayer && NumZCDHits > 1  )
    {
        GotoState('ChargeToMarker');
    }
    else
    {
        GotoState('');
    }
}

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
    if( Level.TimeSeconds - LastPainAnim < MinTimeBetweenPainAnims )
        return;

    if ( Controller.IsInState('WaitForAnim') )
        return; // Don't interrupt the controller if its waiting for an animation to end

    if( StunsRemaining > 0 && Damage>=100 )
        PlayDirectionalHit(HitLocation);

    LastPainAnim = Level.TimeSeconds;

    if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
        return;

    LastPainSound = Level.TimeSeconds;
    PlaySound(HitSound[0], SLOT_Pain,1.25,,400);
}

//Taken from ScaryGhost's SuperFP.
function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
    if ( super.MeleeDamageTarget(hitdamage, pushdir) ) {
        FFPController(Controller).bHitTarget = true;
        return true;
    }
    return false;
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, vect(0,0,0));
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    local int OldHealth;
    local bool bIsHeadShot;
    local float HeadShotCheckScale;
    local class<KFWeaponDamageType> KFDamType;

    if ( damageType == class'DamTypeVomit' || damageType == class'DamTypeTeslaBeam' )
        return;  // full resistance

    // optimizes typecasting and make code comre compact -- PooSH
    KFDamType = class<KFWeaponDamageType>(damageType);
    oldHealth= Health;

    if ( KFDamType != none ) {
        HeadShotCheckScale = 1.0;
        // Do larger headshot checks if it is a melee attach
        if( class<DamTypeMelee>(damageType) != none )
            HeadShotCheckScale *= 1.25;
        bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), HeadShotCheckScale);

        // She takes less damage to small arms fire (non explosives)
        // Frags and LAW rockets will bring her down way faster than bullets and shells.
        if ( !KFDamType.default.bIsExplosive ) // all explosives: current, future and custom -- PooSH
        {
            // Don't reduce the damage so much if its a high headshot damage weapon
            if( bIsHeadShot && KFDamType.default.HeadShotDamageMult >= 1.5 ) {
                Damage *= 0.75;
            }
            else if ( Level.Game.GameDifficulty >= 5.0 && bIsHeadshot
                && (ClassIsChildOf(KFDamType, class'DamTypeCrossbow')
                    || ClassIsChildOf(KFDamType, class'DamTypeM99SniperRifle')) )
            {
                Damage *= 0.35; // 65% damage reduction from xbow/m99 headshots
            }
            else {
                Damage *= 0.5;
            }
        }
        else if ( !ClassIsChildOf(KFDamType, class'DamTypeLAW') ) {
            Damage *= 1.25;
        }
    }

    // fixes none-reference erros when taking enviromental damage -- PooSH
    if (InstigatedBy == none || KFDamType == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType); // skip NONE-reference error
    else
        super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);

    Damage = OldHealth - Health;

    if ( Health <= 0 ) {
        // Shut off her "Device" when dead
        DeviceGoNormal();
        StopVenting();
    }
    else if ( !bDecapitated && !bChargingPlayer && !bZapped
            && (!bBurnified || bCrispified || bFrustrated || Damage > RageDamageThreshold)
            && (Damage > RageDamageThreshold || Health < HealthMax*0.5
                || (Level.Game.GameDifficulty >= 5.0 && Health < HealthMax*0.75)) )
    {
        // Starts charging if single damage > 300 or health drops below 50% on hard difficulty or below,
        // or health <75% on Suicidal/HoE
        // -- PooSH
        StartCharging();
    }
}

function RangedAttack(Actor A)
{
    if ( bShotAnim || Physics == PHYS_Swimming)
        return;

    if ( CanAttack(A) ) {
        bShotAnim = true;
        SetAnimAction('Claw');
    }
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    StopVenting();
    if( AvoidArea != none ) {
        AvoidArea.Destroy();
        AvoidArea = none;
    }
    super.Died( Killer, damageType, HitLocation );
}

simulated function VentMe()
{
    if ( Level.NetMode == NM_DedicatedServer )
        return;

    if ( VentEffectClass == none )
        return;

    if ( Level.DetailMode < DM_High )
        return;

    if ( VentEffect == none ) {
        VentEffect = Spawn(VentEffectClass, self);
        AttachToBone(VentEffect, 'BODY_Piston_top_Camisa_l');
        VentEffect.SetRelativeRotation(rot(0, 0, 0));
    }
    if ( VentEffect2 == none ) {
        VentEffect2 = Spawn(VentEffectClass, self);
        AttachToBone(VentEffect2, 'BODY_Piston_top_Camisa_r');
    }
}

simulated function StopVenting()
{
    if ( VentEffect != none ) {
        VentEffect.Destroy();
        VentEffect = none;
    }
    if ( VentEffect2 != none ) {
        VentEffect2.Destroy();
        VentEffect2 = none;
    }
}

// Sets the FFP in a berserk charge state until she either strikes her target, or hits timeout
function StartCharging()
{
    local float RageAnimDur;

    if( Health <= 0 ) {
        return;
    }

    bChargingPlayer = true;
    SetAnimAction('Rage_Start');
    Acceleration = vect(0,0,0);
    bShotAnim = true;
    Velocity.X = 0;
    Velocity.Y = 0;
    Controller.GoToState('WaitForAnim');
    KFMonsterController(Controller).bUseFreezeHack = true;
    RageAnimDur = GetAnimDuration('Rage_Start');
    FleshpoundZombieController(Controller).SetPoundRageTimout(RageAnimDur);
    GoToState('BeginRaging');
}

state BeginRaging
{
    ignores StartCharging, SetBurningBehavior;

    // Set the zed to the zapped behavior
    simulated function SetZappedBehavior()
    {
        Global.SetZappedBehavior();
        GoToState('');
    }

    function bool CanGetOutOfWay()
    {
        return false;
    }

    simulated function bool HitCanInterruptAction()
    {
        return false;
    }

    function Tick(float dt)
    {
        Acceleration = vect(0,0,0);

        global.Tick(dt);
    }

Begin:
    Sleep(GetAnimDuration('Rage_Start'));
    GotoState('RageCharging');
}


//Next two States are Scary's Code.
state RageCharging
{
    ignores StartCharging, SetBurningBehavior;
    // Set the zed to the zapped behavior
    simulated function SetZappedBehavior()
    {
        Global.SetZappedBehavior();
           GoToState('');
    }

    function PlayDirectionalHit(Vector HitLoc)
    {
        if( !bShotAnim )
        {
            super.PlayDirectionalHit(HitLoc);
        }
    }

    function bool CanGetOutOfWay()
    {
        return false;
    }

    // Don't override speed in this state
    function bool CanSpeedAdjust()
    {
        return false;
    }

    function BeginState()
    {
        local float DifficultyModifier;

        if( bZapped ) {
            GoToState('');
            return;
        }

        bRageMegaHit = true;
        bChargingPlayer = true;
        OnlineHeadshotOffset = OnlineHeadshotOffsetCharging;
        ClientChargingAnims();

        // Scale rage length by difficulty
        if( Level.Game.GameDifficulty < 4.0 )
            DifficultyModifier = 1.0;
        else if( Level.Game.GameDifficulty < 5.0 )
            DifficultyModifier = 1.25;
        else // Hardest difficulty
            DifficultyModifier = 3.0; // Doubled Fleshpound Rage time for Suicidal and HoE in Balance Round 1

        // Female FP charges ~1.5x longer than a male. Cuz she is a pissed-off cunt
        RageEndTime = Level.TimeSeconds + DifficultyModifier * (7.5 + 9.0*FRand());
        NetUpdateTime = Level.TimeSeconds - 1;
    }

    function EndState()
    {
        bChargingPlayer = false;
        bFrustrated = false;
        OnlineHeadshotOffset = default.OnlineHeadshotOffset;

        FleshPoundZombieController(Controller).RageFrustrationTimer = 0;
        StopVenting();

        if( Health > 0 && !bZapped ) {
            SetGroundSpeed(global.GetOriginalGroundSpeed());
        }
        ClientChargingAnims();
        NetUpdateTime = Level.TimeSeconds - 1;
    }

    function Tick( float dt )
    {
        if ( bShotAnim ) {
            // probably redundant because the server is playing the attack animation and, therefore,
            // does not take OnlineHeadshotOffset into account
            OnlineHeadshotOffset = default.OnlineHeadshotOffset;
        }
        else {
            if( !bZedUnderControl && Level.TimeSeconds > RageEndTime ) {
                GoToState('');
            }
            else {
                OnlineHeadshotOffset = OnlineHeadshotOffsetCharging;
                SetGroundSpeed(GetOriginalGroundSpeed());
                if (!bRageMegaHit) {
                    RageMegaHitCounter -= dt;
                    if ( RageMegaHitCounter <= 0 )
                        bRageMegaHit = true;
                }
            }
        }

        global.Tick(dt);
    }

    simulated event SetAnimAction(name NewAction) {
        global.SetAnimAction(NewAction);

        if ( bShotAnim ) {
            if ( AnimAction == 'Attack3' ) {
                SetGroundSpeed(GetOriginalGroundSpeed() * HeavyAttackSpeedMult);
            }
            else {
                SetGroundSpeed(GetOriginalGroundSpeed() * AttackSpeedMult);
            }
        }
    }

    simulated function float GetOriginalGroundSpeed()
    {
        return OriginalGroundSpeed * ChargingSpeedMult;
    }

    function Bump( Actor Other )
    {
        local float RageBumpDamage;
        local KFMonster KFMonst;

        KFMonst = KFMonster(Other);

        // Hurt/Kill enemies that we run into while raging
        if( !bShotAnim && KFMonst!=None && KFMonst.Health>0 && !SameSpeciesAs(self) )
        {
            // Random chance of doing obliteration damage
            if( FRand() < 0.4 )
            {
                 RageBumpDamage = 501;
            }
            else
            {
                 RageBumpDamage = 450;
            }

            RageBumpDamage *= KFMonst.PoundRageBumpDamScale;

            Other.TakeDamage(RageBumpDamage, self, Other.Location, Velocity * Other.Mass, class'DamTypePoundCrushed');
        }
        else Global.Bump(Other);
    }

    function bool MeleeDamageTarget(int hitdamage, vector pushdir)
    {
        local bool RetVal,bWasEnemy, bCalmDown;
        local float oldEnemyHealth;
        local bool bAttackingHuman;
        local KFPawn KFP;


        //Only rage again if he was attacking a human
        KFP = KFPawn(Controller.Target);
        bAttackingHuman = KFP != none;
        if (bAttackingHuman)
            oldEnemyHealth = KFP.Health;

        bWasEnemy = (Controller.Target==Controller.Enemy);
        if ( bRageMegaHit )
            hitdamage *= RageMegaHitDamageMult;
        else
            hitdamage *= RageDamageMult;

        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage, pushdir*3);

        if ( bAttackingHuman || bWasEnemy ) {
            bRageMegaHit = false; //she had a chance to do a greater damage. If she missed - her fault
            RageMegaHitCounter = default.RageMegaHitCounter;
        }

        // On Hard and below she always calms down, no matter of was hit successful or not
        // On Suicidal she calms down after successfull hit
        // On HoE she calms down only if killed a player.
        if ( Level.Game.GameDifficulty < 5 || !bAttackingHuman ) {
            bCalmDown = true;
        }
        else {
            bCalmDown = RetVal && bWasEnemy && (KFP == none || KFP.Health <= 0
                    || (Level.Game.GameDifficulty < 7.0 && KFP.Health < oldEnemyHealth));
        }

        if (bCalmDown) {
            GoToState('');
        }
        else {
            SetGroundSpeed(OriginalGroundSpeed * ChargingSpeedMult);
        }

        return RetVal;
    }
}

// XXX: do we need this state?
state ChargeToMarker extends RageCharging
{
}

simulated function ClientChargingAnims()
{
    if ( bZapped )
        return;

    if( bChargingPlayer ) {
        MovementAnims[0]=ChargingAnim;
    }
    else {
        MovementAnims[0]=default.MovementAnims[0];
    }

    if ( Level.NetMode != NM_DedicatedServer ) {
        if( bChargingPlayer ) {
            DeviceGoRed();
        }
        else {
            DeviceGoNormal();
            StopVenting();
        }
    }
}

simulated function UnSetZappedBehavior()
{
    super.UnSetZappedBehavior();
    ClientChargingAnims();
}

function ClawDamageTarget()
{
    local vector PushDir;
    local KFHumanPawn HumanTarget;
    local KFPlayerController HumanTargetController;
    local float UsedMeleeDamage;

    UsedMeleeDamage = MeleeDamage * (0.95 + 0.10*frand());

    if( LastAttackAnim == 'Attack1' ) {
        UsedMeleeDamage *= Attack1DamageMult;
    }
    else if( LastAttackAnim == 'Attack2' ) {
        // Reduce the melee damage for anims with repeated attacks, since it does repeated damage over time
        UsedMeleeDamage *= Attack2DamageMult;
    }
    else if ( LastAttackAnim == 'Attack3' ) {
        if (Level.TimeSeconds - LastAttack3Time < 1.0) {
            // there is a bug in animation notifies that calls ClawDamageTarget() twice per Attack3 animation
            // (copy from Attack2). Attack3 should damage only once
            // TODO: remove the redundant notify from the animation package
            return;
        }
        LastAttack3Time = Level.TimeSeconds;
    }

    if(Controller!=none && Controller.Target!=none)
    {
        //calculate based on relative positions
        PushDir = (damageForce * Normal(Controller.Target.Location - Location));
    }
    else
    {
        //calculate based on way Monster is facing
        PushDir = damageForce * vector(Rotation);
    }
    if ( MeleeDamageTarget( UsedMeleeDamage, PushDir))
    {
        HumanTarget = KFHumanPawn(Controller.Target);
        if( HumanTarget!=None )
            HumanTargetController = KFPlayerController(HumanTarget.Controller);
        if( HumanTargetController!=None )
            HumanTargetController.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
        PlaySound(MeleeAttackHitSound, SLOT_Interact, 1.25);
    }
}

function SpinDamage(actor Target)
{
    local vector HitLocation;
    local Float dummy;
    local float DamageAmount;
    local vector PushDir;
    local KFHumanPawn HumanTarget;

    if(target==none)
        return;

    PushDir = (damageForce * Normal(Target.Location - Location));
    damageamount = (SpinDamConst + rand(SpinDamRand) );

    HumanTarget = KFHumanPawn(Target);
    if ( HumanTarget != none ) {
        // FLING DEM DEAD BODIEZ!
        if ( HumanTarget.Health <= DamageAmount ) {
            HumanTarget.RagDeathVel *= 3;
            HumanTarget.RagDeathUpKick *= 1.5;
        }

        if (HumanTarget.Controller != none)
            HumanTarget.Controller.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

        //TODO - line below was KFPawn. Does this whole block need to be KFPawn, or is it OK as KFHumanPawn?
        HumanTarget.TakeDamage(DamageAmount, self ,HitLocation,pushdir, class 'KFmod.ZombieMeleeDamage');

        if ( HumanTarget.Health <=0 ) {
            HumanTarget.SpawnGibs(rotator(pushdir), 1);
            HumanTarget.HideBone(HumanTarget.GetClosestBone(HitLocation,Velocity,dummy));
        }
    }
    else if ( Target.IsA('KFDoorMover') ) {
        Target.TakeDamage(DamageAmount , self ,HitLocation,pushdir, class 'KFmod.ZombieMeleeDamage');
        PlaySound(MeleeAttackHitSound, SLOT_Interact, 1.25);
    }
}

simulated function int DoAnimAction( name AnimName )
{
    if( AnimName=='Attack1' || AnimName=='Attack2' || AnimName=='Attack3' )
    {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);
        return 1;
    }
    return Super.DoAnimAction(AnimName);
}

simulated event SetAnimAction(name NewAction)
{
    local int meleeAnimIndex;

    if( NewAction=='' )
        return;

    if(NewAction == 'Claw') {
        if ( bChargingPlayer ) {
            if ( bRageMegaHit ) {
                meleeAnimIndex = 2; // Attack3
            }
            else {
                meleeAnimIndex = rand(3);
            }
        }
        else {
            meleeAnimIndex = rand(2);  // do not use Attack3 if not enraged
        }
        NewAction = meleeAnims[meleeAnimIndex];
        CurrentDamtype = ZombieDamType[meleeAnimIndex];
        LastAttackAnim = NewAction;
    }
    else if( NewAction == 'DoorBash' ) {
        CurrentDamtype = ZombieDamType[Rand(3)];
    }
    ExpectingChannel = DoAnimAction(NewAction);

    if( AnimNeedsWait(NewAction) )
    {
        bWaitForAnim = true;
    }

    if( Level.NetMode!=NM_Client )
    {
        AnimAction = NewAction;
        bResetAnimAct = True;
        ResetAnimActTime = Level.TimeSeconds+0.3;
    }
}

// The animation is full body and should set the bWaitForAnim flag
simulated function bool AnimNeedsWait(name TestAnim)
{
    return TestAnim == 'Rage_Start' || TestAnim == 'DoorBash';
}

simulated function Tick(float dt)
{
    super.Tick(dt);

    // Keep the flesh pound moving toward her target when attacking
    if( Role == ROLE_Authority && bShotAnim) {
        if( LookTarget!=None ) {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }
    }
}

// simulated function DebugHead()
// {
//     local coords C;
//     local vector HeadLoc;
//     local float Radius;

//     if ( Level.NetMode == NM_DedicatedServer || Health <= 0 )
//         return;

//     Radius = HeadRadius * HeadScale;

//     // based on head bone
//     C = GetBoneCoords(HeadBone);
//     HeadLoc = C.Origin + (HeadHeight * HeadScale * C.XAxis);
//     DrawDebugSphere(HeadLoc, Radius, 16, 0, 100, 255);

//     // based on OnlineHeadshotOffset
//     HeadLoc = Location + (OnlineHeadshotOffset >> Rotation);
//     Radius *= OnlineHeadshotScale;
//     DrawDebugSphere(HeadLoc, Radius, 16, 255, 0, 0);
// }

function bool FlipOver()
{
    Return False;
}

function bool SameSpeciesAs(Pawn P)
{
    return P.IsA('ZombieFleshPound') || P.IsA('FemaleFP');
}

simulated function DeviceGoRed()
{
    Skins[3]=Shader'ScrnZedPack_T.FFPLights_Red_shader';
    Skins[1]=Combiner'ScrnZedPack_T.FFP_Metal_R_cmb';
}

simulated function DeviceGoNormal()
{
    Skins[3]=Shader'ScrnZedPack_T.FFPLights_Yellow_shader';
    Skins[1]=Combiner'ScrnZedPack_T.FFP_Metal_cmb';
}

simulated function SetBurningBehavior()
{
    if ( !bChargingPlayer ) {
        super.SetBurningBehavior();
    }
}

//Metal does not burn like flesh!
simulated function ZombieCrispUp()
{
    bAshen = true;
    bCrispified = true;

    SetBurningBehavior();

    if ( Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
    {
        Return;
    }

    Skins[4]=Combiner'PatchTex.Common.BurnSkinEmbers_cmb';

}

simulated function PlayDirectionalDeath(Vector HitLoc)
{
    if( Level.NetMode==NM_DedicatedServer )
    {
        SetCollision(false, false, false);
        return;
    }

    // lame hack, but it is better than leaving her staying for those, who have no karma data
    // -- PooSH
    SetCollision(false, false, false);
    bHidden = true;
}

// Player must have bRagdolls=True in FemaleFPMut.ini to see karma death animation.
// If there is no FemaleFPMut.ini file on client side, then usually there is no FFPKarma.ka file too,
// so non-ragdoll death fallback is used.
// WARNING! Trying to use karma without karma file causes game crash!
// -- PooSH
simulated function PlayDyingAnimation(class<DamageType>DamageType,vector HitLoc)
{
    if(Level.NetMode!=NM_DedicatedServer && Class'FFPKarma'.Static.UseRagdoll(Level) ) {
        // karma death
        super.PlayDyingAnimation(DamageType, HitLoc);
    }
    else {
        if(MyExtCollision!=None)
            MyExtCollision.Destroy();

        // non-ragdoll death fallback
        Velocity+=GetTearOffMomemtum();
        BaseEyeHeight=Default.BaseEyeHeight;
        SetTwistLook(0,0);
        SetInvisibility(0.0);
        PlayDirectionalDeath(HitLoc);
        SetPhysics(PHYS_Falling);
    }
}

function RemoveHead()
{
    local int i;

    Intelligence = BRAINS_Retarded; // Headless dumbasses!

    bDecapitated  = true;
    DECAP = true;
    DecapTime = Level.TimeSeconds;

    Velocity = vect(0,0,0);
    SetAnimAction(KFHitFront);
    SetGroundSpeed(GroundSpeed *= 0.80);
    AirSpeed *= 0.8;
    WaterSpeed *= 0.8;

    // No more raspy breathin'...cuz he has no throat or mouth :S
    AmbientSound = MiscSound;

    //TODO - do we need to inform the controller that we can't move owing to lack of head,
    //       or is that handled elsewhere
    if ( Controller != none )
    {
        MonsterController(Controller).Accuracy = -5;  // More chance of missing. (he's headless now, after all) :-D
    }

    // Head explodes, causing additional hurty.
    if( KFPawn(LastDamagedBy)!=None )
    {
        TakeDamage( LastDamageAmount + 0.25 * HealthMax , LastDamagedBy, LastHitLocation, LastMomentum, LastDamagedByType);

        if ( BurnDown > 0 )
        {
            KFSteamStatsAndAchievements(KFPawn(LastDamagedBy).PlayerReplicationInfo.SteamStatsAndAchievements).AddBurningDecapKill(class'KFGameType'.static.GetCurrentMapName(Level));
        }
    }

    if( Health > 0 )
    {
        BleedOutTime = Level.TimeSeconds +  BleedOutDuration;
    }

    // Plug in headless anims if we have them
    for( i = 0; i < 4; i++ )
    {
        if( HeadlessWalkAnims[i] != '' && HasAnim(HeadlessWalkAnims[i]) )
        {
            MovementAnims[i] = HeadlessWalkAnims[i];
            WalkAnims[i]     = HeadlessWalkAnims[i];
        }
    }

    PlaySound(DecapitationSound, SLOT_Misc,1.30,true,525);

    // FFP has different bone names. Since most bones are hardcoded in KFMonster,
    // there is no easy way to implement decapitation
    KilledBy(LastDamagedBy);
}

simulated function ProcessHitFX()
{
    super.ProcessHitFX();

    // make sure the head is removed from decapitated zeds
    if (bDecapitated && !bHeadGibbed) {
        DecapFX(GetBoneCoords(HeadBone).Origin, rot(0,0,0), false, true);
    }
}


static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.FFP.BraTexture');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.FFP.FFP_Metal_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.FFP.FFP_Metal_R_cmb');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFPLights_Yellow_shader');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFPLights_Red_shader');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFP_Skin1_Sdr');
}

defaultproperties
{
     ChargingAnim="Rage_Run"
     ChargingSpeedMult=2.3
     Attack1DamageMult=0.60  // drilling attack, 60% of MeleeDamage
     Attack2DamageMult=0.40  // x2 - there are two swing attacks
     // Attack3DamageMult is always 1.0, i.e. deals MeleeDamage
     RageDamageMult=1.25     // does 25% more damage while raged
     RageMegaHitDamageMult=2.0  // RageDamageMult is NOT applied on the mega hit
     RageMegaHitCounter=10.0
     VentEffectClass=Class'FFPVentEmitter'
     RageDamageThreshold=300
     MeleeAnims(0)="Attack1"
     MeleeAnims(1)="Attack2"
     MeleeAnims(2)="Attack3"
     HitAnims(0)="Hit"
     HitAnims(1)="Hit"
     HitAnims(2)="Hit"
     MoanVoice=SoundGroup'ScrnZedPack_S.FFP.FFPG_Talk'
     KFHitFront="Hit"
     KFHitBack="Hit"
     KFHitLeft="Hit"
     KFHitRight="Hit"
     StunsRemaining=3
     BleedOutDuration=7.000000
     ZapThreshold=1.750000
     ZappedDamageMod=1.250000
     ZombieFlag=3
     MeleeDamage=30
     damageForce=15000
     bFatAss=True
     KFRagdollName="FFPKarma"
     MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.Fleshpound.FP_HitPlayer'
     JumpSound=SoundGroup'ScrnZedPack_S.FFP.FFPG_Jump'
     SpinDamConst=15.000000
     SpinDamRand=10.000000
     bMeleeStunImmune=True
     Intelligence=BRAINS_Mammal
     bUseExtendedCollision=True
     ColOffset=(X=25.0,Z=43.0)
     ColRadius=30
     ColHeight=30
     ExtCollAttachBoneName="Collision_Attach"
     SeveredLegAttachScale=1.100000
     SeveredHeadAttachScale=1.200000
     DetachedArmClass=Class'SeveredArmFFP'
     DetachedLegClass=Class'SeveredLegFFP'
     PlayerCountHealthScale=0.300000
     OnlineHeadshotOffset=(X=25.0,Z=59.0)
     OnlineHeadshotOffsetCharging=(X=35.0,Z=50.0)
     OnlineHeadshotScale=1.3
     HeadHealth=600.000000
     PlayerNumHeadHealthScale=0.300000
     MotionDetectorThreat=5.000000
     HitSound(0)=SoundGroup'ScrnZedPack_S.FFP.FFPG_Pain'
     DeathSound(0)=SoundGroup'ScrnZedPack_S.FFP.FFPG_Death'
     ChallengeSound(0)=SoundGroup'ScrnZedPack_S.FFP.FFPG_Challenge'
     ChallengeSound(1)=SoundGroup'ScrnZedPack_S.FFP.FFPG_Challenge'
     ChallengeSound(2)=SoundGroup'ScrnZedPack_S.FFP.FFPG_Challenge'
     ChallengeSound(3)=SoundGroup'ScrnZedPack_S.FFP.FFPG_Challenge'
     ScoringValue=200
     IdleHeavyAnim="Idle"
     IdleRifleAnim="Idle"
     FireRootBone="BODY_Spine2"
     GroundSpeed=140.000000
     AttackSpeedMult=0.60
     HeavyAttackSpeedMult=0.45
     HealthMax=1100.000000
     Health=1100
     HeadRadius=8.000000
     HeadHeight=2.500000
     HeadScale=1.300000
     MenuName="Female FleshPound"
     ControllerClass=Class'FFPController'
     MovementAnims(0)="WalkF"
     MovementAnims(1)="WalkB"
     MovementAnims(2)="WalkL"
     MovementAnims(3)="WalkR"
     WalkAnims(0)="WalkF"
     WalkAnims(1)="WalkB"
     WalkAnims(2)="WalkL"
     WalkAnims(3)="WalkR"
     HeadlessWalkAnims(0)="Headless_WalkCycle"
     HeadlessWalkAnims(1)="Headless_WalkCycle_Back"
     HeadlessWalkAnims(2)="Headless_WalkCycle_Left"
     HeadlessWalkAnims(3)="Headless_WalkCycle_Right"

     // cannot use flaming walking animations as they fuck up hitbox detection on the server
     // BurningWalkFAnims(0)="Flaming_WalkCycle"
     // BurningWalkFAnims(1)="Flaming_WalkCycle"
     // BurningWalkFAnims(2)="Flaming_WalkCycle"
     // BurningWalkAnims(0)="Flaming_WalkCycle_Back"
     // BurningWalkAnims(1)="Flaming_WalkCycle_Left"
     // BurningWalkAnims(2)="Flaming_WalkCycle_Right"
     BurningWalkFAnims(0)="WalkF"
     BurningWalkFAnims(1)="WalkF"
     BurningWalkFAnims(2)="WalkF"
     BurningWalkAnims(0)="WalkB"
     BurningWalkAnims(1)="WalkL"
     BurningWalkAnims(2)="WalkR"

     IdleCrouchAnim="Idle"
     IdleWeaponAnim="Idle"
     IdleRestAnim="Idle"
     AirStillAnim="Jump"
     TakeoffStillAnim="Jump"

     RootBone="Armature"
     HeadBone="BODY_Head"
     SpineBone1="BODY_Spine2"
     SpineBone2="BODY_Spine3"
     AmbientSound=SoundGroup'ScrnZedPack_S.FFP.FFPG_Idle'
     Mesh=SkeletalMesh'ScrnZedPack_A.FFPMesh'
     Skins(0)=Texture'ScrnZedPack_T.FFP.BraTexture'
     Skins(1)=Combiner'ScrnZedPack_T.FFP.FFP_Metal_cmb'
     Skins(2)=Combiner'ScrnZedPack_T.FFP.FFP_Metal_cmb'
     Skins(3)=Shader'ScrnZedPack_T.FFP.FFPLights_Yellow_shader'
     Skins(4)=Shader'ScrnZedPack_T.FFP.FFP_Skin1_Sdr'
     CollisionRadius=26
     Mass=500.000000
     RotationRate=(Yaw=45000,Roll=0)
     AvoidAreaClass=class'ZedAvoidArea'
}
