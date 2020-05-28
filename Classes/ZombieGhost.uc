// Completely invisible Stalker
// (c) PooSH, 2014
// used 'ClawAndMove' code from Scary Ghost's SuperStaler

class ZombieGhost extends ZombieStalker;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

// max distance squared for player to see cloacked Stalkers. 
// Beyond that distance Stalkers will appear completely invisible.
var float CloakDistanceSqr; 
// Unclock distance squared for Commandos
var float UncloakDistanceSqr;

var const Material CloakMat;
var const Material InvisibleMat;
var const Material UncloakMat, UncloakFBMat;
var const Material GlowFX;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(default.CloakMat);
    myLevel.AddPrecacheMaterial(default.InvisibleMat);
    myLevel.AddPrecacheMaterial(default.UncloakMat);
    myLevel.AddPrecacheMaterial(default.UncloakFBMat);
    myLevel.AddPrecacheMaterial(default.GlowFX);

    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_T.stalker_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_T.stalker_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_T.stalker_spec');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_T.StalkerCloakOpacity_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_T.StalkerCloakEnv_rot');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_T.stalker_opacity_osc');
    myLevel.AddPrecacheMaterial(Material'KFCharacters.StalkerSkin');
}




simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    
    if ( LocalKFHumanPawn != none ) {
        CloakDistanceSqr = fmax(CloakDistanceSqr, 3.0 * UncloakDistanceSqr * LocalKFHumanPawn.GetStalkerViewDistanceMulti());
        UncloakDistanceSqr *= LocalKFHumanPawn.GetStalkerViewDistanceMulti();
    }
}



function RenderOverlays(Canvas Canvas)
{
    Canvas.SetDrawColor(0, 92, 255, 255);
    super.RenderOverlays(Canvas);
}

// makes Stalker invisible or glowing (for commando)
simulated function CloakStalker()
{
    // No cloaking if zapped
    if( bZapped )
    {
        return;
    }

    if ( bSpotted ) {
        if( Level.NetMode == NM_DedicatedServer )
            return;

        Skins[0] = GlowFX;
        Skins[1] = GlowFX;
        bUnlit = true;
    }
    else if ( !bDecapitated && !bCrispified ) // No head, no cloak, honey.  updated :  Being charred means no cloak either :D
    {
        Visibility = 1;
        bCloaked = true;

        if( Level.NetMode == NM_DedicatedServer )
            Return;

        Skins[0] = InvisibleMat;
        Skins[1] = InvisibleMat;
        bUnlit = false;

        // Invisible - no shadow
        if(PlayerShadow != none)
            PlayerShadow.bShadowActive = false;
        if(RealTimeShadow != none)
            RealTimeShadow.Destroy();

        // Remove/disallow projectors on invisible people
        Projectors.Remove(0, Projectors.Length);
        bAcceptsProjectors = false;
        SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
    }
}

simulated function UnCloakStalker()
{
    if( bZapped )
    {
        return;
    }

    if( !bCrispified )
    {
        LastUncloakTime = Level.TimeSeconds;

        Visibility = default.Visibility;
        bCloaked = false;
        bUnlit = false;

        // 25% chance of our Enemy saying something about us being invisible
        if( Level.NetMode!=NM_Client && !KFGameType(Level.Game).bDidStalkerInvisibleMessage && FRand()<0.25 && Controller.Enemy!=none &&
         PlayerController(Controller.Enemy.Controller)!=none )
        {
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 17, "");
            KFGameType(Level.Game).bDidStalkerInvisibleMessage = true;
        }
        if( Level.NetMode == NM_DedicatedServer )
            Return;

        if ( Skins[0] != UncloakMat )
        {
            Skins[1] = FinalBlend'KF_Specimens_Trip_T.stalker_fb';
            Skins[0] = UncloakMat;

            if (PlayerShadow != none)
                PlayerShadow.bShadowActive = true;

            bAcceptsProjectors = true;

            SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
        }
    }
}

function RemoveHead()
{
    Super(KFMonster).RemoveHead();

    if (!bCrispified)
    {
        Skins[1] = UncloakFBMat;
        Skins[0] = UncloakMat;
    }
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
    Super(KFMonster).PlayDying(DamageType,HitLoc);

    if(bUnlit)
        bUnlit=!bUnlit;

    LocalKFHumanPawn = none;

    if (!bCrispified)
    {
        Skins[1] = UncloakFBMat;
        Skins[0] = UncloakMat;
    }
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
    
    if( Level.NetMode==NM_DedicatedServer )
        Return; // Servers aren't intrested in this info.

    if( bZapped ) {
        // Make sure we check if we need to be cloaked as soon as the zap wears off
        NextCheckTime = Level.TimeSeconds;
    }
    else if( Level.TimeSeconds > NextCheckTime && Health > 0 )
    {
        NextCheckTime = Level.TimeSeconds + 0.5;

        bSpotted = false;
        if ( LocalKFHumanPawn != none ) {
            DistanceSqr = VSizeSquared(Location - LocalKFHumanPawn.Location);
            if( LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers()
                    && DistanceSqr < UncloakDistanceSqr ) 
            {
                bSpotted = True;
                if ( Skins[0] != GlowFX ) {
                    Skins[0] = GlowFX;
                    Skins[1] = GlowFX;
                    bUnlit = true;                
                }
            }
            else if ( DistanceSqr < CloakDistanceSqr ) {
                if ( bCloaked && Skins[0] != CloakMat ) {
                    Skins[0] = CloakMat;
                    Skins[1] = CloakMat;
                    bUnlit = false;
                }
            }
            else if ( Skins[0] != InvisibleMat ) {
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

    bWaitForAnim= false;

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
     CloakDistanceSqr=62500.000000
     UncloakDistanceSqr=360000.000000
     CloakMat=Shader'KF_Specimens_Trip_T.stalker_invisible'
     InvisibleMat=Shader'KF_Specimens_Trip_T.patriarch_invisible'
     UncloakMat=Shader'KF_Specimens_Trip_T.stalker_invisible'
     UncloakFBMat=Shader'KF_Specimens_Trip_T.stalker_invisible'
     GlowFX=FinalBlend'ScrnZedPack_T.Ghost.GhostGlow'
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
     Skins(0)=Shader'KF_Specimens_Trip_T.patriarch_invisible'
     Skins(1)=Shader'KF_Specimens_Trip_T.patriarch_invisible'
}
