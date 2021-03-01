Class HardPat extends ZombieBoss;

var transient float GiveUpTime;
var int MissilesLeft;
var transient bool bFirstMissile;
var bool bEndGameBoss,bMovingChaingunAttack;
var(Sounds) sound SaveMeSound;

replication
{
    reliable if( ROLE==ROLE_AUTHORITY )
        bMovingChaingunAttack;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    SyringeCount = 3; // no healing for mid-game bosses
    Health *= 0.75; // less hp for mid-game bosses
}

function bool MakeGrandEntry()
{
    Health = HealthMax; // restore original hp
    bEndGameBoss = true;
    SyringeCount = 0; // restore healing for end-game boss
    return Super.MakeGrandEntry();
}
function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    Super(KFMonster).Died(Killer,damageType,HitLocation);
    if ( bEndGameBoss )
        KFGameType(Level.Game).DoBossDeath();
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    local coords C;
    local vector HeadLoc;
    local int look;
    local bool bUseAltHeadShotLocation;
    local bool bWasAnimating;

    if (HeadBone == '')
        return false;

    if (Level.NetMode == NM_DedicatedServer) {
        // If we are a dedicated server estimate what animation is most likely playing on the client
        if (Physics == PHYS_Falling) {
            log("Falling");
            PlayAnim(AirAnims[0], 1.0, 0.0);
        }
        else if (Physics == PHYS_Walking) {
            bWasAnimating = IsAnimating(0) || IsAnimating(1);
            if( !bWasAnimating ) {
                if (bIsCrouched) {
                    PlayAnim(IdleCrouchAnim, 1.0, 0.0);
                }
                else {
                    bUseAltHeadShotLocation=true;
                }
            }

            if ( bDoTorsoTwist ) {
                SmoothViewYaw = Rotation.Yaw;
                SmoothViewPitch = ViewPitch;

                look = (256 * ViewPitch) & 65535;
                if (look > 32768)
                    look -= 65536;

                SetTwistLook(0, look);
            }
        }
        else if (Physics == PHYS_Swimming) {
            PlayAnim(SwimAnims[0], 1.0, 0.0);
        }

        if( !bWasAnimating && !bUseAltHeadShotLocation ) {
            SetAnimFrame(0.5);
        }
    }

    if( bUseAltHeadShotLocation ) {
        HeadLoc = Location + (OnlineHeadshotOffset >> Rotation);
        AdditionalScale *= OnlineHeadshotScale;
    }
    else {
        C = GetBoneCoords(HeadBone);
        HeadLoc = C.Origin + (HeadHeight * HeadScale * AdditionalScale * C.XAxis);
    }

    return class'ScrnZedFunc'.static.TestHitboxSphere(HitLoc, Ray, HeadLoc,
            HeadRadius * HeadScale * AdditionalScale);
}

simulated function bool HitCanInterruptAction()
{
    return (!bWaitForAnim && !bShotAnim);
}

