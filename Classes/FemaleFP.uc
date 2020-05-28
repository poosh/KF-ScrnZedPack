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

var transient bool bChargingPlayer,bClientCharge,bFrustrated,bNeedVent;
var transient bool bRageFirstHit; //did she hit a player during current rage run
var float RageEndTime;
var FleshPoundAvoidArea AvoidArea;
var name ChargingAnim;

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

replication
{
    reliable if(Role==ROLE_Authority)
        bChargingPlayer,bFrustrated, bNeedVent;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( ROLE==ROLE_Authority ) {
        StunsRemaining = fmax(7 - Level.Game.GameDifficulty, 1);
    }
}

simulated function PostNetBeginPlay()
{
    if(AvoidArea==None)
        AvoidArea=Spawn(class'FleshPoundAvoidArea',self);
    if(AvoidArea!=None)
        AvoidArea.InitFor(Self);

    EnableChannelNotify(1,1);
    AnimBlendParams(1,1.0,0.0,,SpineBone2);
    super.PostNetBeginPlay();
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
    local bool didIHit;

    didIHit= super.MeleeDamageTarget(hitdamage, pushdir);
    FFPController(Controller).bMissTarget=
        FFPController(Controller).bMissTarget || !didIHit;
    return didIHit;
}


function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    local int OldHealth;
    local bool bIsHeadShot;
    local float HeadShotCheckScale;
    local class<KFWeaponDamageType> KFDamType;

    // optimizes typecasting and make code comre compact -- PooSH
    KFDamType = class<KFWeaponDamageType>(damageType);
    oldHealth= Health;

    if ( KFDamType != none )
    {
        HeadShotCheckScale = 1.0;
        // Do larger headshot checks if it is a melee attach
        if( class<DamTypeMelee>(damageType) != none )
            HeadShotCheckScale *= 1.25;
        bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), 1.0);

        // She takes less damage to small arms fire (non explosives)
        // Frags and LAW rockets will bring her down way faster than bullets and shells.
        if ( !KFDamType.default.bIsExplosive ) // all explosives: current, future and custom -- PooSH
        {
            // Don't reduce the damage so much if its a high headshot damage weapon
            if( bIsHeadShot && KFDamType.default.HeadShotDamageMult >= 1.5 )
            {
                Damage *= 0.75;
            }
            else if ( Level.Game.GameDifficulty >= 5.0 && bIsHeadshot
                && (ClassIsChildOf(KFDamType, class'DamTypeCrossbow')
                    || ClassIsChildOf(KFDamType, class'DamTypeM99SniperRifle')) )
            {
                Damage *= 0.35; // 65% damage reduction from xbow/m99 headshots
            }
            else
            {
                Damage *= 0.5;
            }
        }
        // include subclasses = care about modders (c) PooSH
        // Can't check subclasses of DamTypeFrag, because LAW is one of them
        else if ( KFDamType == class'DamTypeFrag' || ClassIsChildOf(KFDamType, class'DamTypePipeBomb') )
        {
            Damage *= 1.25;
        }
        // M32 and SP are subclasses of DamTypeM79Grenade, so no need to additionally check those -- PooSH
        else if( ClassIsChildOf(KFDamType, class'DamTypeM79Grenade')
                || ClassIsChildOf(KFDamType, class'DamTypeM203Grenade') )
        {
            Damage *= 1.25;
        }
    }

    // Shut off his "Device" when dead
    if (Damage >= Health)
        PostNetReceive();


    if (damageType == class 'DamTypeVomit')
        Damage = 0; // nulled

    // fixes none-reference erros when taking enviromental damage -- PooSH
    if (InstigatedBy == none || KFDamType == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType); // skip NONE-reference error
    else
        super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);


    Damage = OldHealth - Health;

    // Starts charging if single damage > 300 or health drops below 50% on hard difficulty or below,
    // or health <75% on Suicidal/HoE
    // -- PooSH
    if ( Health > 0 && !bDecapitated && !bChargingPlayer
            && !bZapped && (!(bCrispified && bBurnified) || bFrustrated)
            && (Damage > RageDamageThreshold || Health < HealthMax*0.5
                || (Level.Game.GameDifficulty >= 5.0 && Health < HealthMax*0.75)) )
        StartCharging();
}

