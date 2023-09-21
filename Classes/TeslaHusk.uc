class TeslaHusk extends ZedBaseHusk;

#exec OBJ LOAD FILE=KF_EnemiesFinalSnd_CIRCUS.uax
#exec OBJ LOAD FILE=ScrnZedPack_A.ukx
#exec OBJ LOAD FILE=ScrnZedPack_T.utx
#exec OBJ LOAD FILE=ScrnZedPack_SM.usx


var class<TeslaBeam> BeamClass;
var TeslaBeam PrimaryBeam;
var float MaxPrimaryBeamRange; // how far Husk can shoot with his tesla gun?
var float MaxChildBeamRange; // max distance from primary target for a chain reaction
var float ChainedBeamRangeExtension; // if pawn is already chained, chain max range is multiplied by this value
var float MaxHealingRange; // how far Husk can heal zeds
// used for optimization
var transient float MaxPrimaryBeamRangeSquared, MaxChildBeamRangeSquared, MaxHealingRangeSquared;

var float Energy;
var float EnergyMax;
var float EnergyRestoreRate;

var()    float              DischargeDamage; // beam damage per second
var()    float              MaxDischargeTime;
var()    float              ChainDamageMult; // how much damage drops on the next chain
var()    class<DamageType>  MyDamageType;
var()    byte               MaxChainLevel;
var()    int                MaxChainActors;

var ZedBeamSparks           DecapitationSparks;

var bool    bChainThoughZED; // chain tesla beam though a zed, which is between target and the husk, to extend firing range
var transient float     NextChainZedSearchTime;
var transient float     NextChainRebuildTime; // how many seconds between rebuilding chained actors

var float DischargeRate; // time between damaging chained pawns. Do not set it too low due to rounding precission of DischargeDamage
var transient float LastDischargeTime;

// Tesla Husks are able to heal each other (and Fleshpounds)
var() float     HealRate, HealHeadRate;  // Percent of HealthMax to heal per second
var() float     HealEnergyDrain; // amount of energy required to heal 1%
var transient float NextHealAttemptTime, LastHealTime, NextHealTime;

var() float EmpDamagePerEnergy;
var() int EmpDamageMin;

var vector HeadOffset;


struct SActorDamages
{
    var Actor Victim;
    var int Damage;
};
var protected array<SActorDamages> DischargedActors;
var Pawn IntermediateTarget;

simulated function PostBeginPlay()
{
    // Difficulty Scaling
    if (Level.Game != none && !bDiffAdjusted)
    {
        if( Level.Game.GameDifficulty < 2.0 ) {
            // beginner
            DischargeDamage *= 0.50;
            EnergyMax *= 0.50;
            EnergyRestoreRate *= 0.50;
        }
        else if( Level.Game.GameDifficulty < 4.0 ) {
            // normal
        }
        else if( Level.Game.GameDifficulty < 5.0 ) {
            //hard
            DischargeDamage *= 1.35;
            EnergyMax *= 1.35;
            EnergyRestoreRate *= 1.35;
            MaxPrimaryBeamRange *= 1.35;
            MaxHealingRange *= 1.35;
            MaxChildBeamRange *= 1.35;
        }
        else if( Level.Game.GameDifficulty < 7.0 ) {
            // suicidal
            DischargeDamage *= 1.55;
            EnergyMax *= 1.55;
            EnergyRestoreRate *= 1.55;
            MaxPrimaryBeamRange *= 1.55;
            MaxChildBeamRange *= 1.55;
            MaxHealingRange *= 1.55;
            bChainThoughZED = true;
        }
        else {
            // HoE
            DischargeDamage *= 1.75;
            EnergyMax *= 1.75;
            EnergyRestoreRate *= 1.75;
            MaxPrimaryBeamRange *= 1.75;
            MaxChildBeamRange *= 1.75;
            MaxHealingRange *= 1.75;
            bChainThoughZED = true;
        }
    }
    Energy = EnergyMax;
    MaxPrimaryBeamRangeSquared = square(MaxPrimaryBeamRange);
    MaxChildBeamRangeSquared = square(MaxChildBeamRange);
    MaxHealingRangeSquared = square(MaxHealingRange);
    NextHealAttemptTime = Level.TimeSeconds + 5.0;

    super.PostBeginPlay();

    BurnDamageScale = 1.0; // no fire damage resistance
}

