//-----------------------------------------------------------
//
//-----------------------------------------------------------
class StalkerH extends ZedBaseStalker;

#exec OBJ LOAD FILE=KF_EnemiesFinalSnd_HALLOWEEN.uax
#exec OBJ LOAD FILE=KF_Specimens_Trip_HALLOWEEN_T.utx


defaultproperties
{
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Talk'
    MoanVolume=1.000000
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmStalker_HALLOWEEN'
    DetachedLegClass=Class'KFChar.SeveredLegStalker_HALLOWEEN'
    DetachedHeadClass=Class'KFChar.SeveredHeadStalker_HALLOWEEN'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Stalker.Stalker_Challenge'
    GruntVolume=0.250000
    MenuName="Maggie May"
    AmbientSound=Sound'KF_BaseStalker.Stalker_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks_Trip_HALLOWEEN.Stalker_Halloween'
    Skins[0]=Combiner'KF_Specimens_Trip_HALLOWEEN_T.stalker.stalker_RedneckZombie_CMB';
    Skins[1]=Combiner'KF_Specimens_Trip_HALLOWEEN_T.stalker.stalker_RedneckZombie_CMB';
    CloackSkin=Shader'KF_Specimens_Trip_HALLOWEEN_T.stalker.stalker_Redneck_Invisible'
    TransientSoundVolume=0.600000
}
