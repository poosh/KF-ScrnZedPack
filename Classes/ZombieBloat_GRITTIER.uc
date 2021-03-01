// Code originally was taken from Scary Ghost's Super Zombies mutator
class ZombieBloat_GRITTIER extends ZombieBloat;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

var bool bAmIBarfing;
var float NextExtraBileTime;

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

simulated function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);
    if( bAmIBarfing && !bDecapitated && Level.TimeSeconds > NextExtraBileTime ) {
        SpawnTwoShots();
        NextExtraBileTime = Level.TimeSeconds + default.NextExtraBileTime;
    }
}

function Touch(Actor Other)
{
    super.Touch(Other);
    if (Other.IsA('ShotgunBullet')) {
        ShotgunBullet(Other).Damage= 0;
    }
}

function RangedAttack(Actor A)
{
    local int LastFireTime;

    if ( bShotAnim )
        return;

    if ( Physics == PHYS_Swimming ) {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius ) {
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( (KFDoorMover(A) != none || VSize(A.Location-Location) <= 250) && !bDecapitated ) {
        bShotAnim = true;
        SetAnimAction('ZombieBarfMoving');
        RunAttackTimeout = GetAnimDuration('ZombieBarf', 1.0);
        bMovingPukeAttack=true;

        // Randomly send out a message about Bloat Vomit burning(3% chance)
        if ( FRand() < 0.03 && KFHumanPawn(A) != none && PlayerController(KFHumanPawn(A).Controller) != none ) {
            PlayerController(KFHumanPawn(A).Controller).Speech('AUTO', 7, "");
        }
    }
}

//ZombieBarf animation triggers this
function SpawnTwoShots() {
    super.SpawnTwoShots();
    bAmIBarfing= true;
}

simulated function AnimEnd(int Channel) {
    local name  Sequence;
    local float Frame, Rate;


    GetAnimParams( ExpectingChannel, Sequence, Frame, Rate );

    super.AnimEnd(Channel);

    if(Sequence == 'ZombieBarf')
        bAmIBarfing= false;
}

defaultproperties
{
    DetachedArmClass=class'SeveredArmBloat'
    DetachedLegClass=class'SeveredLegBloat'
    DetachedHeadClass=class'SeveredHeadBloat'

    BileExplosion=class'KFMod.BileExplosion'
    BileExplosionHeadless=class'KFMod.BileExplosionHeadless'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Bloat_Freak'

    Skins(0)=Combiner'ScrnZedPack_T.bloat_grittier.bloat_grittier_cmb'

    AmbientSound=Sound'KF_BaseBloat.Bloat_Idle1Loop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Bloat_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Bloat_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Bloat_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Bloat_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Bloat_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Bloat_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Bloat_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Bloat_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Bloat_Challenge'

    MenuName="Bloat.se"
    NextExtraBileTime=1.0
    HeadHealth=50
}