simulated function HideBone(name boneName)
{
    local int BoneScaleSlot;
    local bool bValidBoneToHide;

    if( boneName == LeftThighBone )
    {
        boneScaleSlot = 0;
        bValidBoneToHide = true;
    }
    else if ( boneName == RightThighBone )
    {
        boneScaleSlot = 1;
        bValidBoneToHide = true;
    }
    else if( boneName == RightFArmBone )
    {
        boneScaleSlot = 2;
        bValidBoneToHide = true;
    }
    else if ( boneName == LeftFArmBone )
    {
        boneScaleSlot = 3;
        bValidBoneToHide = true;
    }
    else if ( boneName == HeadBone )
    {
        // Only scale the bone down once
        if( SeveredHead == none )
        {
            bValidBoneToHide = true;
            boneScaleSlot = 4;
        }
        else
        {
            return;
        }
    }
    else if ( boneName == 'spine' )
    {
        bValidBoneToHide = true;
        boneScaleSlot = 5;
    }

    // Only hide the bone if it is one of the arms, legs, or head, don't hide other misc bones
    if( bValidBoneToHide )
    {
        SetBoneScale(BoneScaleSlot, 0.0, BoneName);
    }
}

function TeslaBeam SpawnTeslaBeam()
{
    local TeslaBeam beam;

    beam = spawn(BeamClass, self);
    if ( beam != none ) {
        beam.Instigator = self;
    }

    return beam;
}

function TeslaBeam SpawnPrimaryBeam()
{
    if ( PrimaryBeam == none ) {
        PrimaryBeam = SpawnTeslaBeam();
        PrimaryBeam.StartActor = self;
        PrimaryBeam.StartBoneName = 'Barrel';
    }
    return PrimaryBeam;
}

function FreePrimaryBeam()
{
    if ( PrimaryBeam != none ) {
        //PrimaryBeam.DestroyChildBeams();
        PrimaryBeam.EndActor = none;
        PrimaryBeam.EffectEndTime = Level.TimeSeconds - 1;
        PrimaryBeam.Instigator = none; // mark to delete
        PrimaryBeam = none;
    }
}

function TeslaBeam SpawnChildBeam(TeslaBeam MasterBeam, Actor EndActor)
{
    local TeslaBeam ChildBeam;

    ChildBeam = SpawnTeslaBeam();
    if ( ChildBeam != none ) {
        ChildBeam.StartActor = MasterBeam.EndActor;
        ChildBeam.EndActor = EndActor;
        ChildBeam.EffectEndTime = MasterBeam.EffectEndTime;
        MasterBeam.ChildBeams[MasterBeam.ChildBeams.length] = ChildBeam;
    }
    return ChildBeam;
}

function RangedAttack(Actor A)
{
    local float Dist;
    local KFMonster M;
    local bool bShoot;

    if ( bShotAnim || bDecapitated )
        return;

    // better to heal than attack some crap
    if ( KFPawn(A) == none && TryHealing() )
        return;

    Dist = VSize(A.Location - Location);


    if ( Physics == PHYS_Swimming )
    {
        SetAnimAction('Claw');
        bShotAnim = true;
    }
    else if ( (Energy < 30 || Level.TimeSeconds < NextFireProjectileTime)
            && Dist < MeleeRange + CollisionRadius + A.CollisionRadius )
    {
        // do melee hits only when low on energy
        bShotAnim = true;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }

    if ( Energy > 25 && Level.TimeSeconds > NextFireProjectileTime ) {
        if ( Dist < MaxPrimaryBeamRange*(0.7 + 0.3*frand()) )
        {
            IntermediateTarget = none;
            bShoot = true;
        }
        else if ( (Level.TimeSeconds < NextHealAttemptTime || !TryHealing())
                    && bChainThoughZED && Energy > 50 && Level.TimeSeconds > NextChainZedSearchTime
                    && Controller.Enemy == A && KFPawn(A) != none
                    && Dist < MaxPrimaryBeamRange * 1.9 )
            {
                NextChainZedSearchTime = Level.TimeSeconds + 1.0;
                foreach VisibleCollidingActors(class'KFMonster', M, MaxPrimaryBeamRange*0.9) {
                    if ( !M.bDeleteMe && M.Health > 0 && TeslaHusk(M) == none
                            && VSizeSquared(M.Location - A.Location) < MaxPrimaryBeamRangeSquared
                            && M.FastTrace(A.Location, M.Location) )
                    {
                        IntermediateTarget = M;
                        bShoot = true;
                        break;
                    }
                }
            }
    }

    if ( bShoot ) {
        bShotAnim = true;
        SetAnimAction('ShootBurns');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
        NextFireProjectileTime = Level.TimeSeconds + MaxDischargeTime + ProjectileFireInterval * (0.8 + 0.4*frand());
    }
}

