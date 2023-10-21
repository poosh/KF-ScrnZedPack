//-----------------------------------------------------------
//
//-----------------------------------------------------------
class StalkerC extends ZedBaseStalker;

#exec OBJ LOAD FILE=KF_EnemiesFinalSnd_CIRCUS.uax
#exec OBJ LOAD FILE=KF_Specimens_Trip_CIRCUS_T.utx


defaultproperties
{
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmStalker_CIRCUS'
    DetachedLegClass=Class'KFChar.SeveredLegStalker_CIRCUS'
    DetachedHeadClass=Class'KFChar.SeveredHeadStalker_CIRCUS'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Stalker.Stalker_Challenge'
    MenuName="Assistant"
    AmbientSound=Sound'KF_BaseStalker.Stalker_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks_Trip_CIRCUS.stalker_CIRCUS'
    Skins[0]=Combiner'KF_Specimens_Trip_CIRCUS_T.stalker_CIRCUS.stalker_CIRCUS_CMB';
    Skins[1]=FinalBlend'KF_Specimens_Trip_CIRCUS_T.stalker_CIRCUS.stalker_CIRCUS_fb';
    CloackSkin=Shader'KF_Specimens_Trip_CIRCUS_T.stalker_CIRCUS.stalker_Invisible_CIRCUS_shdr'
}