function RangedAttack(Actor A)
{
    local float D;
    local bool bOnlyE;
    local bool bDesireChainGun;

    // Randomly make him want to chaingun more
    if( Controller.LineOfSightTo(A) && FRand() < 0.15 && LastChainGunTime<Level.TimeSeconds )
    {
        bDesireChainGun = true;
    }

    if ( bShotAnim )
    {
        if( !IsAnimating(ExpectingChannel) )
            bShotAnim = false;
        return;
    }
    D = VSize(A.Location-Location);
    bOnlyE = (Pawn(A)!=None && OnlyEnemyAround(Pawn(A)));
    if ( IsCloseEnuf(A) )
    {
        bShotAnim = true;
        if( Health>1500 && Pawn(A)!=None && FRand() < 0.5 )
        {
            SetAnimAction('MeleeImpale');
        }
        else
        {
            SetAnimAction('MeleeClaw');
            //PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
        }
    }
    else if( Level.TimeSeconds>LastSneakedTime )
    {
        if( FRand() < 0.3 )
        {
            // Wait another 20-40 to try this again
            LastSneakedTime = Level.TimeSeconds+20.f+FRand()*20;
            Return;
        }
        SetAnimAction('transition');
        GoToState('SneakAround');
    }
    else if( bChargingPlayer && (bOnlyE || D<200) )
        Return;
    else if( !bDesireChainGun && !bChargingPlayer && (D<300 || (D<700 && bOnlyE)) &&
        (Level.TimeSeconds - LastChargeTime > (5.0 + 5.0 * FRand())) )  // Don't charge again for a few seconds
    {
        SetAnimAction('transition');
        GoToState('Charging');
    }
    else if( LastMissileTime<Level.TimeSeconds && (D>500 || SyringeCount>=2) )
    {
        if( !Controller.LineOfSightTo(A) || FRand() > 0.75 )
        {
            LastMissileTime = Level.TimeSeconds+FRand() * 5;
            Return;
        }

        LastMissileTime = Level.TimeSeconds + 10 + FRand() * 15;

        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('PreFireMissile');

        HandleWaitForAnim('PreFireMissile');

        GoToState('FireMissile');
    }
    else if ( !bWaitForAnim && !bShotAnim && LastChainGunTime<Level.TimeSeconds )
    {
        if ( !Controller.LineOfSightTo(A) || FRand()> 0.85 )
        {
            LastChainGunTime = Level.TimeSeconds+FRand()*4;
            Return;
        }

        LastChainGunTime = Level.TimeSeconds + 5 + FRand() * 10;

        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('PreFireMG');

        HandleWaitForAnim('PreFireMG');
        if ( bEndGameBoss )
            MGFireCounter = max(35, Rand(60) + 5 * Level.Game.GameDifficulty * (SyringeCount+1));
        else
            MGFireCounter = max(35, Rand(60) + 5 * Level.Game.GameDifficulty);


        GoToState('FireChaingun');
    }
}

simulated function bool AnimNeedsWait(name TestAnim)
{
    if( TestAnim == 'FireMG' )
        return !bMovingChaingunAttack;
    return Super.AnimNeedsWait(TestAnim);
}
simulated final function rotator GetBoneTransRot()
{
    local rotator R;

    R.Yaw = 24576+Rotation.Yaw;
    R.Pitch = 16384+Rotation.Pitch;
    return R;
}
simulated function int DoAnimAction( name AnimName )
{
    if( AnimName=='FireMG' && bMovingChaingunAttack )
    {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone, True);
        //SetBoneDirection(FireRootBone,GetBoneTransRot(),,1,1);
        PlayAnim('FireMG',, 0.f, 1);
        return 1;
    }
    else if( AnimName=='FireEndMG' )
    {
        //SetBoneDirection(FireRootBone,rot(0,0,0),,0,0);
        AnimBlendParams(1, 0);
    }
    return Super.DoAnimAction( AnimName );
}
simulated function AnimEnd(int Channel)
{
    local name  Sequence;
    local float Frame, Rate;

    if( Level.NetMode==NM_Client && bMinigunning )
    {
        GetAnimParams( Channel, Sequence, Frame, Rate );

        if( Sequence != 'PreFireMG' && Sequence != 'FireMG' )
        {
            //SetBoneDirection(FireRootBone,rot(0,0,0),,0,0);
            Super(KFMonster).AnimEnd(Channel);
            return;
        }

        if( bMovingChaingunAttack )
            DoAnimAction('FireMG');
        else
        {
            PlayAnim('FireMG');
            bWaitForAnim = true;
            bShotAnim = true;
            IdleTime = Level.TimeSeconds;
        }
    }
    else
    {
        //SetBoneDirection(FireRootBone,rot(0,0,0),,0,0);
        Super(KFMonster).AnimEnd(Channel);
    }
}

// Fix: Don't spawn needle before last stage.
simulated function NotifySyringeA()
{
    if( Level.NetMode!=NM_Client )
    {
        if( SyringeCount<3 )
            SyringeCount++;
        if( Level.NetMode!=NM_DedicatedServer )
             PostNetReceive();
    }
    if( Level.NetMode!=NM_DedicatedServer )
        DropNeedle();
}
simulated function NotifySyringeC()
{
    if( Level.NetMode!=NM_DedicatedServer )
    {
        CurrentNeedle = Spawn(Class'BossHPNeedle');
        CurrentNeedle.Velocity = vect(-45,300,-90) >> Rotation;
        DropNeedle();
    }
}

