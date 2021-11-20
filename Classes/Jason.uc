class Jason extends ZedBaseScrake;

#exec load obj file=ScrnZedPack_T.utx
#exec load obj file=ScrnZedPack_S.uax
#exec load obj file=ScrnZedPack_A.ukx

var transient bool bFlippedOver, bWasFlippedOver;
var transient float LastFlipOverTime;
var float FlipOverDuration;
var bool bWasRaged; // set to true, if Jason is raged or was raged before
var float RageHealthPct;


simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    FlipOverDuration = GetAnimDuration('KnockDown');
}

simulated function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    if ( bFlippedOver && Level.TimeSeconds > LastFlipOverTime + FlipOverDuration )
        bFlippedOver = false;
}

// Machete has no Exhaust ;)
simulated function SpawnExhaustEmitter() {}
simulated function UpdateExhaustEmitter() {}

function bool FlipOver()
{
    if ( bWasFlippedOver && Level.Game.GameDifficulty >= 7.0 )
        return false;  // on HoE, can be stunned only once

    bFlippedOver = super.FlipOver();
    if ( bFlippedOver ) {
        StunsRemaining = default.StunsRemaining;  // restore the default flich count on stun
        bWasFlippedOver = true;
        LastFlipOverTime = Level.TimeSeconds;
        // do not rotate while stunned
        Controller.Focus = none;
        Controller.FocalPoint = Location + 512*vector(Rotation);
    }
    return bFlippedOver;
}

function bool CanGetOutOfWay()
{
    return !bFlippedOver; // can't dodge husk fireballs while stunned
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamType, optional int HitIndex)
{
    local bool bIsHeadShot;
    local float headShotCheckScale;
    local class<KFWeaponDamageType> KFDamType;
    local int OldHealth, DamageDone;

    KFDamType = class<KFWeaponDamageType>(DamType);

    if ( InstigatedBy != none && KFDamType != none ) {
        if ( KFDamType.default.bCheckForHeadShots ) {
            headShotCheckScale= 1.0;
            if (class<DamTypeMelee>(DamType) != none) {
                headShotCheckScale*= 1.25;
            }
            bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), 1.0);
        }

        if ( ClassIsChildOf(DamType, class'DamTypePipeBomb') )
            Damage *= 1.5;
        else if ( bIsHeadShot && Level.Game.GameDifficulty >= 5.0 && class<DamTypeCrossbow>(DamType) != none )
            Damage *= 0.5;

        OldHealth = Health;
        super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
        DamageDone = OldHealth - Health;

        if ( !bDecapitated ) {
            if ( Level.Game.GameDifficulty >= 5.0 && !IsInState('SawingLoop') && !IsInState('RunningState') && float(Health) / HealthMax < RageHealthPct )
                    RangedAttack(InstigatedBy);
        }
    }
    else {
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    }

}

function RangedAttack(Actor A)
{
    if ( bShotAnim || Physics == PHYS_Swimming)
        return;
    else if ( CanAttack(A) )
    {
        bShotAnim = true;
        SetAnimAction(MeleeAnims[Rand(2)]);
        CurrentDamType = ZombieDamType[0];
        //PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
        GoToState('SawingLoop');
    }

    if( !bShotAnim && !bDecapitated ) {
        if ( bWasRaged || float(Health)/HealthMax < 0.5
                || (Level.Game.GameDifficulty >= 5.0 && float(Health)/HealthMax < RageHealthPct) )
            GoToState('RunningState');
    }
}

simulated function float GetOriginalGroundSpeed()
{
    local float result;

    result = OriginalGroundSpeed;
    if ( bWasRaged || bCharging )
        result *= 3.5;
    else if( bZedUnderControl )
        result *= 1.25;

    if ( bBurnified )
        result *= 0.8;

    return result;
}

state RunningState
{
    function BeginState()
    {
        bWasRaged = true;

        if( bZapped )
            GoToState('');
        else {
            bCharging = true;
            SetGroundSpeed(GetOriginalGroundSpeed());
            if( Level.NetMode!=NM_DedicatedServer )
                PostNetReceive();
            NetUpdateTime = Level.TimeSeconds - 1;
        }
    }

    function EndState()
    {
        bCharging = False;
        if( !bZapped )
            SetGroundSpeed(GetOriginalGroundSpeed());
        if( Level.NetMode!=NM_DedicatedServer )
            PostNetReceive();
    }

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
     RageHealthPct=0.750000
     SawAttackLoopSound=Sound'KF_BaseGorefast.Attack.Gorefast_AttackSwish3'
     StunsRemaining=5
     BleedOutDuration=7.000000
     MeleeDamage=25
     MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.GoreFast.Gorefast_HitPlayer'
     HeadHealth=800.000000
     ScoringValue=300
     HealthMax=1500.000000
     Health=1500
     MenuName="Jason"
     AmbientSound=Sound'ScrnZedPack_S.Jason.Jason_Sound'
     Mesh=SkeletalMesh'ScrnZedPack_A.JasonMesh'
     Skins(0)=Shader'ScrnZedPack_T.Jason.Jason__FB'
     Skins(1)=Texture'ScrnZedPack_T.Jason.JVMaskB'
     Skins(2)=Combiner'ScrnZedPack_T.Jason.Machete_cmb'
}
