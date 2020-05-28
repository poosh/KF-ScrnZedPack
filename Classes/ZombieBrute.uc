class ZombieBrute extends KFMonster;

#exec load obj file=ScrnZedPack_T.utx
#exec load obj file=ScrnZedPack_S.uax
#exec load obj file=ScrnZedPack_A.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax

var bool bChargingPlayer;
var bool bClientCharge;
var bool bFrustrated;
var int MaxRageCounter; // Maximum amount of players we can hit before calming down
var int RageCounter; // Decreases each time we successfully hit a player
var float RageSpeedTween;
var int TwoSecondDamageTotal;
var float LastDamagedTime;
var int RageDamageThreshold;
var int BlockHitsLanded; // Hits made while blocking or raging
var float BlockMeleeDmgMul;     //Multiplier for melee damage taken, when Brute is blocking (no matter where the hit was landed)
var float HeadShotgunDmgMul;    //Multiplier for shotgun damage taken into UNBLOCKED head
var float HeadBulletDmgMul;    //Multiplier for non-sniper bullet damage taken into UNBLOCKED head


var name ChargingAnim;
var Sound RageSound;

// View shaking for players
var() vector    ShakeViewRotMag;
var() vector    ShakeViewRotRate;
var() float        ShakeViewRotTime;
var() vector    ShakeViewOffsetMag;
var() vector    ShakeViewOffsetRate;
var() float        ShakeViewOffsetTime;

var float PushForce;
var vector PushAdd; // Used to add additional height to push
var float RageDamageMul; // Multiplier for hit damage when raging
var float RageBumpDamage; // Damage done when we hit other specimens while raging
var float BlockAddScale; // Additional head scale when blocking
var bool bBlockedHS;
var bool bBlocking;
var bool bServerBlock;
var bool bClientBlock;
var float BlockDmgMul; // Multiplier for damage taken from blocked shots
var float BlockFireDmgMul;
var float BurnGroundSpeedMul; // Multiplier for ground speed when burning

replication
{
    reliable if(Role == ROLE_Authority)
        bChargingPlayer, bServerBlock;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    EnableChannelNotify(1,1);
    EnableChannelNotify(2,1);
    AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
}

function ServerRaiseBlock()
{
    bServerBlock = true;
    SetAnimAction('BlockLoop');
}

function ServerLowerBlock()
{
    local name Sequence;
    local float Frame, Rate;

    bServerBlock = false;
    GetAnimParams(1, Sequence, Frame, Rate);
    if (Sequence == 'BlockLoop')
        AnimStopLooping(1);
}

simulated function PostNetReceive()
{
    local name Sequence;
    local float Frame, Rate;

    if(bClientCharge != bChargingPlayer)
    {
        bClientCharge = bChargingPlayer;
        if (bChargingPlayer)
        {
            MovementAnims[0] = ChargingAnim;
            MeleeAnims[0] = 'BruteRageAttack';
            MeleeAnims[1] = 'BruteRageAttack';
            MeleeAnims[2] = 'BruteRageAttack';
        }
        else
        {
            MovementAnims[0] = default.MovementAnims[0];
            MeleeAnims[0] = default.MeleeAnims[0];
            MeleeAnims[1] = default.MeleeAnims[1];
            MeleeAnims[2] = default.MeleeAnims[2];
        }
    }

    if (bClientBlock != bServerBlock)
    {
        bClientBlock = bServerBlock;
        if (bClientBlock)
            SetAnimAction('BlockLoop');
        else
        {
            GetAnimParams(1, Sequence, Frame, Rate);
            if (Sequence == 'BlockLoop')
                AnimStopLooping(1);
        }
    }
}

simulated function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    if (Role == ROLE_Authority)
    {
        // Lock to target when attacking (except on beginner!)
        if (bShotAnim && Level.Game.GameDifficulty >= 2.0)
            if (LookTarget != none)
                Acceleration = AccelRate * Normal(LookTarget.Location - Location);

        // Block according to rules
        if (Role == ROLE_Authority && !bServerBlock && !bShotAnim)
            if (Controller != none && Controller.Target != none)
                ServerRaiseBlock();
    }
}