function RangedAttack(Actor A)
{
    if ( bShotAnim || Physics == PHYS_Swimming)
        return;
    else if ( CanAttack(A) )
    {
        bShotAnim = true;
        SetAnimAction('Claw');
        return;
    }
}

//Need to add sound!
simulated function SpawnVentEmitter()
{
    if ( VentEffectClass != none )
    {
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
    else
        bNeedVent = false;
}


//Clean up of effects.
function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    StopVenting();
    super.Died( Killer, damageType, HitLocation );
}

simulated function VentMe()
{
    //Level.GetLocalPlayerController().ClientMessage("VentMe");
    //Log("AAAAAARRRRRRROOOOOOOOOOOOOOGGGGGAAAAAAAAA!!");
    bNeedVent = true;
    SpawnVentEmitter();
}

simulated function StopVenting()
{
    bNeedVent = false;
    if ( VentEffect != none )
    {
        VentEffect.Destroy();
        VentEffect = none;
    }
    if ( VentEffect2 != none )
    {
        VentEffect2.Destroy();
        VentEffect2 = none;
    }
}

// Sets the FFP in a berserk charge state until she either strikes her target, or hits timeout
function StartCharging()
{
    local float RageAnimDur;

    if( Health <= 0 )
    {
        return;
    }

    SetAnimAction('Rage_Start');
    Acceleration = vect(0,0,0);
    bShotAnim = true;
    Velocity.X = 0;
    Velocity.Y = 0;
    Controller.GoToState('WaitForAnim');
    KFMonsterController(Controller).bUseFreezeHack = True;
    RageAnimDur = GetAnimDuration('Rage_Start');
    FleshpoundZombieController(Controller).SetPoundRageTimout(RageAnimDur);
    GoToState('BeginRaging');
}

state BeginRaging
{
    Ignores StartCharging;

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

    function Tick( float Delta )
    {
        Acceleration = vect(0,0,0);

        global.Tick(Delta);
    }

Begin:
    Sleep(GetAnimDuration('Rage_Start'));
    GotoState('RageCharging');
}


simulated function SetBurningBehavior()
{
    if( bFrustrated || bChargingPlayer )
    {
        return;
    }

    super.SetBurningBehavior();
}

