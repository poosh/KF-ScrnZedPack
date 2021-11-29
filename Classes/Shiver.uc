class Shiver extends KFMonster;

#exec load obj file=ScrnZedPack_T.utx
#exec load obj file=ScrnZedPack_S.uax
#exec load obj file=ScrnZedPack_A.ukx

var name WalkAnim, RunAnim;

// Head twitch
var rotator CurHeadRot, NextHeadRot, HeadRot;
var float NextHeadTime;
var float MaxHeadTime;
var float MaxTilt, MaxTurn;

// Targetting, charging
var float TeleportBlockTime;
var vector HeadOffset;

var transient bool bRunning, bClientRunning;
var bool bDelayedReaction;
var transient bool bCanSeeEnamy;
var transient float ChargeEnemyTime;
var float RunUntilTime;
var float RunCooldownEnd;
var float PeriodRunBase;
var float PeriodRunRan;
var float PeriodRunCoolBase;
var float PeriodRunCoolRan;

// Teleporting
var byte FadeStage;
var byte OldFadeStage;
var float AlphaFader;
var bool bFlashTeleporting;
var float LastFlashTime;
var float MinTeleportDistSq, MaxTeleportDistSq;
var float MinLandDist, MaxLandDist; // How close we can teleport to the target (collision cylinders are taken into account)
var int MaxTeleportAttempts; // Attempts per angle
var int MaxTeleportAngles;
var ColorModifier MatAlphaSkin;

