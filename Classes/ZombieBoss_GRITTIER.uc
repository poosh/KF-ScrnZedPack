class ZombieBoss_GRITTIER extends ZombieBoss;
#exec OBJ LOAD FILE=ScrnZedPack_T.utx

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    local coords C;
    local vector HeadLoc;
    local int look;
    local bool bUseAltHeadShotLocation;
    local bool bWasAnimating;

    if (HeadBone == '')
        return false;

    if (Level.NetMode == NM_DedicatedServer) {
        // If we are a dedicated server estimate what animation is most likely playing on the client
        if (Physics == PHYS_Falling) {
            log("Falling");
            PlayAnim(AirAnims[0], 1.0, 0.0);
        }
        else if (Physics == PHYS_Walking) {
            bWasAnimating = IsAnimating(0) || IsAnimating(1);
            if( !bWasAnimating ) {
                if (bIsCrouched) {
                    PlayAnim(IdleCrouchAnim, 1.0, 0.0);
                }
                else {
                    bUseAltHeadShotLocation=true;
                }
            }

            if ( bDoTorsoTwist ) {
                SmoothViewYaw = Rotation.Yaw;
                SmoothViewPitch = ViewPitch;

                look = (256 * ViewPitch) & 65535;
                if (look > 32768)
                    look -= 65536;

                SetTwistLook(0, look);
            }
        }
        else if (Physics == PHYS_Swimming) {
            PlayAnim(SwimAnims[0], 1.0, 0.0);
        }

        if( !bWasAnimating && !bUseAltHeadShotLocation ) {
            SetAnimFrame(0.5);
        }
    }

    if( bUseAltHeadShotLocation ) {
        HeadLoc = Location + (OnlineHeadshotOffset >> Rotation);
        AdditionalScale *= OnlineHeadshotScale;
    }
    else {
        C = GetBoneCoords(HeadBone);
        HeadLoc = C.Origin + (HeadHeight * HeadScale * AdditionalScale * C.XAxis);
    }

    return class'ScrnZedFunc'.static.TestHitboxSphere(HitLoc, Ray, HeadLoc,
            HeadRadius * HeadScale * AdditionalScale);
}

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
