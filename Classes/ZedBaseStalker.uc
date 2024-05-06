class ZedBaseStalker extends ZombieStalker
abstract;

var() Material CloackSkin;
var() Material CloackOverlay;
var() Material GlowSkin;
var() Material ZapOverlay;

var bool bServerSideSpotDetection, bServerSpotted;

replication {
    reliable if (bNetInitial && Role == ROLE_Authority)
        bServerSideSpotDetection;

    reliable if ((bNetInitial || bNetDirty) && Role == ROLE_Authority)
        bServerSpotted;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    class'ScrnZedFunc'.static.ZedBeginPlay(self);

    if (Role == ROLE_Authority) {
        bServerSideSpotDetection = class'ScrnZedFunc'.default.bCommandoRevealsStalkers;
    }
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);
    super.Destroyed();
}

function bool IsHeadShot(vector HitLoc, vector ray, float AdditionalScale)
{
    return class'ScrnZedFunc'.static.IsHeadShot(self, HitLoc, ray, AdditionalScale, vect(0,0,0));
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

simulated function RestoreSkin() {
    local int i;

    if (Level.Netmode == NM_DedicatedServer || bCrispified || bZapped)
        return;

    for (i = 0; i < Skins.Length; ++i) {
        Skins[i] = default.Skins[i];
    }
}

function RemoveHead()
{
    super(KFMonster).RemoveHead();
    RestoreSkin();
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
    super(KFMonster).PlayDying(DamageType,HitLoc);

    bUnlit=false;
    LocalKFHumanPawn = none;
    RestoreSkin();
}

function bool CanAttack(Actor A)
{
    return class'ScrnZedFunc'.static.CanAttack(self, A);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
    return class'ScrnZedFunc'.static.MeleeDamageTarget(self, hitdamage, pushdir);
}

simulated function bool IsSpotted()
{
    local KFHumanPawn HP;

    if (bServerSideSpotDetection) {
        if (Role == ROLE_Authority) {
            bServerSpotted = false;
            foreach VisibleCollidingActors(Class'KFHumanPawn', HP, 800, Location) {
                if (HP.Health > 0 && HP.ShowStalkers()) {
                    bServerSpotted = true;
                    break;
                }
            }
        }
        return bServerSpotted;
    }
    else if (LocalKFHumanPawn != none && LocalKFHumanPawn.Health > 0 && LocalKFHumanPawn.ShowStalkers()
                && VSizeSquared(Location - LocalKFHumanPawn.Location) < LocalKFHumanPawn.GetStalkerViewDistanceMulti() * 640000.0)
    {
        return true;
    }
    return false;
}

simulated function Tick(float DeltaTime)
{
    super(KFMonster).Tick(DeltaTime);
    if( Level.NetMode==NM_DedicatedServer ) {
        if (bServerSideSpotDetection && bSpotted != IsSpotted()) {
            bSpotted = bServerSpotted;
            NetUpdateTime = Level.TimeSeconds - 1;
        }
        return;
    }

    if( bZapped ) {
        // Make sure we check if we need to be cloaked as soon as the zap wears off
        NextCheckTime = Level.TimeSeconds;
    }
    else if( Level.TimeSeconds > NextCheckTime && Health > 0 ) {
        NextCheckTime = Level.TimeSeconds + 0.5;
        bSpotted = IsSpotted();

        if (!bSpotted && (bDecapitated || !bCloaked)) {
            if (Skins[0] != default.Skins[0]) {
                UncloakStalker();
                if (bDecapitated) {
                    NextCheckTime += 100;  // never cloack again
                }
            }
        }
        else if (Level.TimeSeconds - LastUncloakTime > 1.2) {
            // if we're uberbrite, turn down the light
            if (bSpotted && Skins[0] != GlowSkin) {
                bUnlit = false;
                CloakStalker();
            }
            else if (Skins[0] != CloackSkin) {
                CloakStalker();
            }
        }
    }
}

simulated function CloakStalker()
{
    local int i;

    // No cloaking if zapped
    if (bZapped || bCrispified)
        return;

    if (bSpotted) {
        Visibility = 120;
        if( Level.NetMode == NM_DedicatedServer )
            return;

        for (i = 0; i < Skins.Length; ++i) {
            Skins[i] = GlowSkin;
        }
        bUnlit = true;
    }
    else if (!bDecapitated) {
        Visibility = 1;
        bCloaked = true;

        if( Level.NetMode == NM_DedicatedServer )
            Return;

        for (i = 0; i < Skins.Length; ++i) {
            Skins[i] = CloackSkin;
        }

        // Invisible - no shadow
        if(PlayerShadow != none)
            PlayerShadow.bShadowActive = false;
        if(RealTimeShadow != none)
            RealTimeShadow.Destroy();

        // Remove/disallow projectors on invisible people
        Projectors.Remove(0, Projectors.Length);
        bAcceptsProjectors = false;
        SetOverlayMaterial(CloackOverlay, 0.25, true);
    }
}

simulated function UnCloakStalker()
{
    if (bZapped || bCrispified)
        return;

    LastUncloakTime = Level.TimeSeconds;

    Visibility = default.Visibility;
    bCloaked = false;
    bUnlit = false;

    // 25% chance of our Enemy saying something about us being invisible
    if (Level.NetMode!=NM_Client && !KFGameType(Level.Game).bDidStalkerInvisibleMessage && FRand() < 0.25
            && Controller.Enemy!=none && PlayerController(Controller.Enemy.Controller) != none)
    {
        PlayerController(Controller.Enemy.Controller).Speech('AUTO', 17, "");
        KFGameType(Level.Game).bDidStalkerInvisibleMessage = true;
    }

    if (Level.NetMode == NM_DedicatedServer)
        return;

    if (Skins[0] != default.Skins[0]) {
        RestoreSkin();
        if (PlayerShadow != none)
            PlayerShadow.bShadowActive = true;
        bAcceptsProjectors = true;
        SetOverlayMaterial(CloackOverlay, 0.25, true);
    }
}

simulated function SetZappedBehavior()
{
    RestoreSkin();
    super(KFMonster).SetZappedBehavior();

    bUnlit = false;

    // Handle setting the zed to uncloaked so the zapped overlay works properly
    if( Level.Netmode == NM_DedicatedServer )
        return;

    if (PlayerShadow != none)
        PlayerShadow.bShadowActive = true;
    bAcceptsProjectors = true;
    SetOverlayMaterial(ZapOverlay, 999, true);
}

static function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(default.Skins[0]);
    myLevel.AddPrecacheMaterial(default.Skins[1]);
    myLevel.AddPrecacheMaterial(default.CloackSkin);
    myLevel.AddPrecacheMaterial(default.CloackOverlay);
    myLevel.AddPrecacheMaterial(default.GlowSkin);
    myLevel.AddPrecacheMaterial(default.ZapOverlay);
}


defaultproperties
{
    ControllerClass=class'ZedController'
    Skins[0]=Combiner'KF_Specimens_Trip_T.stalker_cmb'
    Skins[1]=FinalBlend'KF_Specimens_Trip_T.stalker_fb'
    CloackSkin=Shader'KF_Specimens_Trip_T.stalker_invisible'
    CloackOverlay=Material'KFX.FBDecloakShader'
    GlowSkin=Finalblend'KFX.StalkerGlow'
    ZapOverlay=Material'KFZED_FX_T.Energy.ZED_overlay_Hit_Shdr'
}