replication
{
    reliable if (Role == ROLE_Authority)
        FadeStage, bRunning;
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    if (Level.NetMode != NM_DedicatedServer)
    {
        MatAlphaSkin = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
        if (MatAlphaSkin != none)
        {
            MatAlphaSkin.Color = class'Canvas'.static.MakeColor(255, 255, 255, 255);
            MatAlphaSkin.RenderTwoSided = false;
            MatAlphaSkin.AlphaBlend = true;
            MatAlphaSkin.Material = Skins[0];
            Skins[0] = MatAlphaSkin;
        }
    }
    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function Destroyed()
{
    if (Level.NetMode != NM_DedicatedServer && MatAlphaSkin != none)
    {
        Skins[0] = default.Skins[0];
        Level.ObjectPool.FreeObject(MatAlphaSkin);
    }

    class'ScrnZedFunc'.static.ZedDestroyed(self);
    Super.Destroyed();
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if( bClientRunning != bRunning )
    {
        bClientRunning = bRunning;
        if( bRunning ) {
            MovementAnims[0] = RunAnim;
        }
        else {
            MovementAnims[0] = WalkAnim;
        }
    }
}

simulated function StopBurnFX()
{
    if (bBurnApplied)
    {
        MatAlphaSkin.Material = Texture'PatchTex.Common.ZedBurnSkin';
        Skins[0] = MatAlphaSkin;
    }

    Super.StopBurnFX();
}

function RangedAttack(Actor A)
{
    if (bShotAnim || Physics == PHYS_Swimming)
        return;
    else if (CanAttack(A))
    {
        bShotAnim = true;
        SetAnimAction('Claw');
        return;
    }
}

state Running
{
    function BeginState()
    {
        bRunning = true;
        RunUntilTime = Level.TimeSeconds + PeriodRunBase + FRand() * PeriodRunRan;
        MovementAnims[0] = RunAnim;
    }

    function EndState()
    {
        bRunning = false;
        GroundSpeed = global.GetOriginalGroundSpeed();
        RunCooldownEnd = Level.TimeSeconds + PeriodRunCoolBase + FRand() * PeriodRunCoolRan;
        MovementAnims[0] = WalkAnim;
    }

    function float GetOriginalGroundSpeed()
    {
        return global.GetOriginalGroundSpeed() * 2.5;
    }

    function Tick(float Delta)
    {
        Global.Tick(Delta);
        if (RunUntilTime < Level.TimeSeconds)
            GotoState('');
        GroundSpeed = GetOriginalGroundSpeed();
    }

    function bool CanSpeedAdjust()
    {
        return false;
    }

    function bool CanRun()
    {
        return false;
    }

    function RemoveHead()
    {
        GotoState('');
        global.RemoveHead();
    }

}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    TeleportBlockTime = fmax(TeleportBlockTime, Level.TimeSeconds + 0.5);
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

// returns true also for KnockDown (stun) animation -- PooSH
simulated function bool AnimNeedsWait(name TestAnim)
{
    if( TestAnim == 'DoorBash' || TestAnim == 'KnockDown' )
    {
        return true;
    }

    return ExpectingChannel == 0;
}

simulated function float GetOriginalGroundSpeed()
{
    local float result;

    result = OriginalGroundSpeed;

    if( bZedUnderControl )
        result *= 1.25;

    if ( bBurnified )
        result *= 0.8;

    return result;
}

simulated function Tick(float Delta)
{
    local float DistSq;
    local bool bSeeEnemyNow;

    Super.Tick(Delta);

    if ( Role == ROLE_Authority && !bDecapitated && !bBurnApplied && Health > 0 ) {
        bSeeEnemyNow = Controller != none && Controller.Enemy != none && Controller.Enemy == Controller.Target
                && Controller.CanSee(Controller.Enemy);

        if ( bCanSeeEnamy != bSeeEnemyNow ) {
            bCanSeeEnamy = bSeeEnemyNow;
            if ( bCanSeeEnamy ) {
                ChargeEnemyTime = Level.TimeSeconds + 1.0 + 3.0*frand();
            }
        }
        else if ( bCanSeeEnamy && Level.TimeSeconds > ChargeEnemyTime ) {
            DistSq = VSizeSquared(Controller.Enemy.Location - Location);
            if (DistSq < MaxTeleportDistSq) {
                if ( (DistSq > MinTeleportDistSq || !Controller.ActorReachable(Controller.Enemy)) && CanTeleport() ) {
                    StartTeleport();
                }
                else if ( CanRun() ) {
                    GotoState('Running');
                }
            }
        }
    }

    // Handle client-side teleport variables
    if (!bBurnApplied)
    {
        if (Level.NetMode != NM_DedicatedServer && OldFadeStage != FadeStage)
        {
            OldFadeStage = FadeStage;

            if (FadeStage == 2)
                AlphaFader = 0;
            else
                AlphaFader = 255;
        }

        // Handle teleporting
        if (FadeStage == 1) // Fade out (pre-teleport)
        {
            AlphaFader = FMax(AlphaFader - Delta * 512, 0);

            if (Role == ROLE_Authority && AlphaFader == 0)
            {
                SetCollision(true, true);
                FlashTeleport();
                SetCollision(false, false);
                FadeStage = 2;
            }
        }
        else if (FadeStage == 2) // Fade in (post-teleport)
        {
            AlphaFader = FMin(AlphaFader + Delta * 512, 255);

            if (Role == ROLE_Authority && AlphaFader == 255)
            {
                FadeStage = 0;
                SetCollision(true, true);
                GotoState('Running');
            }
        }

        if (Level.NetMode != NM_DedicatedServer && ColorModifier(Skins[0]) != none)
            ColorModifier(Skins[0]).Color.A = AlphaFader;
    }
}

/*
simulated function DebugHead()
{
    local coords C;
    local vector HeadLoc;
    local float Radius;

    Radius = HeadRadius * HeadScale;

    ClearStayingDebugLines();
    // based on head bone
    C = GetBoneCoords(HeadBone);
        HeadLoc = C.Origin + (HeadHeight * HeadScale * C.XAxis) + HeadOffsetY * C.YAxis;
    DrawDebugSphere(HeadLoc, Radius, 16, 0, 100, 255);
    DrawStayingDebugLine(HeadLoc - Radius*vect(1,0,0), HeadLoc + Radius*vect(1,0,0), 0, 100, 255);
    DrawStayingDebugLine(HeadLoc - Radius*vect(0,1,0), HeadLoc + Radius*vect(0,1,0), 0, 100, 255);
    DrawStayingDebugLine(HeadLoc - Radius*vect(0,0,1), HeadLoc + Radius*vect(0,0,1), 0, 100, 255);

    // based on OnlineHeadshotOffset
    HeadLoc = Location + (OnlineHeadshotOffset >> Rotation);
    Radius *= OnlineHeadshotScale;
    DrawDebugSphere(HeadLoc, Radius, 16, 255, 0, 0);
    DrawStayingDebugLine(HeadLoc - Radius*vect(1,0,0), HeadLoc + Radius*vect(1,0,0), 255, 0, 0);
    DrawStayingDebugLine(HeadLoc - Radius*vect(0,1,0), HeadLoc + Radius*vect(0,1,0), 255, 0, 0);
    DrawStayingDebugLine(HeadLoc - Radius*vect(0,0,1), HeadLoc + Radius*vect(0,0,1), 255, 0, 0);
}
*/

function bool CanTeleport()
{
    return !bFlashTeleporting && !bBurnified && Physics == PHYS_Walking && Level.TimeSeconds > TeleportBlockTime
        && LastFlashTime + 7.5 < Level.TimeSeconds;
}

function bool CanRun()
{
    return !bFlashTeleporting && RunCooldownEnd < Level.TimeSeconds;
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, HeadOffset);
}