//Next two States are Scary's Code.
state RageCharging
{
    Ignores StartCharging;
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

        bRageFirstHit = false;

        if( bZapped )
        {
            GoToState('');
        }
        else
        {
            bChargingPlayer = true;
            if( Level.NetMode!=NM_DedicatedServer )
                ClientChargingAnims();

            // Scale rage length by difficulty
            if( Level.Game.GameDifficulty < 2.0 )
            {
                DifficultyModifier = 0.85;
            }
            else if( Level.Game.GameDifficulty < 4.0 )
            {
                DifficultyModifier = 1.0;
            }
            else if( Level.Game.GameDifficulty < 5.0 )
            {
                DifficultyModifier = 1.25;
            }
            else // Hardest difficulty
            {
                DifficultyModifier = 3.0; // Doubled Fleshpound Rage time for Suicidal and HoE in Balance Round 1
            }

            RageEndTime = Level.TimeSeconds + DifficultyModifier * (10.0 + 6.0*FRand());
            NetUpdateTime = Level.TimeSeconds - 1;
        }
    }

    function EndState()
    {
        bChargingPlayer = False;
        bFrustrated = false;

        FleshPoundZombieController(Controller).RageFrustrationTimer = 0;
        StopVenting();

        if( Health>0 && !bZapped )
        {
            SetGroundSpeed(GetOriginalGroundSpeed());
        }

        if( Level.NetMode!=NM_DedicatedServer )
            ClientChargingAnims();

        NetUpdateTime = Level.TimeSeconds - 1;
    }

    function Tick( float Delta )
    {
        if( !bShotAnim )
        {
            SetGroundSpeed(OriginalGroundSpeed * 2.3);//2.0;
            if( !bFrustrated && !bZedUnderControl && Level.TimeSeconds>RageEndTime )
            {
                GoToState('');
            }
        }

        // Keep the flesh pound moving toward its target when attacking
        if( Role == ROLE_Authority && bShotAnim)
        {
            if( LookTarget!=None )
            {
                Acceleration = AccelRate * Normal(LookTarget.Location - Location);
            }
        }

        global.Tick(Delta);
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
            oldEnemyHealth= KFP.Health;

        bWasEnemy = (Controller.Target==Controller.Enemy);
        if ( !bRageFirstHit )
            hitdamage *= 1.5; // first rage hit doesn more damage, down from 1.75 to 1.5 in v091 -- PooSH
        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage, pushdir*3);

        if ( bAttackingHuman || bWasEnemy )
            bRageFirstHit = true; //she had a chance to do a greater damage. If she missed - her fault

        if(RetVal && bWasEnemy)
        {
            // On Hard and below she always calms down, no matter of was hit successful or not
            // On Suicidal she calms down after successfull hit
            // On HoE she calms down only if killed a player.
            if ( bAttackingHuman && Level.Game.GameDifficulty >= 5.0 ) {
                if ( Level.Game.GameDifficulty >= 7.0 )
                    bCalmDown = KFP == none || KFP.Health <= 0;
                else
                    bCalmDown = KFP == none || KFP.Health < oldEnemyHealth;
            }
            else {
                bCalmDown = true;
            }

            if (bCalmDown)
                GoToState('');
        }

        return RetVal;
    }
}

state ChargeToMarker extends RageCharging
{
Ignores StartCharging;

    function Tick( float Delta )
    {
        if( !bShotAnim )
        {
            SetGroundSpeed(OriginalGroundSpeed * 2.3);
            if( !bFrustrated && !bZedUnderControl && Level.TimeSeconds>RageEndTime )
            {
                GoToState('');
            }
        }

        // Keep the flesh pound moving toward its target when attacking
        if( Role == ROLE_Authority && bShotAnim)
        {
            if( LookTarget!=None )
            {
                Acceleration = AccelRate * Normal(LookTarget.Location - Location);
            }
        }

        global.Tick(Delta);
    }
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if( bClientCharge!=bChargingPlayer && !bZapped )
    {
        bClientCharge=bChargingPlayer;
        if( bChargingPlayer ) {
            MovementAnims[0]=ChargingAnim;
            MeleeAnims[0]='attack3';
            MeleeAnims[1]='attack3';
            MeleeAnims[2]='attack3';
            DeviceGoRed();
        }
        else {
            MovementAnims[0]=default.MovementAnims[0];
            MeleeAnims[0]=default.MeleeAnims[0];
            MeleeAnims[1]=default.MeleeAnims[1];
            MeleeAnims[2]=default.MeleeAnims[2];
            DeviceGoNormal();
            StopVenting();
        }
    }
}

simulated function ClientChargingAnims()
{
    PostNetReceive();
}

function ClawDamageTarget()
{
    local vector PushDir;
    local KFHumanPawn HumanTarget;
    local KFPlayerController HumanTargetController;
    local float UsedMeleeDamage;
    local name  Sequence;
    local float Frame, Rate;

    GetAnimParams( ExpectingChannel, Sequence, Frame, Rate );

    if( MeleeDamage > 1 )
    {
       UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));
    }
    else
    {
       UsedMeleeDamage = MeleeDamage;
    }

    // Reduce the melee damage for anims with repeated attacks, since it does repeated damage over time
    if( Sequence == 'Attack1' )
    {
        UsedMeleeDamage *= 0.5;
    }
    else if( Sequence == 'Attack2' )
    {
        UsedMeleeDamage *= 0.25;
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
        Return 1;
    }
    Return Super.DoAnimAction(AnimName);
}