function Heal(KFMonster Patient, float dt);

function n_SpawnBeam()
{
    if ( Controller == none || Controller.Target == none )
        return;

    if ( IntermediateTarget != none ) {
        if ( !Controller.LineOfSightTo(IntermediateTarget)
                || !FastTrace(IntermediateTarget.Location, Controller.Target.Location) )
            return;

        SpawnPrimaryBeam();
        PrimaryBeam.EndActor = IntermediateTarget;
        PrimaryBeam.EffectEndTime = Level.TimeSeconds + MaxDischargeTime;
        SpawnChildBeam(PrimaryBeam, Controller.Target);
        GotoState('Shooting');
    }
    else if ( Controller.LineOfSightTo(Controller.Target) ) {
        SpawnPrimaryBeam();
        PrimaryBeam.EndActor = Controller.Target;
        PrimaryBeam.EffectEndTime = Level.TimeSeconds + MaxDischargeTime;
        GotoState('Shooting');
    }
}

function SpawnTwoShots()
{
    warn("TeslaHuks.SpawnTwoShots() must not be called");
}

simulated function Tick(float dt)
{
    if ( Role < ROLE_Authority ) {
        if ( bDecapitated && Health > 0 && DecapitationSparks == none ) {
            SpawnDecapitationEffects();
        }
    }

    super.Tick(dt);

    if ( Role == ROLE_Authority ) {
        if ( Energy < EnergyMax )
            Energy += EnergyRestoreRate * dt;

        if ( Energy > 50 && Level.TimeSeconds > NextHealAttemptTime ) {
            NextHealAttemptTime = Level.TimeSeconds + 3.0;
            TryHealing();
        }
    }
}

function bool TryHealing()
{
    local Controller C;
    local KFMonsterController MyMC;
    local KFMonster BestPatient, Candidate;
    local int MaxHealing;
    local bool bAnyPatients;

    if ( Energy < 25 )
        return false;

    MyMC = KFMonsterController(Controller);
    if ( MyMC == none )
        return false; // just in case

    if ( MyMC.Enemy != none && VSizeSquared(MyMC.Enemy.Location - Location) < MaxPrimaryBeamRange )
        return false; // no healing when need to fight

    for ( C=Level.ControllerList; C!=none; C=C.NextController ) {
        Candidate = KFMonster(C.Pawn);
        if ( Candidate != none && Candidate != self && Candidate.Health > 0
                && (Candidate.IsA('TeslaHusk') || Candidate.IsA('ZombieFleshpound') || Candidate.IsA('FemaleFP')) )
        {
            bAnyPatients = true;
            if ( Candidate.HealthMax - Candidate.Health > MaxHealing
                    && VSizeSquared(Candidate.Location - Location) < MaxHealingRangeSquared
                    && FastTrace(Candidate.Location, Location) )
                BestPatient = Candidate;
                MaxHealing = Candidate.HealthMax - Candidate.Health;
        }
    }

    if ( !bAnyPatients ) {
        NextHealAttemptTime = Level.TimeSeconds + 10.0; // no other husks on the map - so no need to do searching so often
    }
    else if ( BestPatient != none ) {
        if ( BestPatient.Health < BestPatient.HealthMax * 0.95 ) {
            IntermediateTarget = BestPatient;
            GotoState('Healing');
            return true;
        }
        else
            NextHealAttemptTime = Level.TimeSeconds + 1.0; // if there are other Tesla Husks nearby, then check their health each second
    }
    else {
        NextHealAttemptTime = Level.TimeSeconds + 3.0; // there are other Tesla Husks on the map, but not too close
    }
    return false;
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    if ( PrimaryBeam != none )
        PrimaryBeam.Instigator = none;
    if ( DecapitationSparks != none )
        DecapitationSparks.Destroy();

    AmbientSound = none;

    super.Died(Killer, damageType, HitLocation);
}

