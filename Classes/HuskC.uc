// We use Circus Husk model for Tesla Husk. Use regular Husk in Circus mode.
class HuskC extends Husk;

#exec OBJ LOAD FILE=KF_EnemiesFinalSnd_CIRCUS.uax

var vector HeadOffset;

simulated function HideBone(name boneName)
{
    local int BoneScaleSlot;
    local bool bValidBoneToHide;

    if( boneName == LeftThighBone )
    {
        boneScaleSlot = 0;
        bValidBoneToHide = true;
    }
    else if ( boneName == RightThighBone )
    {
        boneScaleSlot = 1;
        bValidBoneToHide = true;
    }
    else if( boneName == RightFArmBone )
    {
        boneScaleSlot = 2;
        bValidBoneToHide = true;
    }
    else if ( boneName == LeftFArmBone )
    {
        boneScaleSlot = 3;
        bValidBoneToHide = true;
    }
    else if ( boneName == HeadBone )
    {
        // Only scale the bone down once
        if( SeveredHead == none )
        {
            bValidBoneToHide = true;
            boneScaleSlot = 4;
        }
        else
        {
            return;
        }
    }
    else if ( boneName == 'spine' )
    {
        bValidBoneToHide = true;
        boneScaleSlot = 5;
    }

    // Only hide the bone if it is one of the arms, legs, or head, don't hide other misc bones
    if( bValidBoneToHide )
    {
        SetBoneScale(BoneScaleSlot, 0.0, BoneName);
    }
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(default.Skins[0]);
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, HeadOffset);
}

defaultproperties
{
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Bloat.Bloat_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Jump'
    ProjectileBloodSplatClass=None
    DetachedArmClass=Class'KFChar.SeveredArmHusk_CIRCUS'
    DetachedLegClass=Class'KFChar.SeveredLegHusk_CIRCUS'
    DetachedHeadClass=Class'KFChar.SeveredHeadHusk_CIRCUS'
    DetachedSpecialArmClass=Class'KFChar.SeveredArmHusk_CIRCUS'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd_CIRCUS.Husk.Husk_Challenge'
    MenuName="Dancing Robot"
    AmbientSound=Sound'KF_BaseHusk_CIRCUS.Husk_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks2_Trip_CIRCUS.husk_CIRCUS'
    Skins(0)=Shader'KF_Specimens_Trip_CIRCUS_T.husk_CIRCUS.husk_shader'

    HeadOffset=(X=-5.0,Y=-2.0)
    OnlineHeadshotOffset=(X=22.000000,Z=50.000000)
    OnlineHeadshotScale=1.2
    ColOffset=(Z=36.000000)
    ColRadius=30.000000
    ColHeight=30
}
