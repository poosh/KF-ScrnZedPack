//-----------------------------------------------------------
//
//-----------------------------------------------------------
class StalkerX extends ZedBaseStalker;

#exec OBJ LOAD FILE=KF_EnemiesFinalSnd_Xmas.uax


defaultproperties
{
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmStalker_XMas'
    DetachedLegClass=Class'KFChar.SeveredLegStalker_XMas'
    DetachedHeadClass=Class'KFChar.SeveredHeadStalker_XMas'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd_Xmas.Stalker.Stalker_Challenge'
    MenuName="Mrs. Claws"
    AmbientSound=Sound'KF_BaseStalker.Stalker_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks_Trip_Xmas.StalkerClause'
    Skins[0]=Combiner'KF_Specimens_Trip_XMAS_T.StalkerClause.StalkerClause_cmb';
    Skins[1]=FinalBlend'KF_Specimens_Trip_XMAS_T.StalkerClause.StalkerClause_fb';
    CloackSkin=Shader'KF_Specimens_Trip_XMAS_T.StalkerClause.StalkerClause_invisible'
}
