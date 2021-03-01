// Code originally was taken from Scary Ghost's Super Zombies mutator
class ZombieGorefast_GRITTIER extends ZombieGorefast;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

var float minRageDist;

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

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}
function RangedAttack(Actor A) {
    Super(KFMonster).RangedAttack(A);
    if( !bShotAnim && !bDecapitated && VSize(A.Location-Location)<=minRageDist )
        GoToState('RunningState');
}

state RunningState {
    // Don't override speed in this state
    function bool CanSpeedAdjust() {
        return super.CanSpeedAdjust();
    }

    function BeginState() {
        super.BeginState();
    }

    function EndState() {
        super.EndState();
    }

    function RemoveHead() {
        super.RemoveHead();
    }

    function RangedAttack(Actor A) {

        if ( bShotAnim || Physics == PHYS_Swimming)
            return;
        else if ( CanAttack(A) ) {
            bShotAnim = true;

            //Always do the charging melee attack
            SetAnimAction('ClawAndMove');
            RunAttackTimeout = GetAnimDuration('GoreAttack1', 1.0);
            return;
        }
    }

    simulated function Tick(float DeltaTime) {
        super.Tick(DeltaTime);
    }


Begin:
    GoTo('CheckCharge');
CheckCharge:
    if( Controller!=None && Controller.Target!=None && VSize(Controller.Target.Location-Location)<minRageDist ) {
        Sleep(0.5+ FRand() * 0.5);
        //log("Still charging");
        GoTo('CheckCharge');
    }
    else {
        //log("Done charging");
        GoToState('');
    }
}

defaultproperties
{
    DetachedArmClass=class'SeveredArmGorefast'
    DetachedLegClass=class'SeveredLegGorefast'
    DetachedHeadClass=class'SeveredHeadGorefast'

    Mesh=SkeletalMesh'KF_Freaks_Trip.GoreFast_Freak'

    Skins(0)=Combiner'ScrnZedPack_T.gorefast_grittier.gorefast_grittier_cmb'

    AmbientSound=Sound'KF_BaseGorefast.Gorefast_Idle'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Gorefast_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Gorefast_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Gorefast_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Gorefast_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Gorefast_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Gorefast_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Gorefast_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Gorefast_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Gorefast_Challenge'

    minRageDist=1400.000000
    MenuName="Gorefast.se"
}
