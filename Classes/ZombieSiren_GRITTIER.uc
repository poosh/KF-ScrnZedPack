class ZombieSiren_GRITTIER extends ZombieSiren;
#exec OBJ LOAD FILE=ScrnZedPack_T.utx

defaultproperties
{
    DetachedLegClass=class'SeveredLegSiren'
	DetachedHeadClass=class'SeveredHeadSiren'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Siren_Freak'

    Skins(0)=FinalBlend'KF_Specimens_Trip_T.siren_hair_fb'
    Skins(1)=Combiner'ScrnZedPack_T.siren_grittier_cmb'

    AmbientSound=Sound'KF_BaseSiren.Siren_IdleLoop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Siren_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Siren_Jump'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Siren_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Siren_Death'
    MenuName="Grittier Siren"
}

