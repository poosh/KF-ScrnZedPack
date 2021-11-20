class ScrnZedFunc extends Object
    config(ScrnZedPack)
    abstract;

var config bool bHeadshotSrvAnim;
var config bool bHeadshotSrvDebugAnim;
var config bool bHeadshotSrvTorsoTwist;


static function bool IsHeadShot(KFMonster M, vector HitLoc, vector ray, float AdditionalScale, vector HeadOffset)
{
    local coords C;
    local vector HeadLoc;
    local int look;
    local bool bUseAltHeadShotLocation;
    local bool bWasAnimating;

    if ( M.HeadBone == '' )
        return false;

    if ( M.Level.NetMode == NM_DedicatedServer && !M.bShotAnim ) {
        // If we are a dedicated server estimate what animation is most likely playing on the client
        switch ( M.Physics ) {
            case PHYS_Walking:
                bWasAnimating = default.bHeadshotSrvAnim && (M.IsAnimating(0) || M.IsAnimating(1));
                if( !bWasAnimating ) {
                    if ( M.bIsCrouched ) {
                        M.PlayAnim(M.IdleCrouchAnim, 1.0, 0.0);
                    }
                    else {
                        bUseAltHeadShotLocation=true;
                    }
                }
                else if ( default.bHeadshotSrvDebugAnim ) {
                    DebugAnim(M);
                }

                if ( default.bHeadshotSrvTorsoTwist && M.bDoTorsoTwist && !bUseAltHeadShotLocation ) {
                    M.SmoothViewYaw = M.Rotation.Yaw;
                    M.SmoothViewPitch = M.ViewPitch;

                    look = (256 * M.ViewPitch) & 65535;
                    if (look > 32768)
                        look -= 65536;

                    M.SetTwistLook(0, look);
                }
                break;

            case PHYS_Falling:
            case PHYS_Flying:
                M.PlayAnim(M.AirAnims[0], 1.0, 0.0);
                break;
            case PHYS_Swimming:
                M.PlayAnim(M.SwimAnims[0], 1.0, 0.0);
                break;
        }

        if( !bWasAnimating && !bUseAltHeadShotLocation ) {
            M.SetAnimFrame(0.5);
        }
    }

    if( bUseAltHeadShotLocation ) {
        HeadLoc = M.Location + (M.OnlineHeadshotOffset >> M.Rotation);
        AdditionalScale *= M.OnlineHeadshotScale;
    }
    else {
        C = M.GetBoneCoords(M.HeadBone);
        // AdditionalScale should not be here - it makes head by 25% higher when hitting with melee weapons.
        HeadLoc = C.Origin + (M.HeadHeight * M.HeadScale * C.XAxis)
            + HeadOffset.X * C.XAxis + HeadOffset.Y * C.YAxis + HeadOffset.Z * C.ZAxis;
    }

    return class'ScrnF'.static.TestHitboxSphere(HitLoc, Ray, HeadLoc,
            M.HeadRadius * M.HeadScale * AdditionalScale);
}

static function DebugAnim(KFMonster M)
{
    local int i;
    local name seq;
    local float frame, rate;
    local vector HeadLoc, SrvLoc, Diff;
    local coords C;

    for ( i = 0; i < 2; ++i ) {
        if ( !M.IsAnimating(i) )
            continue;
        M.GetAnimParams(i, seq, frame, rate);
        log(M $ " channel="$i $ " anim="$seq $ " frame="$frame $ " rate="$rate);
    }

    C = M.GetBoneCoords(M.HeadBone);
    HeadLoc = C.Origin + (M.HeadHeight * M.HeadScale * C.XAxis);
    SrvLoc = M.Location + (M.OnlineHeadshotOffset >> M.Rotation);
    Diff = SrvLoc - HeadLoc;
    log(M $ " server/client head diff: "$ VSize(Diff)$"u ("$Diff$")");
}

static function ZedBeginPlay(KFMonster M)
{
    if ( M.Role < ROLE_Authority ) {
        // spawn extended zed collision on client side for projector tracing (e.g., laser sights)
        if ( M.bUseExtendedCollision && M.MyExtCollision == none )
        {
            M.MyExtCollision = M.Spawn(class'ExtendedZCollision', M);
            M.MyExtCollision.SetCollisionSize(M.ColRadius, M.ColHeight);

            M.MyExtCollision.bHardAttach = true;
            M.MyExtCollision.SetLocation(M.Location + (M.ColOffset >> M.Rotation));
            M.MyExtCollision.SetPhysics(PHYS_None);
            M.MyExtCollision.SetBase(M);
            M.SavedExtCollision = M.MyExtCollision.bCollideActors;
        }
    }
}

static function ZedDestroyed(KFMonster M)
{
}


defaultproperties
{
    bHeadshotSrvAnim=false
    bHeadshotSrvTorsoTwist=true
}