simulated event PlayDying(class<DamageType> DamageType, vector HitLoc)
{
    super.PlayDying(DamageType, HitLoc);

    if ( DecapitationSparks != none )
        DecapitationSparks.Destroy();

    AmbientSound = none;
}

// instead of roaming around, activate self-destruct
function RemoveHead()
{
    Intelligence = BRAINS_Retarded; // Headless dumbasses!

    bDecapitated  = true;
    DECAP = true;
    DecapTime = Level.TimeSeconds;

    bShotAnim = true;
    SetAnimAction('KnockDown');
    Acceleration = vect(0, 0, 0);
    Velocity.X = 0;
    Velocity.Y = 0;
    Controller.GoToState('WaitForAnim');
    KFMonsterController(Controller).bUseFreezeHack = True;
    SetGroundSpeed(0);
    AirSpeed = 0;
    WaterSpeed = 0;

    // No more raspy breathin'...cuz he has no throat or mouth :S
    AmbientSound = MiscSound;

    // super.TakeDamage(LastDamageAmount) isn't called yet, so set self-destruct sequence only if
    // zed can survive the hit
    if( Health > LastDamageAmount ) {
        SpawnDecapitationEffects();
        BleedOutTime = Level.TimeSeconds +  BleedOutDuration;
        GotoState('SelfDestruct');
    }

    PlaySound(DecapitationSound, SLOT_Misc,1.30,true,525);
}

// Tesla Husk doesn't get stunned by weak sniper shots
// function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum, optional int HitIdx )
// {
    // super(KFMonster).PlayHit(Damage, InstigatedBy, HitLocation, damageType,  Momentum, HitIdx );
// }

simulated function Destroyed()
{
    if ( PrimaryBeam != none )
        PrimaryBeam.Destroy();

    if ( DecapitationSparks != none )
        DecapitationSparks.Destroy();

    super.Destroyed();
}

simulated function SpawnDecapitationEffects()
{
    if (Level.NetMode == NM_DedicatedServer)
        return;

    DecapitationSparks = spawn(class'ZedBeamSparks', self,, GetBoneCoords(HeadBone).Origin, Rotation);
}

simulated function int DoAnimAction( name AnimName )
{
    // faked animation with forces to play the end of shoot animation (where Huks is putting his gun down)
    if ( AnimName == 'ShootBurnsEnd' ) {
        PlayAnim('ShootBurns');
        SetAnimFrame(120, 0, 1);
        return 0;
    }
    return super.DoAnimAction(AnimName);
}

function bool HasRangedAttack()
{
    return true;
}

function float RangedAttackTime()
{
    return MaxDischargeTime + 1.0;
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, HeadOffset);
}