simulated function ZombieCrispUp() // Don't become crispy.
{
    bAshen = true;
    bCrispified = true;
    SetBurningBehavior();
}

state KnockDown
{
    Ignores RangedAttack;

Begin:
    if ( Health > 0 )
    {
        Sleep(GetAnimDuration('KnockDown'));
        CloakBoss();
        PlaySound(SaveMeSound, SLOT_Misc, 2.0,,500.0);

        if ( KFGameType(Level.Game).FinalSquadNum == SyringeCount )
        {
           KFGameType(Level.Game).AddBossBuddySquad();
        }

        GotoState('Escaping');
    }
    else
    {
       GotoState('');
    }
}
state FireChaingun
{
    function BeginState()
    {
        Super.BeginState();
        bMovingChaingunAttack = Level.Game.GameDifficulty >= 4 && SyringeCount >= 2 && (bEndGameBoss || FRand() < 0.4);
        bChargingPlayer = Level.Game.GameDifficulty >= 5 && bEndGameBoss && SyringeCount >= 3 && FRand() < 0.4f;
        bCanStrafe = true;
    }
    function EndState()
    {
        bChargingPlayer = false;
        Super.EndState();
        bMovingChaingunAttack = false;
        bCanStrafe = false;
    }
    function Tick( float Delta )
    {
        Super(KFMonster).Tick(Delta);
        if( bChargingPlayer )
            GroundSpeed = OriginalGroundSpeed * 2.3;
        else
            GroundSpeed = OriginalGroundSpeed * 1.15;
    }
    function AnimEnd( int Channel )
    {
        if( MGFireCounter <= 0 )
        {
            bShotAnim = true;
            Acceleration = vect(0,0,0);
            SetAnimAction('FireEndMG');
            HandleWaitForAnim('FireEndMG');
            GoToState('');
        }
        else if( bMovingChaingunAttack )
        {
            if( bFireAtWill && Channel!=1 )
                return;
            if( Controller.Target!=None )
                Controller.Focus = Controller.Target;
            bShotAnim = false;
            bFireAtWill = True;
            SetAnimAction('FireMG');
        }
        else
        {
            if ( Controller.Enemy != none )
            {
                if ( Controller.LineOfSightTo(Controller.Enemy) && FastTrace(GetBoneCoords('tip').Origin,Controller.Enemy.Location))
                {
                    MGLostSightTimeout = 0.0;
                    Controller.Focus = Controller.Enemy;
                    Controller.FocalPoint = Controller.Enemy.Location;
                }
                else
                {
                    MGLostSightTimeout = Level.TimeSeconds + (0.25 + FRand() * 0.35);
                    Controller.Focus = None;
                }
                Controller.Target = Controller.Enemy;
            }
            else
            {
                MGLostSightTimeout = Level.TimeSeconds + (0.25 + FRand() * 0.35);
                Controller.Focus = None;
            }

            if( !bFireAtWill )
            {
                MGFireDuration = Level.TimeSeconds + (0.75 + FRand() * 0.5);
            }
            else if ( FRand() < 0.03 && Controller.Enemy != none && PlayerController(Controller.Enemy.Controller) != none )
            {
                // Randomly send out a message about Patriarch shooting chain gun(3% chance)
                PlayerController(Controller.Enemy.Controller).Speech('AUTO', 9, "");
            }

            bFireAtWill = True;
            bShotAnim = true;
            Acceleration = vect(0,0,0);

            SetAnimAction('FireMG');
            bWaitForAnim = true;
        }
    }

    function FireMGShot()
    {
        super.FireMGShot();
        // stop charging on killing the enemy
        bChargingPlayer = bChargingPlayer && Controller.Enemy != none && Controller.Enemy.Health > 0;
    }

    function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
    {
        local float EnemyDistSq, DamagerDistSq;
        global.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);
        if( bMovingChaingunAttack || Health<=0 )
            return;

        // if someone close up is shooting us, just charge them
        if( InstigatedBy != none )
        {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

            if( (ChargeDamage > 200 && DamagerDistSq < (500 * 500)) || DamagerDistSq < (100 * 100) )
            {
                SetAnimAction('transition');
                GoToState('Charging');
                return;
            }
        }

        if( Controller.Enemy != none && InstigatedBy != none && InstigatedBy != Controller.Enemy )
        {
            EnemyDistSq = VSizeSquared(Location - Controller.Enemy.Location);
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
        }

        if( InstigatedBy != none && (DamagerDistSq < EnemyDistSq || Controller.Enemy == none) )
        {
            MonsterController(Controller).ChangeEnemy(InstigatedBy,Controller.CanSee(InstigatedBy));
            Controller.Target = InstigatedBy;
            Controller.Focus = InstigatedBy;

            if( DamagerDistSq < (500 * 500) )
            {
                SetAnimAction('transition');
                GoToState('Charging');
            }
        }
    }

