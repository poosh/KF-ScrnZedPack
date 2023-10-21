class StalkerG extends ZedBaseStalker;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx


defaultproperties
{
    DetachedArmClass=class'SeveredArmStalker'
    DetachedLegClass=class'SeveredLegStalker'
    DetachedHeadClass=class'SeveredHeadStalker'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Stalker_Freak'
    Skins[0]=Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb';
    Skins[1]=FinalBlend'ScrnZedPack_T.stalker_grittier.stalker_grittier_fb';
    CloackSkin=Shader'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible'//Shader'KFCharacters.CloakShader';

    AmbientSound=Sound'KF_BaseStalker.Stalker_IdleLoop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Stalker_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Stalker_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Stalker_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Stalker_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Stalker_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    MenuName="Grittier Stalker"
}