state Healing
{
    function BeginState()
    {
        local KFMonsterController MyMC;

        // log(">>> Healing @ " $ Level.TimeSeconds, 'TeslaHusk');
        MyMC = KFMonsterController(Controller);
        if ( MyMC == none || IntermediateTarget == none )
            return;

        MyMC.Target = IntermediateTarget;
        MyMC.ChangeEnemy(IntermediateTarget, MyMC.CanSee(IntermediateTarget));
        MyMC.GotoState('RangedAttack');
        NextHealTime = Level.TimeSeconds + 3.0; // do not heal until beam is spawned
    }

    function EndState()
    {
        local KFMonsterController MyMC;
        local name SeqName;
        local float AnimFrame, AnimRate;

        // log("<<< Healing @ " $ Level.TimeSeconds, 'TeslaHusk');
        NextHealAttemptTime = Level.TimeSeconds + 5.0;
        FreePrimaryBeam();

        // end shooting animation
        GetAnimParams(0, SeqName, AnimFrame, AnimRate);
        if ( SeqName == 'ShootBurns' && AnimFrame < 120 )
            SetAnimAction('ShootBurnsEnd'); // faked anim

        MyMC = KFMonsterController(Controller);
        if ( MyMC != none ) {
            MyMC.Enemy = none;
            MyMC.FindNewEnemy();
            MyMC.WhatToDoNext(200);
        }
    }

    function RangedAttack(Actor A)
    {
        if ( bShotAnim || A != IntermediateTarget )
            return;

        bShotAnim = true;
        SetAnimAction('ShootBurns');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }

    function bool TryHealing()
    {
        return false;
    }

    function n_SpawnBeam()
    {
        if ( Controller == none || !Controller.LineOfSightTo(IntermediateTarget) ) {
            GotoState('');
            return;
        }

        SpawnPrimaryBeam();
        PrimaryBeam.EndActor = IntermediateTarget;
        PrimaryBeam.EffectEndTime = Level.TimeSeconds + 1.0 / HealRate;
        Heal(KFMonster(Controller.Target), DischargeRate);
    }

    function Heal(KFMonster Patient, float dt)
    {
        local int HealthToAdd, HeadHealthToAdd;
        local int HeadHealthMax;

        if ( Patient == none || Patient.Health <= 0 || Patient.bDecapitated || Patient.Health >= Patient.HealthMax
                || Energy <= 0 )
        {
            GotoState('');
            return;
        }

        HealthToAdd = min(ceil(Patient.HealthMax * HealRate * dt), Patient.HealthMax - Patient.Health);
        HeadHealthMax = Patient.default.HeadHealth * Patient.DifficultyHeadHealthModifer() * Patient.NumPlayersHeadHealthModifer();
        HeadHealthToAdd = min(ceil(HeadHealthMax * HealHeadRate * dt), HeadHealthMax - Patient.HeadHealth);

        Energy -= (HealthToAdd + HeadHealthToAdd) * HealEnergyDrain;
        Patient.HeadHealth += HeadHealthToAdd;
        Patient.Health += HealthToAdd;

        LastHealTime = Level.TimeSeconds;
        NextHealTime = Level.TimeSeconds + DischargeRate;
    }

    function bool FlipOver()
    {
        if ( global.FlipOver() ) {
            GotoState('');
            return true;
        }
        return false;
    }

    function Tick(float dt)
    {
        super.Tick(dt);

        if ( Level.TimeSeconds > NextHealTime ) {
            if ( PrimaryBeam == none || Level.TimeSeconds > PrimaryBeam.EffectEndTime ) {
                GotoState('');
                return;
            }
            Heal(KFMonster(PrimaryBeam.EndActor), Level.TimeSeconds - LastHealTime);
        }
    }
}


