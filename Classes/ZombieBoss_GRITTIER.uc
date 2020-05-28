class ZombieBoss_GRITTIER extends ZombieBoss;
#exec OBJ LOAD FILE=ScrnZedPack_T.utx

defaultproperties
{
    DetachedArmClass=class'SeveredArmPatriarch'
    DetachedSpecialArmClass=class'SeveredRocketArmPatriarch'
    DetachedLegClass=class'SeveredLegPatriarch'
    DetachedHeadClass=class'SeveredHeadPatriarch'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Patriarch_Freak'

    Skins(0)=Combiner'KF_Specimens_Trip_T.gatling_cmb'
    Skins(1)=Combiner'ScrnZedPack_T.patriarch_grittier.patriarch_grittier_cmb'

    AmbientSound=Sound'KF_BasePatriarch.Idle.Kev_IdleLoop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Kev_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Kev_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Kev_HitPlayer_Fist'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Kev_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Kev_Death'

    MeleeImpaleHitSound=sound'KF_EnemiesFinalSnd.Kev_HitPlayer_Impale'
    RocketFireSound=sound'KF_EnemiesFinalSnd.Kev_FireRocket'
    MiniGunFireSound=sound'KF_BasePatriarch.Kev_MG_GunfireLoop'
    MiniGunSpinSound=Sound'KF_BasePatriarch.Attack.Kev_MG_TurbineFireLoop'
    MenuName="Grittier Patriarch"
}
