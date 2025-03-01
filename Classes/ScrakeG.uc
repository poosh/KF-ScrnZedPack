class ScrakeG extends ZedBaseScrake;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

var float ExplosiveUnstunThreshold;
var bool bWasRaged; // set to true, if Scrake is raged or was raged before


function bool ShouldDamageUnstun(int Damage, class<DamageType> DamType)
{
    local class<KFWeaponDamageType> KFDamType;

    KFDamType = class<KFWeaponDamageType>(DamType);
    if (KFDamType == none)
        return false;

    return KFDamType.default.bIsExplosive && Damage >= ExplosiveUnstunThreshold;
}

static function PreCacheMaterials(LevelInfo myLevel)
{
    local int i;

    for ( i = 0; i < default.Skins.length; ++i ) {
        myLevel.AddPrecacheMaterial(default.Skins[i]);
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

defaultproperties
{
    ExplosiveUnstunThreshold=150

    DetachedArmClass=class'SeveredArmScrake'
    DetachedSpecialArmClass=class'SeveredArmScrakeSaw'
    DetachedLegClass=class'SeveredLegScrake'
    DetachedHeadClass=class'SeveredHeadScrake'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Scrake_Freak'

    Skins(0)=Shader'ScrnZedPack_T.scrake_grittier_FB'
    Skins(1)=TexPanner'KF_Specimens_Trip_T.scrake_saw_panner'

    AmbientSound=Sound'KF_BaseScrake.Scrake_Chainsaw_Idle'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Scrake_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Scrake_Jump'
    MeleeAttackHitSound=Sound'KF_EnemiesFinalSnd.Scrake_Chainsaw_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Scrake_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Scrake_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Scrake_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Scrake_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Scrake_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Scrake_Challenge'

    SawAttackLoopSound=Sound'KF_BaseScrake.Scrake_Chainsaw_Impale'
    ChainSawOffSound=Sound'KF_ChainsawSnd.Chainsaw_Deselect'
    MenuName="Grittier Scrake"
}
