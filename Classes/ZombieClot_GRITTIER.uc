class ZombieClot_GRITTIER extends ZombieClot;
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
    DetachedArmClass="SeveredArmClot"
    DetachedLegClass="SeveredLegClot"
    DetachedHeadClass="SeveredHeadClot"

    Mesh=SkeletalMesh'KF_Freaks_Trip.CLOT_Freak'

    Skins(0)=Combiner'ScrnZedPack_T.clot_grittier.clot_grittier_cmb'

    AmbientSound=Sound'KF_BaseClot.Clot_Idle1Loop'//Sound'KFPlayerSound.Zombiesbreath'//
    MoanVoice=Sound'KF_EnemiesFinalSnd.Clot_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Clot_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Clot_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Clot_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Clot_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Clot_Challenge'
    MenuName="Grittier Clot"
}
