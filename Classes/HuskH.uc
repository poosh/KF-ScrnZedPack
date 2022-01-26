//-----------------------------------------------------------
//
//-----------------------------------------------------------
class HuskH extends ZedBaseHusk;


#exec OBJ LOAD FILE=KF_EnemiesFinalSnd_HALLOWEEN.uax


defaultproperties
{
    AmmunitionClass=class'HuskAmmoH'

    MoanVoice=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Bloat.Bloat_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Jump'
    ProjectileBloodSplatClass=None
    DetachedArmClass=Class'KFChar.SeveredArmHusk_HALLOWEEN'
    DetachedLegClass=Class'KFChar.SeveredLegHusk_HALLOWEEN'
    DetachedHeadClass=Class'KFChar.SeveredHeadHusk_HALLOWEEN'
    DetachedSpecialArmClass=Class'KFChar.SeveredArmHuskGun_HALLOWEEN'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd_HALLOWEEN.Husk.Husk_Challenge'
    MenuName="Brother Sparky"
    AmbientSound=Sound'KF_BaseHusk_HALLOWEEN.Husk_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks2_Trip_HALLOWEEN.Husk_Halloween'
    Skins(0)=Combiner'KF_Specimens_Trip_HALLOWEEN_T.Husk.husk_RedneckZombie_CMB'
}
