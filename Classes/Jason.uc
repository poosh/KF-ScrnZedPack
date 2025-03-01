class Jason extends ZedBaseScrake;

#exec load obj file=ScrnZedPack_T.utx
#exec load obj file=ScrnZedPack_S.uax
#exec load obj file=ScrnZedPack_A.ukx

var float PipeBombDmgMult;
var bool bWasRaged; // set to true, if Scrake is raged or was raged before

// Machete has no Exhaust ;)
simulated function SpawnExhaustEmitter() {}
simulated function UpdateExhaustEmitter() {}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (ClassIsChildOf(DamType, class'DamTypePipeBomb')) {
        Damage *= PipeBombDmgMult;
    }
    super.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType, HitIndex);
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
        if (bWasRaged || ShouldRage())
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
    PipeBombDmgMult=1.5

    SawAttackLoopSound=Sound'KF_BaseGorefast.Attack.Gorefast_AttackSwish3'
    StunsRemaining=5
    BleedOutDuration=7.000000
    MeleeDamage=25
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.GoreFast.Gorefast_HitPlayer'
    HeadHealth=800.000000
    ScoringValue=125
    HealthMax=1500.000000
    Health=1500
    MenuName="Jason"
    AmbientSound=Sound'ScrnZedPack_S.Jason.Jason_Sound'
    Mesh=SkeletalMesh'ScrnZedPack_A.JasonMesh'
    Skins(0)=Shader'ScrnZedPack_T.Jason.Jason__FB'
    Skins(1)=Texture'ScrnZedPack_T.Jason.JVMaskB'
    Skins(2)=Combiner'ScrnZedPack_T.Jason.Machete_cmb'
}
