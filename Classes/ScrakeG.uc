class ScrakeG extends ZedBaseScrake;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

static function PreCacheMaterials(LevelInfo myLevel)
{
    local int i;

    for ( i = 0; i < default.Skins.length; ++i ) {
        myLevel.AddPrecacheMaterial(default.Skins[i]);
    }
}

defaultproperties
{
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
