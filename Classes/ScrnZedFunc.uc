class ScrnZedFunc extends Object
    config(ScrnZedPack)
    abstract;

var config bool bHeadshotSrvAnim;
var config bool bHeadshotSrvDebugAnim;
var config bool bHeadshotSrvTorsoTwist;


/**
 * Tests if the tracing Ray that hit the target at HitLoc hits also the given target's sphere-shaped hitbox.
 * @param HitLoc location where the tracing ray hit the target's collision cylinder
 * @param Ray normalized direction of the trace line
 * @param SphereLoc the center of the sphere (e.g., Head bone's location for headshot detection)
 * @param SphereRadius the radius of the sphere
 * @pre The function assumes that the sphere is inside the target's collision cylinder
 * @return true if the ray hits the sphere
 */
static function bool TestHitboxSphere(vector HitLoc, vector Ray, vector SphereLoc, float SphereRadius)
{
    local vector HitToSphere;  // vector from HitLoc to SphereLoc
    local vector P;

    SphereRadius *= SphereRadius; // square it to avoid doing sqrt()

    HitToSphere = SphereLoc - HitLoc;
    if ( VSizeSquared(HitToSphere) < SphereRadius ) {
        // HitLoc is already inside the sphere - no projection needed
        return true;
    }

    // Let's project SphereLoc to Ray to get the projection point P.
    //               SphereLoc
    //              /|
    //            /  |
    //          /    |
    // HitLoc /_ _ _ |  _ _ _ _ _ _ > Ray
    //              P^
    //
    // If VSize(P - SphereLoc) < SphereRadius, the Ray hits the sphere.
    // VSize(P - SphereLoc) = sin(A) * vsize(SpereLoc - HitLoc)
    // A = acos(normal(SphereLoc - HitLoc) dot Ray)
    // The above solution is simle to understand. However, it is CPU-heavy since it uses 2 trigonometric function calls.
    // The below algorithm does the same but avoids trigonometry

    // HitToSphere dot Ray = cos(A) * VSize(HitToSphere) = VSize(P - HitLoc)
    P = HitLoc + Ray * (HitToSphere dot Ray);

    return VSizeSquared(P - SphereLoc) < SphereRadius;
}

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

    return TestHitboxSphere(HitLoc, Ray, HeadLoc, M.HeadRadius * M.HeadScale * AdditionalScale);
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
