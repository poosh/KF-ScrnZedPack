class HuskFireProjectileSE extends KFChar.HuskFireProjectile;

simulated singular function Touch(Actor Other)
{
    local vector    HitLocation, HitNormal;

    //Don't touch bulletwhip attachment.  Taken from HuskFireProjectile
    if ( Other == None || KFBulletWhipAttachment(Other) != none )
        return;
    if ( Other.bProjTarget || Other.bBlockActors ) {
        LastTouched = Other;
        if ( Velocity == vect(0,0,0) || Other.IsA('Mover') ) {
            ProcessTouch(Other,Location);
            LastTouched = None;
            return;
        }

        if ( Other.TraceThisActor(HitLocation, HitNormal, Location, Location - 2*Velocity, GetCollisionExtent()) )
            HitLocation = Location;

        ProcessTouch(Other, HitLocation);
        LastTouched = None;
        if ( (Role < ROLE_Authority) && (Other.Role == ROLE_Authority) && (Pawn(Other) != None) )
            ClientSideTouch(Other, HitLocation);
    }
}

// Don't hit Zed extra collision cylinders
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    if ( ExtendedZCollision(Other) != none /* || Other.IsA('KFMonster') */ )
    {
        return;
    }

    // Don't let it hit this player, or blow up on another player
    if (Other == none || Other == Instigator || Other.Base == Instigator)
        return;
    // Don't collide with bullet whip attachments
    if (KFBulletWhipAttachment(Other) != none) {
        return;
    }

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if (Instigator != none) {
        OrigLoc = Instigator.Location;
    }
    if (!bDud && ((VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))) {
        if( Role == ROLE_Authority ) {
            AmbientSound=none;
            PlaySound(Sound'ProjectileSounds.PTRD_deflect04',,2.0);
            Other.TakeDamage( ImpactDamage, Instigator, HitLocation, Normal(Velocity), ImpactDamageType );
        }

        bDud = true;
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
    }

    if (!bDud) {
       Explode(HitLocation,Normal(HitLocation-Other.Location));
    }
}

defaultproperties
{
}