Begin:
    While( True )
    {
        if( !bMovingChaingunAttack )
            Acceleration = vect(0,0,0);

        if( MGLostSightTimeout > 0 && Level.TimeSeconds > MGLostSightTimeout )
        {
            Acceleration = vect(0,0,0);
            bShotAnim = true;
            Acceleration = vect(0,0,0);
            SetAnimAction('FireEndMG');
            HandleWaitForAnim('FireEndMG');
            GoToState('');
        }

        if( MGFireCounter <= 0 )
        {
            bShotAnim = true;
            Acceleration = vect(0,0,0);
            SetAnimAction('FireEndMG');
            HandleWaitForAnim('FireEndMG');
            GoToState('');
        }

        // Give some randomness to the patriarch's firing (constantly fire after first stage passed)
        if( Level.TimeSeconds > MGFireDuration && SyringeCount==0 )
        {
            if( AmbientSound != MiniGunSpinSound )
            {
                SoundVolume=185;
                SoundRadius=200;
                AmbientSound = MiniGunSpinSound;
            }
            Sleep(0.5 + FRand() * 0.75);
            MGFireDuration = Level.TimeSeconds + (0.75 + FRand() * 0.5);
        }
        else
        {
            if( bFireAtWill )
                FireMGShot();
            Sleep(0.05);
        }
    }
}

state FireMissile
{
    function RangedAttack(Actor A)
    {
        if( SyringeCount>=2 )
        {
            Controller.Target = A;
            Controller.Focus = A;
        }
    }
    function BeginState()
    {
        if ( bEndGameBoss ) {
            MissilesLeft = 1 + Rand(SyringeCount+1);
            if (SyringeCount > 1 && Level.Game.GameDifficulty >= 5) {
                MissilesLeft += SyringeCount - 1;
            }
        }
        else if (Level.Game.GameDifficulty >= 5) {
            MissilesLeft = 1 + Rand(3);
        }
        else {
            MissilesLeft = 1 + Rand(2);
        }
        bFirstMissile = true;
        Acceleration = vect(0,0,0);
    }

    function AnimEnd( int Channel )
    {
        local vector Start;
        local Rotator R;

        Start = GetBoneCoords('tip').Origin;
        if( Controller.Target==None )
            Controller.Target = Controller.Enemy;

        if ( !SavedFireProperties.bInitialized )
        {
            SavedFireProperties.AmmoClass = MyAmmo.Class;
            SavedFireProperties.ProjectileClass = Class'BossLAWProj';
            SavedFireProperties.WarnTargetPct = 0.15;
            SavedFireProperties.MaxRange = 10000;
            SavedFireProperties.bTossed = False;
            SavedFireProperties.bLeadTarget = True;
            SavedFireProperties.bInitialized = true;
        }
        SavedFireProperties.bInstantHit = (SyringeCount<1);
        SavedFireProperties.bTrySplash = (SyringeCount>=2);

        R = AdjustAim(SavedFireProperties,Start,100);
        PlaySound(RocketFireSound,SLOT_Interact,2.0,,TransientSoundRadius,,false);
        Spawn(Class'BossLAWProj',,,Start,R);

        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('FireEndMissile');
        HandleWaitForAnim('FireEndMissile');

        // Randomly send out a message about Patriarch shooting a rocket
        // More rockets-in-a-raw = higher chance.
        if ( bFirstMissile && Controller.Enemy != none && PlayerController(Controller.Enemy.Controller) != none
            && frand() < 0.05 * MissilesLeft )
        {
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 10, "");
        }

        if( --MissilesLeft <= 0 )
            GoToState('');
        else {
            GoToState(,'SecondMissile');
        }
    }
