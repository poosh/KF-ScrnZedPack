// Code originally was taken from Scary Ghost's Super Zombies mutator
class ZombieGorefast_GRITTIER extends ZombieGorefast;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

var float minRageDist;

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