function StartTeleport()
{
    FadeStage = 1;
    AlphaFader = 255;
    SetCollision(false, false);
    bFlashTeleporting = true;
}

function FlashTeleport()
{
    local Actor Target;
    local vector OldLoc;
    local vector NewLoc;
    local vector HitLoc;
    local vector HitNorm;
    local rotator RotOld;
    local rotator RotNew;
    local float LandTargetDist;
    local int iEndAngle;
    local int iAttempts;

    if (Controller == none || Controller.Enemy == none)
        return;

    Target = Controller.Enemy;
    RotOld = rotator(Target.Location - Location);
    RotNew = RotOld;
    OldLoc = Location;

    for (iEndAngle = 0; iEndAngle < MaxTeleportAngles; iEndAngle++)
    {
        RotNew = RotOld;
        RotNew.Yaw += iEndAngle * (65536 / MaxTelePortAngles);

        for (iAttempts = 0; iAttempts < MaxTeleportAttempts; iAttempts++)
        {
            LandTargetDist = Target.CollisionRadius + CollisionRadius +
                MinLandDist + (MaxLandDist - MinLandDist) * (iAttempts / (MaxTeleportAttempts - 1.0));

            NewLoc = Target.Location - vector(RotNew) * LandTargetDist; // Target.Location - Location
            NewLoc.Z = Target.Location.Z;

            if (Trace(HitLoc, HitNorm, NewLoc + vect(0, 0, -500), NewLoc) != none)
                NewLoc.Z = HitLoc.Z + CollisionHeight;

            // Try a new location
            if (SetLocation(NewLoc))
            {
                SetPhysics(PHYS_Walking);

                if (Controller.PointReachable(Target.Location))
                {
                    Velocity = vect(0, 0, 0);
                    Acceleration = vect(0, 0, 0);
                    SetRotation(rotator(Target.Location - Location));

                    PlaySound(Sound'ScrnZedPack_S.Shiver.ShiverWarpGroup', SLOT_Interact, 4.0);
                    Controller.GotoState('');
                    MonsterController(Controller).WhatToDoNext(0);
                    goto Teleported;
                }
            }

            // Reset location
            SetLocation(OldLoc);
        }
    }

Teleported:

    bFlashTeleporting = false;
    LastFlashTime = Level.TimeSeconds;
}

function RemoveHead()
{
    local class<KFWeaponDamageType> KFDamType;
    local KFPlayerController KFPC;

    KFDamType = class<KFWeaponDamageType>(LastDamagedByType);
    if ( LastDamagedBy != none )
        KFPC = KFPlayerController(LastDamagedBy.Controller);

    if ( KFDamType != none && !KFDamType.default.bIsPowerWeapon
            && !KFDamType.default.bSniperWeapon && !KFDamType.default.bIsMeleeDamage
            && !KFDamType.default.bIsExplosive && !KFDamType.default.bDealBurningDamage )
    {
        LastDamageAmount *= 3.5; //significantly raise decapitation bonus for Assault Rifles

        //award shiver kill on decap for Commandos
        if ( KFPC != none && KFSteamStatsAndAchievements(KFPC.SteamStatsAndAchievements) != none ) {
            KFDamType.Static.AwardKill(KFSteamStatsAndAchievements(KFPC.SteamStatsAndAchievements), KFPC, self);
        }
    }
    Super.RemoveHead();
}

function bool FlipOver()
{
    if ( super.FlipOver() ) {
        TeleportBlockTime = Level.TimeSeconds + 4.0; // can't teleport during stun
        // do not rotate while stunned
        Controller.Focus = none;
        Controller.FocalPoint = Location + 512*vector(Rotation);
    }
    return false;
}

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamType)
{
    if (Level.TimeSeconds - LastPainSound > MinTimeBetweenPainSounds)
    {
        LastPainSound = Level.TimeSeconds;
        PlaySound(HitSound[0], SLOT_Pain, 1.25,,400);
    }

    if (!IsInState('Running') && Level.TimeSeconds - LastPainAnim > MinTimeBetweenPainAnims)
    {
        PlayDirectionalHit(HitLocation);
        LastPainAnim = Level.TimeSeconds;
    }
}