Begin:
    while ( true )
    {
        Acceleration = vect(0,0,0);
        Sleep(0.1);
    }
SecondMissile:
    bFirstMissile = false;
    Acceleration = vect(0,0,0);
    Sleep(0.5f);
    AnimEnd(0);
}

State Escaping // Added god-mode if bEndGameBoss
{
Ignores RangedAttack;

    function BeginState()
    {
        GiveUpTime = Level.TimeSeconds+20.f+FRand()*20.f;
        Super.BeginState();
        if ( bEndGameBoss ) {
            bBlockActors = false;
            // While escaping Pat doesn't blow up pipebombs -- PooSH
            MotionDetectorThreat=0;
        }
    }
    function EndState()
    {
        Super.EndState();
        if( Health>0 )
            bBlockActors = true;
        MotionDetectorThreat = default.MotionDetectorThreat;
    }
    function Tick( float Delta )
    {
        if( Level.TimeSeconds>GiveUpTime )
        {
            BeginHealing();
            return;
        }
        if( !bChargingPlayer )
        {
            bChargingPlayer = true;
                if( Level.NetMode!=NM_DedicatedServer )
                    PostNetReceive();
            }
        GroundSpeed = OriginalGroundSpeed * 2.5;
        Global.Tick(Delta);
    }

    function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
    {
        if ( !bEndGameBoss )
            global.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);
    }
}

State SneakAround
{
    function BeginState()
    {
        super.BeginState();
        SneakStartTime = Level.TimeSeconds+10.f+FRand()*15.f;
    }
    function EndState()
    {
        super.EndState();
        LastSneakedTime = Level.TimeSeconds+20.f+FRand()*30.f;
        if( Controller!=None && Controller.IsInState('PatFindWay') )
            Controller.GoToState('ZombieHunt');
    }
    function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
    {
        global.TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);
        if( Health<=0 )
            return;

        // if someone close up is shooting us, just charge them
        if( InstigatedBy!=none && VSizeSquared(Location - InstigatedBy.Location)<62500 )
            GoToState('Charging');
    }

Begin:
    CloakBoss();
    if( SyringeCount>=2 && FRand()<0.6 )
        HardPatController(Controller).FindPathAround();
    While( true )
    {
        Sleep(0.5);

        if( !bCloaked && !bShotAnim )
            CloakBoss();
        if( !Controller.IsInState('PatFindWay') )
        {
            if( Level.TimeSeconds>SneakStartTime )
                GoToState('');
            if( !Controller.IsInState('WaitForAnim') && !Controller.IsInState('ZombieHunt') )
                Controller.GoToState('ZombieHunt');
        }
        else SneakStartTime = Level.TimeSeconds+30.f;
    }
}

defaultproperties
{
    ControllerClass=Class'ScrnZedPack.HardPatController'
    LODBias=4.000000
    MenuName="Hard Pat"
    ScoringValue=1000

    // copy-pasted from ZombieBoss_STANDARD
    RocketFireSound=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_FireRocket'
    MiniGunFireSound=Sound'KF_BasePatriarch.Attack.Kev_MG_GunfireLoop'
    MiniGunSpinSound=Sound'KF_BasePatriarch.Attack.Kev_MG_TurbineFireLoop'
    MeleeImpaleHitSound=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_HitPlayer_Impale'
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_HitPlayer_Fist'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmPatriarch'
    DetachedLegClass=Class'KFChar.SeveredLegPatriarch'
    DetachedHeadClass=Class'KFChar.SeveredHeadPatriarch'
    DetachedSpecialArmClass=Class'KFChar.SeveredRocketArmPatriarch'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd.Patriarch.Kev_Death'
    AmbientSound=Sound'KF_BasePatriarch.Idle.Kev_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks_Trip.Patriarch_Freak'
    Skins(0)=Combiner'KF_Specimens_Trip_T.gatling_cmb'
    Skins(1)=Combiner'KF_Specimens_Trip_T.patriarch_cmb'

    SaveMeSound=sound'KF_EnemiesFinalSnd.Patriarch.Kev_SaveMe'
}