// Override to always move when attacking
function RangedAttack(Actor A)
{
    if (bShotAnim || Physics == PHYS_Swimming)
        return;
    else if (CanAttack(A))
    {
        if (bChargingPlayer)
            SetAnimAction('AoeClaw');
        else
        {
            if (Rand(BlockHitsLanded) < 1)
                SetAnimAction('BlockClaw');
            else
                SetAnimAction('Claw');
        }

        bShotAnim = true;
        return;
    }
}

function bool IsHeadShot(vector Loc, vector Ray, float AdditionalScale)
{
    local float D;
    local float AddScale;
    local bool bIsBlocking;

    bBlockedHS = false;

    if (bServerBlock && !IsTweening(1))
    {
        bIsBlocking = true;
        AddScale = AdditionalScale + BlockAddScale;
    }
    else
        AddScale = AdditionalScale + 1.0;

    if (Super.IsHeadShot(Loc, Ray, AddScale))
    {
        if (bIsBlocking)
        {
            D = vector(Rotation) dot Ray;
            if (-D > 0.20) {
                bBlockedHS = true;
                return false;
            }
            else
                return true;
        }
        else
            return true;
    }
    else
        return false;
}

// Damage, which doen't make headshots, always does full damage to Brute
// Melee weapon resistance is applied only while blocking
function TakeDamage(int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamType, optional int HitIndex)
{
    local bool bIsHeadShot;
    local class<KFWeaponDamageType> KFDamType;

    KFDamType = class<KFWeaponDamageType>(DamType);

    // damage, which doen't make headshots, always does full damage to Brute -- PooSH
    if (KFDamType != none && KFDamType.default.bCheckForHeadShots) {

        bIsHeadShot = IsHeadShot(HitLocation, normal(Momentum), 1.0);

        if (!bIsHeadShot && bBlockedHS)
        {
            if (class<KFProjectileWeaponDamageType>(DamType) != none)
                PlaySound(class'MetalHitEmitter'.default.ImpactSounds[rand(3)],, 128);
            else if (class<DamTypeChainsaw>(DamType) != none)
                PlaySound(Sound'KF_ChainsawSnd.Chainsaw_Impact_Metal',, 128);
            else if (class<DamTypeMelee>(DamType) != none)
                PlaySound(Sound'KF_KnifeSnd.Knife_HitMetal',, 128);

            if ( KFDamType.default.bDealBurningDamage && !KFDamType.default.bIsPowerWeapon )
                Damage *= BlockFireDmgMul; // Fire damage isn't reduced as much, excluding TrenchGun
            else
                Damage *= BlockDmgMul; // Greatly reduce damage as we only hit the metal plating
        }
        else if ( bServerBlock && class<DamTypeMelee>(DamType) != none )
            Damage *= BlockMeleeDmgMul; // Give Brute higher melee damage resistance, but apply it only if Brute is blocking
        else if ( bIsHeadShot ) {
            if ( KFDamType.default.bIsPowerWeapon )
                Damage *= HeadShotgunDmgMul; // Give Brute's head resistance to stotguns
            else if ( !KFDamType.default.bSniperWeapon && !KFDamType.default.bIsMeleeDamage )
                Damage *= HeadBulletDmgMul; // Give damage bonus to commando and gunslinger weapons
        }
    }

    // Record damage over 2-second frames
    if (LastDamagedTime < Level.TimeSeconds)
    {
        TwoSecondDamageTotal = 0;
        LastDamagedTime = Level.TimeSeconds + 2;
    }
    TwoSecondDamageTotal += Damage;

    // If criteria is met make him rage
    if (!bDecapitated && !bChargingPlayer && TwoSecondDamageTotal > RageDamageThreshold)
    {
        StartCharging();
        if (InstigatedBy != None)
            if (Controller.Target != InstigatedBy)
                MonsterController(Controller).ChangeEnemy(InstigatedBy, Controller.CanSee(InstigatedBy));
    }

    if (InstigatedBy == none || KFDamType == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);

    if (bDecapitated)
        Died(InstigatedBy.Controller, DamType, HitLocation);
}

