// Code originally was taken from Scary Ghost's Super Zombies mutator
class HuskG extends ZedBaseHusk;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.husk_grittier.husk_grittier_diff');
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.husk_grittier.husk_grittier_emissive_mask');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_energy_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_env_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_fire_cmb');
    myLevel.AddPrecacheMaterial(Material'ScrnZedPack_T.husk_grittier.husk_grittier_shdr');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_cmb');
}

simulated function PostBeginPlay()
{
    if ( Level.Game != none ) {
        if ( Level.Game.GameDifficulty < 5 ) {
            ShotsRemaining = 2; // max two shots in a row on Hard an below
        }
        else if ( Level.Game.GameDifficulty < 7 ) {
            ShotsRemaining--;  // one less shot on Suicidal
        }
        // on HoE, use default.ShotsRemaining
    }
    super.PostBeginPlay();
}


defaultproperties
{
    HuskFireProjClass=class'HuskFireProjectileSE'

    DetachedArmClass=class'SeveredArmHusk'
    DetachedSpecialArmClass=class'SeveredArmHuskGun'
    DetachedLegClass=class'SeveredLegHusk'
    DetachedHeadClass=class'SeveredHeadHusk'

    Mesh=SkeletalMesh'KF_Freaks2_Trip.Burns_Freak'

    Skins(0)=Texture'ScrnZedPack_T.husk_grittier.husk_grittier_tatters'
    Skins(1)=Shader'ScrnZedPack_T.husk_grittier.husk_grittier_shdr'

    AmbientSound=Sound'KF_BaseHusk.Husk_IdleLoop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Husk_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Husk_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Bloat_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Husk_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Husk_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'

    MenuName="Grittier Husk"
    ShotsRemaining=4
    MaxMeleeAttacks=1
    ControllerClass=Class'ZedControllerHuskG'
}
