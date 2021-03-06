class ZombieStalker_GRITTIER extends ZombieStalker;
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

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);
    if( Level.NetMode==NM_DedicatedServer )
        Return; // Servers aren't intrested in this info.

    if( Level.TimeSeconds > NextCheckTime && Health > 0 )
    {
        NextCheckTime = Level.TimeSeconds + 0.5;

        if( LocalKFHumanPawn != none && LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers() &&
            VSizeSquared(Location - LocalKFHumanPawn.Location) < LocalKFHumanPawn.GetStalkerViewDistanceMulti() * 640000.0 ) // 640000 = 800 Units
        {
            bSpotted = True;
        }
        else
        {
            bSpotted = false;
        }

        if ( !bSpotted && !bCloaked && Skins[0] != Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb' )
        {
            UncloakStalker();
        }
        else if ( Level.TimeSeconds - LastUncloakTime > 1.2 )
        {
            // if we're uberbrite, turn down the light
            if( bSpotted && Skins[0] != Finalblend'KFX.StalkerGlow' )
            {
                bUnlit = false;
                CloakStalker();
            }
            else if ( Skins[0] != Shader'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible' )
            {
                CloakStalker();
            }
        }
    }
}


simulated function CloakStalker()
{
    if ( bSpotted )
    {
        if( Level.NetMode == NM_DedicatedServer )
            return;

        Skins[0] = Finalblend'KFX.StalkerGlow';
        Skins[1] = Finalblend'KFX.StalkerGlow';
        Skins[2] = Finalblend'KFX.StalkerGlow';
        bUnlit = true;
        return;
    }

    if ( !bDecapitated && !bCrispified ) // No head, no cloak, honey.  updated :  Being charred means no cloak either :D
    {
        Visibility = 1;
        bCloaked = true;

        if( Level.NetMode == NM_DedicatedServer )
            Return;

        Skins[0] = Shader'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible';
        Skins[1] = Shader'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible';

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
    if( !bCrispified )
    {
        LastUncloakTime = Level.TimeSeconds;

        Visibility = default.Visibility;
        bCloaked = false;

        // 25% chance of our Enemy saying something about us being invisible
        if( Level.NetMode!=NM_Client && !KFGameType(Level.Game).bDidStalkerInvisibleMessage && FRand()<0.25 && Controller.Enemy!=none &&
         PlayerController(Controller.Enemy.Controller)!=none )
        {
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 17, "");
            KFGameType(Level.Game).bDidStalkerInvisibleMessage = true;
        }
        if( Level.NetMode == NM_DedicatedServer )
            Return;

        if ( Skins[0] != Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb' )
        {
            Skins[1] = FinalBlend'ScrnZedPack_T.stalker_grittier.stalker_grittier_fb';
            Skins[0] = Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb';

            if (PlayerShadow != none)
                PlayerShadow.bShadowActive = true;

            bAcceptsProjectors = true;

            SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
        }
    }
}

function RemoveHead()
{
    Super.RemoveHead();

    if (!bCrispified)
    {
        Skins[1] = FinalBlend'ScrnZedPack_T.stalker_grittier.stalker_grittier_fb';
        Skins[0] = Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb';
    }
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
    Super.PlayDying(DamageType,HitLoc);

    if(bUnlit)
        bUnlit=!bUnlit;

    LocalKFHumanPawn = none;

    if (!bCrispified)
    {
        Skins[1] = FinalBlend'ScrnZedPack_T.stalker_grittier.stalker_grittier_fb';
        Skins[0] = Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb';
    }
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{//should be derived and used.
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.stalker_grittier.stalker_grittier_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.stalker_grittier.stalker_grittier_diff');
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.stalker_grittier.stalker_grittier_spec');
    myLevel.AddPrecacheMaterial(Material'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_T.StalkerCloakOpacity_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_T.StalkerCloakEnv_rot');
    myLevel.AddPrecacheMaterial(Material'ScrnZedPack_T.stalker_grittier.stalker_grittier_opacity_osc');
}



defaultproperties
{
    DetachedArmClass=class'SeveredArmStalker'
    DetachedLegClass=class'SeveredLegStalker'
    DetachedHeadClass=class'SeveredHeadStalker'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Stalker_Freak'
    Skins(0) = Shader'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible'//Combiner'KF_Specimens_Trip_T.stalker_cmb'//Shader 'KFCharacters.StalkerHairShader'
    Skins(1) = Shader'ScrnZedPack_T.stalker_grittier.stalker_grittier_invisible'//Shader'KFCharacters.CloakShader';

    AmbientSound=Sound'KF_BaseStalker.Stalker_IdleLoop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Stalker_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Stalker_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Stalker_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Stalker_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Stalker_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Stalker_Challenge'
    MenuName="Grittier Stalker"
}
