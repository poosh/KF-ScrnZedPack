class ClotG extends ZedBaseClot;

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
    DetachedArmClass="SeveredArmClot"
    DetachedLegClass="SeveredLegClot"
    DetachedHeadClass="SeveredHeadClot"

    Mesh=SkeletalMesh'KF_Freaks_Trip.CLOT_Freak'

    Skins(0)=Combiner'ScrnZedPack_T.clot_grittier.clot_grittier_cmb'

    AmbientSound=Sound'KF_BaseClot.Clot_Idle1Loop'//Sound'KFPlayerSound.Zombiesbreath'//
    MoanVoice=Sound'KF_EnemiesFinalSnd.Clot_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Clot_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Clot_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Clot_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Clot_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    MenuName="Grittier Clot"
}