// todo:  make custom controller, moving states there
state Shooting
{
    ignores RangedAttack;

    function BeginState()
    {
        //log(">>> Shooting @ " $ Level.TimeSeconds, 'TeslaHusk');

        if ( PrimaryBeam == none ) {
            SpawnPrimaryBeam();
            PrimaryBeam.EndActor = Controller.Target;
        }

        PrimaryBeam.EffectEndTime = Level.TimeSeconds + 2.5;
        BuildChain();
        LastDischargeTime = Level.TimeSeconds;
        Discharge(DischargeRate);
    }

    function EndState()
    {
        local name SeqName;
        local float AnimFrame, AnimRate;

        //log("<<< Shooting @ " $ Level.TimeSeconds, 'TeslaHusk');

        FreePrimaryBeam();
        NextChainRebuildTime = 0;

        // end shooting animation
        GetAnimParams(0, SeqName, AnimFrame, AnimRate);
        if ( SeqName == 'ShootBurns' && AnimFrame < 120 )
            SetAnimAction('ShootBurnsEnd'); // faked anim
    }

    function bool TryHealing()
    {
        return false;
    }

    function BuildChain()
    {
        local int ChainsRemaining;

        NextChainRebuildTime = Level.TimeSeconds + 1;
        ChainsRemaining = MaxChainActors;
        if ( PrimaryBeam != none && KFDoorMover(PrimaryBeam.EndActor) == none )
            SpawnChildBeams(PrimaryBeam, 1, ChainsRemaining);
    }

    function SpawnChildBeams(TeslaBeam MasterBeam, byte level, out int ChainsRemaining)
    {
        local Pawn P;
        local int i;

        if ( MasterBeam == none || level > MaxChainLevel || ChainsRemaining <= 0 )
            return;

        for ( i=0; i<MasterBeam.ChildBeams.length; ++i ) {
            if ( MasterBeam.ChildBeams[i] == none )
                MasterBeam.ChildBeams.remove(i--, 1);
        }

        if ( MasterBeam.EndActor == none || MasterBeam.EndActor.bDeleteMe )
            return;

        foreach MasterBeam.EndActor.VisibleCollidingActors(class'Pawn', P, MaxChildBeamRange, MasterBeam.EndActor.Location) {
            if ( !P.bDeleteMe && P.Health > 0 && P != MasterBeam.StartActor && P != MasterBeam.EndActor
                    && TeslaHusk(P) == none && !PrimaryBeam.IsChainedTo(P) )
            {
                i = MasterBeam.ChildIndex(P);
                if ( i != -1 ) {
                    MasterBeam.ChildBeams[i].EffectEndTime = MasterBeam.EffectEndTime;
                }
                else {
                    SpawnChildBeam(MasterBeam, P);
                }
                if ( --ChainsRemaining <= 0 )
                    return;
            }
        }

        for ( i=0; i<MasterBeam.ChildBeams.length && ChainsRemaining > 0; ++i ) {
            SpawnChildBeams(MasterBeam.ChildBeams[i], level+1, ChainsRemaining);
        }
    }

    function ChainDamage(TeslaBeam Beam, float Damage, byte ChainLevel)
    {
        local int i;
        local float DmgMult;

        if ( Beam == none || Beam.EndActor == none || Energy < 0)
            return;

        Damage = clamp(Damage, 1, Energy);

        // look if actor already received a damage during this discharge
        for ( i=0; i<DischargedActors.length; ++i ) {
            if ( DischargedActors[i].Victim == Beam.EndActor ) {
                if ( DischargedActors[i].Damage >= Damage )
                    return; // Victim already received enough damage
                else {
                    Damage -= DischargedActors[i].Damage;
                    DischargedActors[i].Damage += Damage;
                    break;
                }
            }
        }
        if ( i == DischargedActors.length ) {
            // new victim
            DischargedActors.insert(i, 1);
            DischargedActors[i].Victim = Beam.EndActor;
            DischargedActors[i].Damage = Damage;
        }

        // deal higher damage to monsters, but do not drain energy quicker
        DmgMult = 1.0;
        if ( KFMonster(Beam.EndActor) != none ) {
                DmgMult = 10.0;
        }
        // if pawn is already chained, then damage him until he gets out of the primary range
        Beam.SetBeamLocation(); // ensure that StartEffect and EndEffect are set
        if ( KFDoorMover(Beam.EndActor) != none ) {
            Beam.EndActor.TakeDamage(Damage*10.0,Self,Location,vect(0,0,0), class'DamTypeUnWeld');
        }
        else if ( VSizeSquared(Beam.EndEffect - Beam.StartEffect) <= MaxPrimaryBeamRangeSquared * ChainedBeamRangeExtension
                && FastTrace(Beam.EndEffect, Beam.StartEffect) )
        {
            Beam.EndActor.TakeDamage(Damage*DmgMult, self, Beam.EndActor.Location, Beam.SetBeamRotation(), MyDamageType);
            Energy -= Damage;

            Damage *= ChainDamageMult;
            ChainLevel++;
            if ( Damage > 0 && ChainLevel <= MaxChainLevel) {
                for ( i=0; i<Beam.ChildBeams.length && Energy > 0; ++i )
                    ChainDamage(Beam.ChildBeams[i], Damage, ChainLevel);
            }
        }
        else {
            Beam.Instigator = none; // delete beam
        }
    }

    function Discharge(float dt)
    {
        local int i;

        LastDischargeTime = Level.TimeSeconds;
        DischargedActors.length = 0;
        ChainDamage(PrimaryBeam, DischargeDamage*dt, 0);
        if ( Energy <= 0 ) {
            GotoState(''); // out of energy - stop shooting
            return;
        }
        if ( Controller != none && KFPawn(Controller.Enemy) != none ) {
            // stop shooting zeds if there are no players around
            for ( i = 0; i < DischargedActors.length; ++i ) {
                if ( KFPawn(DischargedActors[i].Victim) != none )
                    return;
            }
            // if reached here - no players got hit
            GotoState('');
        }
    }

    function bool FlipOver()
    {
        if ( global.FlipOver() ) {
            GotoState('');
            return true;
        }
        return false;
    }


    function Tick(float dt)
    {
        super.Tick(dt);

        if ( Energy <= 0 || PrimaryBeam == none || PrimaryBeam.EndActor == none
                || Level.TimeSeconds > PrimaryBeam.EffectEndTime ) {
            GotoState('');
        }
        else if ( Level.TimeSeconds > LastDischargeTime + DischargeRate ) {
            if ( Level.TimeSeconds > NextChainRebuildTime )
                BuildChain();

            Discharge(Level.TimeSeconds - LastDischargeTime); // damage chained actors
        }

    }
}