function TakeFireDamage(int Damage, Pawn Instigator)
{
    Super.TakeFireDamage(Damage, Instigator);

    // Adjust movement speed if not charging
    if (!bChargingPlayer)
    {
        if (bBurnified)
            GroundSpeed = GetOriginalGroundSpeed() * BurnGroundSpeedMul;
        else
            GroundSpeed = GetOriginalGroundSpeed();
    }
}

function ClawDamageTarget()
{
    local KFHumanPawn HumanTarget;
    local float UsedMeleeDamage;
    local Actor OldTarget;
    local name Sequence;
    local float Frame, Rate;
    local bool bHitSomeone;

    if (MeleeDamage > 1)
        UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));
    else
        UsedMeleeDamage = MeleeDamage;

    GetAnimParams(1, Sequence, Frame, Rate);

    if (Controller != none && Controller.Target != none)
    {
        if (Sequence == 'BruteRageAttack')
        {
            OldTarget = Controller.Target;
            foreach VisibleCollidingActors(class'KFHumanPawn', HumanTarget, MeleeRange + class'KFHumanPawn'.default.CollisionRadius)
            {
                bHitSomeone = ClawDamageSingleTarget(UsedMeleeDamage, HumanTarget);
            }
            Controller.Target = OldTarget;
            if (bHitSomeone)
                BlockHitsLanded++;
        }
        else if (Sequence != 'BruteAttack1' && Sequence != 'BruteAttack2' && Sequence != 'DoorBash') // Block attack
        {
            bHitSomeone = ClawDamageSingleTarget(UsedMeleeDamage, Controller.Target);
            if (bHitSomeone)
                BlockHitsLanded++;
        }
        else
            bHitSomeone = ClawDamageSingleTarget(UsedMeleeDamage, Controller.Target);

        if (bHitSomeone)
            PlaySound(MeleeAttackHitSound, SLOT_Interact, 1.25);
    }
}

function bool ClawDamageSingleTarget(float UsedMeleeDamage, Actor ThisTarget)
{
    local Pawn HumanTarget;
    local KFPlayerController HumanTargetController;
    local bool bHitSomeone;
    local float EnemyAngle;
    local vector PushForceVar;

    EnemyAngle = Normal(ThisTarget.Location - Location) dot vector(Rotation);
    if (EnemyAngle > 0)
    {
        Controller.Target = ThisTarget;
        if (MeleeDamageTarget(UsedMeleeDamage, vect(0, 0, 0)))
        {
            HumanTarget = KFHumanPawn(ThisTarget);
            if (HumanTarget != None)
            {
                EnemyAngle = (EnemyAngle * 0.5) + 0.5; // Players at sides get knocked back half as much
                PushForceVar = (PushForce * Normal(HumanTarget.Location - Location) * EnemyAngle) + PushAdd;
                if (!bChargingPlayer)
                    PushForceVar *= 0.85;

                // (!) I'm sure the VeterancyName string is localized but I'm not sure of another way compatible with ServerPerks
                if (KFPlayerReplicationInfo(HumanTarget.Controller.PlayerReplicationInfo).ClientVeteranSkill != none)
                    if (KFPlayerReplicationInfo(HumanTarget.Controller.PlayerReplicationInfo).ClientVeteranSkill
                        .default.VeterancyName == "Berserker")
                            PushForceVar *= 0.75;

                if (!(HumanTarget.Physics == PHYS_WALKING || HumanTarget.Physics == PHYS_NONE))
                    PushForceVar *= vect(1, 1, 0); // (!) Don't throw upwards if we are not on the ground - adjust for more flexibility

                HumanTarget.AddVelocity(PushForceVar);

                HumanTargetController = KFPlayerController(HumanTarget.Controller);
                if (HumanTargetController != None)
                    HumanTargetController.ShakeView(ShakeViewRotMag, ShakeViewRotRate, ShakeViewRotTime,
                        ShakeViewOffsetMag, ShakeViewOffsetRate, ShakeViewOffsetTime);

                bHitSomeone = true;
            }
        }
    }

    return bHitSomeone;
}