simulated function int DoAnimAction( name AnimName )
{
    if (AnimName=='Claw' || AnimName=='Claw2' || AnimName=='Claw3')
    {
        AnimBlendParams(1, 1.0, 0.1,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);
        return 1;
    }

    return Super.DoAnimAction(AnimName);
}

static function PreCacheMaterials(LevelInfo myLevel)
{
    local int i;

    for ( i = 0; i < default.Skins.length; ++i ) {
        myLevel.AddPrecacheMaterial(default.Skins[i]);
    }
}

defaultproperties
{
    ControllerClass=class'ScrnZedPack.ZedController'
    WalkAnim="ClotWalk"
    RunAnim="Run"
    MaxHeadTime=0.100000
    MaxTilt=10000.000000
    MaxTurn=20000.000000
    bDelayedReaction=True
    PeriodRunBase=4.000000
    PeriodRunRan=4.000000
    PeriodRunCoolBase=4.000000
    PeriodRunCoolRan=3.000000
    AlphaFader=255.000000
    MinTeleportDistSq=302500   // 11m squared
    MaxTeleportDistSq=4000000  // 40m squared
    MinLandDist=150.000000
    MaxLandDist=500.000000
    MaxTeleportAttempts=3
    MaxTeleportAngles=3
    MoanVoice=SoundGroup'ScrnZedPack_S.Shiver.ShiverTalkGroup'
    bCannibal=True
    MeleeDamage=8
    damageForce=5000
    KFRagdollName="Clot_Trip"
    JumpSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Jump'
    CrispUpThreshhold=9
    PuntAnim="ClotPunt"
    Intelligence=BRAINS_Mammal
    bUseExtendedCollision=True
    ColOffset=(Z=48.000000)
    ColRadius=25.000000
    ColHeight=5.000000
    ExtCollAttachBoneName="Collision_Attach"
    SeveredArmAttachScale=0.800000
    SeveredLegAttachScale=0.800000
    SeveredHeadAttachScale=0.800000
    DetachedArmClass=Class'ScrnZedPack.SeveredArmShiver'
    DetachedLegClass=Class'ScrnZedPack.SeveredLegShiver'
    DetachedHeadClass=Class'ScrnZedPack.SeveredHeadShiver'
    HeadRadius=8.0
    HeadHeight=3.0
    HeadScale=1.300000
    HeadOffset=(Y=-3)
    OnlineHeadshotOffset=(X=19.000000,Z=39.000000)
    OnlineHeadshotScale=1.4
    MotionDetectorThreat=0.340000
    HitSound(0)=SoundGroup'ScrnZedPack_S.Shiver.ShiverPainGroup'
    DeathSound(0)=SoundGroup'ScrnZedPack_S.Shiver.ShiverDeathGroup'
    ChallengeSound(0)=SoundGroup'ScrnZedPack_S.Shiver.ShiverTalkGroup'
    ChallengeSound(1)=SoundGroup'ScrnZedPack_S.Shiver.ShiverTalkGroup'
    ChallengeSound(2)=SoundGroup'ScrnZedPack_S.Shiver.ShiverTalkGroup'
    ChallengeSound(3)=SoundGroup'ScrnZedPack_S.Shiver.ShiverTalkGroup'
    ScoringValue=15
    GroundSpeed=100.000000
    WaterSpeed=100.000000
    AccelRate=1024.000000
    JumpZ=340.000000
    HealthMax=300
    Health=300
    PlayerCountHealthScale=0.200000

    MenuName="Shiver"
    MovementAnims(0)="ClotWalk"
    AmbientSound=SoundGroup'ScrnZedPack_S.Shiver.ShiverIdleGroup'
    Mesh=SkeletalMesh'ScrnZedPack_A.ShiverMesh'
    DrawScale=1.100000
    PrePivot=(Z=5.000000)
    Skins(0)=Combiner'ScrnZedPack_T.Shiver.CmbRemoveAlpha'
    RotationRate=(Yaw=45000,Roll=0)
}