state SelfDestruct
{
    ignores PlayDirectionalHit, RangedAttack, MeleeDamageTarget;

    function BeginState()
    {
        local TeslaHuskEMPCharge MyNade;

        MyNade = spawn(class'TeslaHuskEMPCharge', self,, Location);
        if ( MyNade != none ) {
            AttachToBone(MyNade, RootBone);
            MyNade.SetTimer(3.0, false);
            MyNade.bTimerSet = true;
            MyNade.Damage = max(EmpDamageMin, Energy * EmpDamagePerEnergy);
            MyNade.Instigator = self;
            MyNade.InstigatorController = Controller;
            MyNade.Killer = LastDamagedBy;
            if ( LastDamagedBy != none ) {
                MyNade.KillerController = LastDamagedBy.Controller;
            }
        }
        else {
            // wtf?
            Died(LastDamagedBy.Controller,class'DamTypeBleedOut',Location);
        }


    }

    function bool CanGetOutOfWay()
    {
        return false;
    }

    // takes only 25% of damage
    function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
    {
        if ( InstigatedBy != self )
            Damage *= 0.25;
        global.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType,HitIndex);
    }
}

static function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.TeslaHusk.TeslaHusk_SHADER');
    myLevel.AddPrecacheMaterial(FinalBlend'KFZED_FX_T.Energy.ZED_FX_Beam_FB');
}


defaultproperties
{
    // copy-pasted from ZombieHusk_CIRCUS
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Bloat.Bloat_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Jump'
    ProjectileBloodSplatClass=None
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    AmbientSound=Sound'KF_BaseHusk_CIRCUS.Husk_IdleLoop'

    Mesh=SkeletalMesh'ScrnZedPack_A.TeslaHuskMesh'

    Skins(0)=Shader'ScrnZedPack_T.TeslaHusk.TeslaHusk_SHADER'

    DetachedArmClass=Class'SeveredArmTeslaHusk'
    DetachedSpecialArmClass=Class'SeveredGunTeslaHusk'
    DetachedLegClass=Class'SeveredLegTeslaHusk'
    DetachedHeadClass=Class'SeveredHeadTeslaHusk'

    DecapitationSound=Sound'KF_FY_ZEDV2SND.Fire.WEP_ZEDV2_Secondary_Explode'
    MiscSound=Sound'KF_FY_ZEDV2SND.foley.WEP_ZEDV2_Projectile_Loop' // used as ambient sound after decapitation

    MenuName="Tesla Husk"

    WaterSpeed=120 // 102
    GroundSpeed=150 // 115

    HeadOffset=(X=-5.0,Y=-2.0)
    OnlineHeadshotOffset=(X=22.000000,Z=50.000000)
    OnlineHeadshotScale=1.2
    ColOffset=(Z=36.000000)
    ColRadius=30.000000
    ColHeight=30

    HeadHealth=250 // Husk=200
    Health=800 // Husk = 600
    HealthMax=800 // Husk = 600
    ScoringValue=25 // Husk=17
    BurnDamageScale=1.0 // no fire damage resistance

    bMeleeFighter=false
    MaxHealingRange=500  // 10m
    MaxPrimaryBeamRange=300 // 6m
    MaxChildBeamRange=150 // 3m
    // 35% range increase for chained zed. E.g. pawn must get 300*1.35=405uu
    // away from Tesla Husk to get himself unchainsed
    ChainedBeamRangeExtension=1.35

    BeamClass=class'TeslaBeam'
    Energy=100
    EnergyMax=100
    EnergyRestoreRate=8
    ProjectileFireInterval=8.0
    BleedOutDuration=5.0

    DischargeRate=0.25
    DischargeDamage=10.00 // 20
    MaxDischargeTime=2.5
    ChainDamageMult=0.850 // 0.70
    MaxChainLevel=5
    MaxChainActors=20
    MyDamageType=class'DamTypeTeslaBeam'
    HealRate=0.25
    HealHeadRate=0.50
    HealEnergyDrain=0.05
    EmpDamagePerEnergy=0.65
    EmpDamageMin=30
}