function StartCharging()
{
    // How many times should we hit before we cool down?
    if (Level.Game.NumPlayers <= 3)
        MaxRageCounter = 2;
    else
        MaxRageCounter = 3;

    RageCounter = MaxRageCounter;
    PlaySound(RageSound, SLOT_Talk, 255);
    GotoState('RageCharging');
}

state RageCharging
{
Ignores StartCharging;

    function PlayDirectionalHit(Vector HitLoc)
    {
        if (!bShotAnim)
            super.PlayDirectionalHit(HitLoc);
    }

    function bool CanGetOutOfWay()
    {
        return false;
    }

    function bool CanSpeedAdjust()
    {
        return false;
    }

    function BeginState()
    {
        bFrustrated = false;
        bChargingPlayer = true;
        RageSpeedTween = 0.0;
        if (Level.NetMode != NM_DedicatedServer)
            ClientChargingAnims();

        NetUpdateTime = Level.TimeSeconds - 1;
    }

    function EndState()
    {
        bChargingPlayer = false;

        BruteZombieController(Controller).RageFrustrationTimer = 0;

        if (Health > 0)
        {
            GroundSpeed = GetOriginalGroundSpeed();
            if (bBurnified)
                GroundSpeed *= BurnGroundSpeedMul;
        }

        if( Level.NetMode!=NM_DedicatedServer )
            ClientChargingAnims();

        NetUpdateTime = Level.TimeSeconds - 1;
    }

    function Tick(float Delta)
    {
        if (!bShotAnim)
        {
            RageSpeedTween = FClamp(RageSpeedTween + (Delta * 0.75), 0, 1.0);
            GroundSpeed = OriginalGroundSpeed + ((OriginalGroundSpeed * 0.75 / MaxRageCounter * (RageCounter + 1) * RageSpeedTween));
            if (bBurnified)
                GroundSpeed *= BurnGroundSpeedMul;
        }

        Global.Tick(Delta);
    }

    function Bump(Actor Other)
    {
        local KFMonster KFM;

        KFM = KFMonster(Other);

        // Hurt enemies that we run into while raging
        if (!bShotAnim && KFM != None && ZombieBrute(Other) == None && Pawn(Other).Health > 0)
            Other.TakeDamage(RageBumpDamage, self, Other.Location, Velocity * Other.Mass, class'DamTypePoundCrushed');
        else Global.Bump(Other);
    }

    function bool MeleeDamageTarget(int HitDamage, vector PushDir)
    {
        local bool DamDone, bWasEnemy;

        bWasEnemy = (Controller.Target == Controller.Enemy);

        DamDone = Super.MeleeDamageTarget(HitDamage * RageDamageMul, vect(0, 0, 0));

        if (bWasEnemy && DamDone)
        {
            ChangeTarget();
            CalmDown();
        }

        return DamDone;
    }

    function CalmDown()
    {
        RageCounter = FClamp(RageCounter - 1, 0, MaxRageCounter);
        if (RageCounter == 0)
            GotoState('');
    }

    function ChangeTarget()
    {
        local Controller C;
        local Pawn BestPawn;
        local float Dist, BestDist;

        for (C = Level.ControllerList; C != none; C = C.NextController)
            if (C.Pawn != none && KFHumanPawn(C.Pawn) != none)
            {
                Dist = VSize(C.Pawn.Location - Location);
                if (C.Pawn == Controller.Target)
                    Dist += GroundSpeed * 4;

                if (BestPawn == none)
                {
                    BestPawn = C.Pawn;
                    BestDist = Dist;
                }
                else if (Dist < BestDist)
                {
                    BestPawn = C.Pawn;
                    BestDist = Dist;
                }
            }

        if (BestPawn != none && BestPawn != Controller.Enemy)
            MonsterController(Controller).ChangeEnemy(BestPawn, Controller.CanSee(BestPawn));
    }
}

// Override to prevent stunning
function bool FlipOver()
{
    return false;
}

// Shouldn't fight with our own
function bool SameSpeciesAs(Pawn P)
{
    return (ZombieBrute(P) != none);
}