simulated event SetAnimAction(name NewAction)
{
    local int meleeAnimIndex;

    if( NewAction=='' )
        Return;
    if(NewAction == 'Claw')
    {
        meleeAnimIndex = Rand(3);
        NewAction = meleeAnims[meleeAnimIndex];
        CurrentDamtype = ZombieDamType[meleeAnimIndex];
    }
    else if( NewAction == 'DoorBash' )
    {
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

    FFPController(Controller).bAttackedTarget=
        (NewAction == 'Claw') || (NewAction == 'DoorBash');
}

// The animation is full body and should set the bWaitForAnim flag
simulated function bool AnimNeedsWait(name TestAnim)
{
    if( TestAnim == 'Rage_Start' || TestAnim == 'DoorBash' )
    {
        return true;
    }

    return false;
}

simulated function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    // Keep the flesh pound moving toward its target when attacking
    if( Role == ROLE_Authority && bShotAnim)
    {
        if( LookTarget!=None )
        {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }
    }

    if ( Level.NetMode != NM_DedicatedServer ) {
        if ( bNeedVent && Health > 0 )
            SpawnVentEmitter();

        //DebugHead();
    }
}

simulated function DebugHead()
{
    local coords C;
    local vector HeadLoc;
    local float Radius;

    if ( Level.NetMode == NM_DedicatedServer || Health <= 0 )
        return;

    Radius = HeadRadius * HeadScale;

    // based on head bone
    C = GetBoneCoords(HeadBone);
    HeadLoc = C.Origin + (HeadHeight * HeadScale * C.XAxis);
    DrawDebugSphere(HeadLoc, Radius, 16, 0, 100, 255);

    // based on OnlineHeadshotOffset
    HeadLoc = Location + (OnlineHeadshotOffset >> Rotation);
    Radius *= OnlineHeadshotScale;
    DrawDebugSphere(HeadLoc, Radius, 16, 255, 0, 0);
}

function bool FlipOver()
{
    Return False;
}

function bool SameSpeciesAs(Pawn P)
{
    return ZombieFleshPound(P) != none || FemaleFP(P) != none;
}

simulated function Destroyed()
{
    if( AvoidArea!=None )
        AvoidArea.Destroy();
    StopVenting();

    Super.Destroyed();
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
    Super.RemoveHead();
    // FFP has different bone names. Since most bones are hardcoded in KFMonster,
    // there is no easy way to implement decapitation
    KilledBy(LastDamagedBy);
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
     VentEffectClass=Class'ScrnZedPack.FFPVentEmitter'
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
     ColOffset=(Z=47.000000)
     ColRadius=40
     ColHeight=40
     ExtCollAttachBoneName="Collision_Attach"
     SeveredLegAttachScale=1.100000
     SeveredHeadAttachScale=1.200000
     DetachedArmClass=Class'ScrnZedPack.SeveredArmFFP'
     DetachedLegClass=Class'ScrnZedPack.SeveredLegFFP'
     PlayerCountHealthScale=0.300000
     OnlineHeadshotOffset=(X=25.000000,Z=61.000000)
     OnlineHeadshotScale=1.3 // 1.3
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
     HealthMax=1100.000000
     Health=1100
     HeadRadius=8.000000
     HeadHeight=2.500000
     HeadScale=1.300000
     MenuName="Female FleshPound"
     ControllerClass=Class'ScrnZedPack.FFPController'
     MovementAnims(0)="WalkF"
     MovementAnims(1)="WalkF"
     MovementAnims(2)="WalkL"
     MovementAnims(3)="WalkR"
     WalkAnims(2)="WalkL"
     WalkAnims(3)="WalkR"
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
}
