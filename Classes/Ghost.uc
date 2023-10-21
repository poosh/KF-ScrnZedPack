// Completely invisible Stalker
// (c) PooSH, 2014
// used 'ClawAndMove' code from Scary Ghost's SuperStaler

class Ghost extends ZedBaseStalker;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

// max distance squared for player to see cloacked Ghosts.
// Beyond that distance Ghosts will appear completely invisible.
var float InvisibleDistanceSqr;
// Glow distance squared for Commandos
var float GlowDistanceSqr;

var() Material SemiCloackSkin;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    bServerSideSpotDetection = false;
}

function RenderOverlays(Canvas Canvas)
{
    Canvas.SetDrawColor(0, 92, 255, 255);
    super.RenderOverlays(Canvas);
}

simulated function Tick(float DeltaTime)
{
    local float DistanceSqr;

    Super(KFMonster).Tick(DeltaTime);

    // Keep the stalker moving toward its target when attacking
    if( Role == ROLE_Authority && bShotAnim && !bWaitForAnim && !bZapped ) {
        if( LookTarget!=None ) {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }
    }

    if( Level.NetMode==NM_DedicatedServer || bCrispified )
        Return; // Servers aren't intrested in this info.

    if( bZapped ) {
        // Make sure we check if we need to be cloaked as soon as the zap wears off
        NextCheckTime = Level.TimeSeconds;
    }
    else if( Level.TimeSeconds > NextCheckTime && Health > 0 ) {
        NextCheckTime = Level.TimeSeconds + 0.5;
        bSpotted = false;
        if ( LocalKFHumanPawn != none ) {
            DistanceSqr = VSizeSquared(Location - LocalKFHumanPawn.Location);
            if( LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers()
                    && DistanceSqr < GlowDistanceSqr )
            {
                bSpotted = true;
                if ( Skins[0] != GlowSkin ) {
                    CloakStalker();
                }
            }
            else if (DistanceSqr < InvisibleDistanceSqr) {
                if (bCloaked && Skins[0] != SemiCloackSkin) {
                    Skins[0] = SemiCloackSkin;
                    Skins[1] = SemiCloackSkin;
                    bUnlit = false;
                }
            }
            else if ( Skins[0] != CloackSkin ) {
                CloakStalker();
            }
        }
    }
}

function RangedAttack(Actor A)
{
    if ( !bShotAnim && Physics != PHYS_Swimming && CanAttack(A) ) {
        bShotAnim = true;
        SetAnimAction('ClawAndMove');
    }
}

// copied from ZombieSuperStalker (c) Scary Ghost
simulated event SetAnimAction(name NewAction)
{
    if( NewAction=='' )
        Return;

    ExpectingChannel = AttackAndMoveDoAnimAction(NewAction);

    bWaitForAnim = false;

    if( Level.NetMode!=NM_Client ) {
        AnimAction = NewAction;
        bResetAnimAct = True;
        ResetAnimActTime = Level.TimeSeconds+0.3;
    }
}

// copied from ZombieSuperStalker (c) Scary Ghost
simulated function int AttackAndMoveDoAnimAction( name AnimName )
{
    local int meleeAnimIndex;
    local float duration;

    if( AnimName == 'ClawAndMove' ) {
        meleeAnimIndex = Rand(3);
        AnimName = meleeAnims[meleeAnimIndex];
        CurrentDamtype = ZombieDamType[meleeAnimIndex];

        duration= GetAnimDuration(AnimName, 1.0);
    }

    if( AnimName=='StalkerSpinAttack' || AnimName=='StalkerAttack1' || AnimName=='JumpAttack') {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);

        return 1;
    }

    return super.DoAnimAction( AnimName );
}

defaultproperties
{
    MoanVoice=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmStalker'
    DetachedLegClass=Class'KFChar.SeveredLegStalker'
    DetachedHeadClass=Class'KFChar.SeveredHeadStalker'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd.Stalker.Stalker_Challenge'
    MenuName="Ghost"
    AmbientSound=Sound'KF_BaseStalker.Stalker_IdleLoop'
    Mesh=SkeletalMesh'KF_Freaks_Trip.Stalker_Freak'
    Skins[0]=FinalBlend'ScrnZedPack_T.Ghost.GhostGlow'
    Skins[1]=FinalBlend'ScrnZedPack_T.Ghost.GhostGlow'
    CloackSkin=Shader'KF_Specimens_Trip_T.patriarch_invisible'
    SemiCloackSkin=Shader'KF_Specimens_Trip_T.stalker_invisible'
    GlowSkin=FinalBlend'ScrnZedPack_T.Ghost.GhostGlow'
    InvisibleDistanceSqr=90000
    GlowDistanceSqr=640000
}