// ------------------------------------------------------
// Animation --------------------------------------------
// ------------------------------------------------------

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
    if (Level.TimeSeconds - LastPainAnim < MinTimeBetweenPainAnims)
        return;

    // Uncomment this if we want some damage to make him drop his block
    /*if( !Controller.IsInState('WaitForAnim') && Damage >= 10 )
        PlayDirectionalHit(HitLocation);*/

    LastPainAnim = Level.TimeSeconds;

    if (Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds)
        return;

    LastPainSound = Level.TimeSeconds;
    PlaySound(HitSound[0], SLOT_Pain,1.25,,400);
}

// Overridden to handle playing upper body only attacks when moving
simulated event SetAnimAction(name NewAction)
{
    if (NewAction=='')
        return;

    if (NewAction == 'Claw')
    {
        NewAction = MeleeAnims[rand(2)];
        CurrentDamType = ZombieDamType[0];
    }
    else if (NewAction == 'BlockClaw')
    {
        NewAction = 'BruteBlockSlam';
        CurrentDamType = ZombieDamType[0];
    }
    else if (NewAction == 'AoeClaw')
    {
        NewAction = 'BruteRageAttack';
        CurrentDamType = ZombieDamType[0];
    }
    else if (NewAction == 'DoorBash')
        CurrentDamType = ZombieDamType[Rand(3)];

    ExpectingChannel = DoAnimAction(NewAction);

    if (AnimNeedsWait(NewAction))
        bWaitForAnim = true;
    else
        bWaitForAnim = false;

    if (Level.NetMode != NM_Client)
    {
        AnimAction = NewAction;
        bResetAnimAct = True;
        ResetAnimActTime = Level.TimeSeconds+0.3;
    }
}

simulated function int DoAnimAction( name AnimName )
{
    if (AnimName=='BruteAttack1' || AnimName=='BruteAttack2' || AnimName=='ZombieFireGun' || AnimName == 'DoorBash')
    {
        if (Role == ROLE_Authority)
            ServerLowerBlock();
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);
        return 1;
    }
    else if (AnimName == 'BruteRageAttack')
    {
        if (Role == ROLE_Authority)
            ServerLowerBlock();
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);
        return 1;
    }
    else if (AnimName == 'BlockLoop')
    {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        LoopAnim(AnimName,, 0.25, 1);
        return 1;
    }
    else if (AnimName == 'BruteBlockSlam')
    {
        AnimBlendParams(2, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 2);
        return 2;
    }
    return Super.DoAnimAction(AnimName);
}

// The animation is full body and should set the bWaitForAnim flag
simulated function bool AnimNeedsWait(name TestAnim)
{
    if (TestAnim == 'DoorBash')
        return true;

    return false;
}

simulated function AnimEnd(int Channel)
{
    local name Sequence;
    local float Frame, Rate;

    GetAnimParams(Channel, Sequence, Frame, Rate);

    // Don't allow notification for a looping animation
    if (Sequence == 'BlockLoop')
        return;

    // Disable channel 2 when we're done with it
    if (Channel == 2 && Sequence == 'BruteBlockSlam')
    {
        AnimBlendParams(2, 0);
        bShotAnim = false;
        return;
    }

    Super.AnimEnd(Channel);
}

simulated function ClientChargingAnims()
{
    PostNetReceive();
}

function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum, optional int HitIdx)
{
    local Actor A;
    if (bBlockedHS)
        A = Spawn(class'BlockHitEmitter', InstigatedBy,, HitLocation, rotator(Normal(HitLocation - Location)));
    else
        Super.PlayHit(Damage, InstigatedBy, HitLocation, damageType, Momentum, HitIdx);
}

