// Code originally was taken from Scary Ghost's Super Zombies mutator
class ZombieCrawler_GRITTIER extends ZombieCrawler;

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

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    PounceSpeed= Rand(221)+330;
    MeleeRange= Rand(41)+50;
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

defaultproperties
{
    DetachedArmClass=class'SeveredArmCrawler'
    DetachedLegClass=class'SeveredLegCrawler'
    DetachedHeadClass=class'SeveredHeadCrawler'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Crawler_Freak'

    Skins(0)=Combiner'ScrnZedPack_T.crawler_grittier.crawler_grittier_cmb'

    AmbientSound=Sound'KF_BaseCrawler.Crawler_Idle'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Crawler_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Crawler_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Crawler_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Crawler_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Crawler_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'

    MenuName="Crawler.se"
    GroundSpeed=190.000000
    WaterSpeed=175.000000
}
