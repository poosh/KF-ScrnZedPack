class ScrnZedFunc extends Object
abstract;


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