defaultproperties
{
    RageDamageThreshold=50
    ChargingAnim="BruteRun"
    RageSound=SoundGroup'ScrnZedPack_S.Brute.BruteRage'
    ShakeViewRotMag=(X=500.000000,Y=500.000000,Z=600.000000)
    ShakeViewRotRate=(X=12500.000000,Y=12500.000000,Z=12500.000000)
    ShakeViewRotTime=6.000000
    ShakeViewOffsetMag=(X=5.000000,Y=10.000000,Z=5.000000)
    ShakeViewOffsetRate=(X=300.000000,Y=300.000000,Z=300.000000)
    ShakeViewOffsetTime=3.500000
    PushForce=860.000000
    PushAdd=(Z=150.000000)
    RageDamageMul=1.100000
    RageBumpDamage=4.000000
    BlockAddScale=2.500000
    BlockDmgMul=0.100000
    MeleeAnims(0)="BruteAttack1"
    MeleeAnims(1)="BruteAttack2"
    MeleeAnims(2)="BruteBlockSlam"
    MoanVoice=SoundGroup'ScrnZedPack_S.Brute.BruteTalk'
    BleedOutDuration=7.000000
    ZombieFlag=3
    MeleeDamage=20
    damageForce=25000
    bFatAss=True
    KFRagdollName="FleshPound_Trip"
    MeleeAttackHitSound=SoundGroup'ScrnZedPack_S.Brute.BruteHitPlayer'
    JumpSound=SoundGroup'ScrnZedPack_S.Brute.BruteJump'
    SpinDamConst=20.000000
    SpinDamRand=20.000000
    bMeleeStunImmune=True
    bUseExtendedCollision=True
    ColOffset=(Z=52.000000)
    ColRadius=35.000000
    ColHeight=25.000000
    SeveredArmAttachScale=1.300000
    SeveredLegAttachScale=1.200000
    SeveredHeadAttachScale=1.500000
    PlayerCountHealthScale=0.250000
    OnlineHeadshotOffset=(X=22.000000,Z=68.000000)
    OnlineHeadshotScale=1.300000
    MotionDetectorThreat=5.000000
    HitSound(0)=SoundGroup'ScrnZedPack_S.Brute.BrutePain'
    DeathSound(0)=SoundGroup'ScrnZedPack_S.Brute.BruteDeath'
    ChallengeSound(0)=SoundGroup'ScrnZedPack_S.Brute.BruteChallenge'
    ChallengeSound(1)=SoundGroup'ScrnZedPack_S.Brute.BruteChallenge'
    ChallengeSound(2)=SoundGroup'ScrnZedPack_S.Brute.BruteChallenge'
    ChallengeSound(3)=SoundGroup'ScrnZedPack_S.Brute.BruteChallenge'
    ScoringValue=60
    IdleHeavyAnim="BruteIdle"
    IdleRifleAnim="BruteIdle"
    RagDeathUpKick=100.000000
    MeleeRange=85.000000
    GroundSpeed=140.000000
    WaterSpeed=120.000000
    HeadHeight=2.500000
    HeadScale=1.300000
    MovementAnims(0)="BruteWalkC"
    MovementAnims(1)="BruteWalkC"
    WalkAnims(0)="BruteWalkC"
    WalkAnims(1)="BruteWalkC"
    WalkAnims(2)="RunL"
    WalkAnims(3)="RunR"
    IdleCrouchAnim="BruteIdle"
    IdleWeaponAnim="BruteIdle"
    IdleRestAnim="BruteIdle"
    AmbientSound=Sound'ScrnZedPack_S.Idle.BruteIdle1Shot'
    Mesh=SkeletalMesh'ScrnZedPack_A.BruteMesh'
    PrePivot=(Z=0.000000)
    Skins(0)=Combiner'ScrnZedPack_T.Brute.Brute_Final'
    Mass=600.000000
    RotationRate=(Yaw=45000,Roll=0)
    DetachedArmClass=Class'ScrnZedPack.SeveredArmBrute'
    DetachedLegClass=Class'ScrnZedPack.SeveredLegBrute'
    DetachedHeadClass=Class'ScrnZedPack.SeveredHeadBrute'
    ControllerClass=Class'ScrnZedPack.BruteZombieController'

    BlockMeleeDmgMul=0.500000
    HeadShotgunDmgMul=0.500000
    HeadBulletDmgMul=1.25
    BlockFireDmgMul=1.000000
    BurnGroundSpeedMul=0.600000
    HeadHealth=210
    PlayerNumHeadHealthScale=0.15
    HealthMax=1000.000000
    Health=1000
    MenuName="Brute.se"
}
