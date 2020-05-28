// most of the code c&p from ZEDBeamEffect

class TeslaBeam extends xEmitter;

var array<TeslaBeam> ChildBeams;

var Actor StartActor, EndActor; // actors to chain with beam
var name StartBoneName, EndBoneName; // bone names of StartActor/EndActor to use for beam ending locations

var transient float EffectEndTime; // time when beam should be hidden. 0 - don't hide

var ZedBeamSparks            Sparks;
var Vector    PrevLoc;
var Rotator PrevRot;


var Vector    StartEffect, EndEffect;

var transient protected bool bInstigatorReplicated; // not sure if we need this
var transient protected float DestroyTime;

replication
{
    reliable if ( Role == ROLE_Authority && bNetDirty )
        StartActor, EndActor, StartBoneName, EndBoneName,
        EffectEndTime;
}

simulated function PostNetReceive()
{
    bInstigatorReplicated = bInstigatorReplicated || Instigator != none;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( TeslaHusk(Owner) != none )
        Instigator = TeslaHusk(Owner);
}

// returns item index of ChildBeams array, which has ChainedActor as an EndActor
// returns -1, if ChainedActor isn't chained to EndActor
function int ChildIndex(Actor ChainedActor)
{
    local int i;

    if ( ChainedActor != none ) {
        for ( i=0; i<ChildBeams.Length; ++i ) {
            if ( ChildBeams[i] != none && ChildBeams[i].EndActor == ChainedActor)
                return i;
        }
    }

    return -1;
}

function bool IsChainedTo(Actor Other, optional byte ChainLevel)
{
    local int i;

    if ( Other == none || ChainLevel > 100 ) // prevents circular links
        return false;

    for ( i=0; i<ChildBeams.Length; ++i ) {
        if ( ChildBeams[i] != none && (ChildBeams[i].EndActor == Other || ChildBeams[i].IsChainedTo(Other, ChainLevel+1)) )
            return true;
    }

    return false;
}

function DestroyChildBeams()
{
    local int i;

    for ( i=0; i<ChildBeams.Length; ++i ) {
        if ( ChildBeams[i] != none ) {
            ChildBeams[i].Instigator = none;
        }
    }
    ChildBeams.Length = 0;
}

simulated function Destroyed()
{
    if ( Sparks != None )
    {
        Sparks.SetTimer(0, false);
        Sparks.mRegen = false;
        Sparks.LightType = LT_None;
    }

    if ( ChildBeams.Length > 0 )
        DestroyChildBeams();

    Super.Destroyed();
}

simulated function SetBeamLocation()
{
    if ( StartBoneName == '' )
        StartEffect = StartActor.Location;
    else {
        StartEffect = StartActor.GetBoneCoords(StartBoneName).Origin;
    }

    if ( EndBoneName == '' )
        EndEffect = EndActor.Location;
    else {
        EndEffect = EndActor.GetBoneCoords(EndBoneName).Origin;
    }

    SetLocation(StartEffect);
    bHidden = false;
}

simulated function Vector SetBeamRotation()
{
    SetRotation(Rotator(EndEffect - StartEffect));

    return Normal(EndEffect - StartEffect);
}

simulated function bool CheckMaxEffectDistance(PlayerController P, vector SpawnLocation)
{
    return !P.BeyondViewDistance(SpawnLocation,1000);
}


simulated function Tick(float dt)
{
    local float LocDiff, RotDiff, WiggleMe;
    local Vector BeamDir;
    local PlayerController LocalPC;

    if ( Instigator == none ) {
        if ( Role == ROLE_Authority ) {
            if ( Level.NetMode != NM_Standalone && DestroyTime == 0 )
                DestroyTime = Level.TimeSeconds + 1.0; // give some time to replicate
            else if ( DestroyTime < Level.TimeSeconds )
                Destroy();
        }
        else if ( bInstigatorReplicated )
            Destroy();

        bHidden = true;
    }
    else {
        bHidden = StartActor == none || EndActor == none || (EffectEndTime != 0 && EffectEndTime < Level.TimeSeconds);
    }
    if ( Sparks != none )
        Sparks.bHidden = bHidden;
    if ( bHidden ) {
        if ( ChildBeams.Length > 0 )
            DestroyChildBeams(); // destroy them, because they are comming from the EndActor
        return;
    }

    // set beam start location
    SetBeamLocation();
    BeamDir = SetBeamRotation();

    if ( Level.NetMode != NM_DedicatedServer )
    {
        if ( Sparks == None && EffectIsRelevant(EndEffect, false) )
        {
            LocalPC = Level.GetLocalPlayerController();
            if ( LocalPC != none && CheckMaxEffectDistance(LocalPC, Location) )
                Sparks = Spawn(class'ZedBeamSparks', self);
        }
    }

    /*
    if ( Level.bDropDetail || Level.DetailMode == DM_Low )
    {
        bDynamicLight = false;
        LightType = LT_None;
    }
    else if ( bDynamicLight )
        LightType = LT_Steady;
    */

    mSpawnVecA = EndEffect;

    LocDiff            = VSize((Location - PrevLoc) * Vect(1,1,5));
    RotDiff            = VSize(Vector(Rotation) - Vector(PrevRot));
    WiggleMe        = FMax(LocDiff*0.02, RotDiff*4.0);
    mWaveAmplitude    = FMax(1.0, mWaveAmplitude - mWaveAmplitude*1.0*dt);
    mWaveAmplitude    = FMin(16.0, mWaveAmplitude + WiggleMe);

    PrevLoc = Location;
    PrevRot = Rotation;


    if ( Sparks != None )
    {
        Sparks.SetLocation( EndEffect - BeamDir*10.0 );
        Sparks.SetRotation( Rotation);
        Sparks.mRegenRange[0] = Sparks.DesiredRegen;
        Sparks.mRegenRange[1] = Sparks.DesiredRegen;
        Sparks.bDynamicLight = true;
    }
}

defaultproperties
{
     mParticleType=PT_Beam
     mMaxParticles=3
     mRegenDist=65.000000
     mSpinRange(0)=45000.000000
     mSizeRange(0)=6.000000
     mColorRange(0)=(B=240,G=240,R=240)
     mColorRange(1)=(B=240,G=240,R=240)
     mAttenuate=False
     mAttenKa=0.000000
     mWaveFrequency=0.060000
     mWaveAmplitude=8.000000
     mWaveShift=100000.000000
     mBendStrength=3.000000
     mWaveLockEnd=True
     LightHue=100
     LightSaturation=100
     LightBrightness=255.000000
     LightRadius=4.000000
     bNetTemporary=False
     bReplicateInstigator=True
     bReplicateMovement=False
     RemoteRole=ROLE_SimulatedProxy
     NetUpdateFrequency=5.000000
     LifeSpan=10.000000
     Skins(0)=FinalBlend'KFZED_FX_T.Energy.ZED_FX_Beam_FB'
     Style=STY_Additive
     bNetNotify=True
}
