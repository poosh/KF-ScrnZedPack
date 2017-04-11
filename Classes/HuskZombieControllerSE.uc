// Code originally was taken from Scary Ghost's Super Zombies mutator
class HuskZombieControllerSE extends HuskZombieController;

var float aimAtFeetZDelta;

function bool DefendMelee(float Dist)
{
    return (Dist < 1000);
}

function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
    local rotator FireRotation, TargetLook;
    local float FireDist, TargetDist, ProjSpeed;
    local actor HitActor;
    local vector FireSpot, FireDir, TargetVel, HitLocation, HitNormal;
    local int realYaw;
    local bool bDefendCloseRange, bClean, bLeadTargetNow;
    local bool bWantsToAimAtFeet;

    if ( FiredAmmunition.ProjectileClass != None )
        projspeed = FiredAmmunition.ProjectileClass.default.speed;

    // make sure bot has a valid target
    if ( Target == None ) {
        Target = Enemy;
        if ( Target == None )
            return Rotation;
    }
    FireSpot = Target.Location;

    TargetDist = VSize(Target.Location - Pawn.Location);

    // perfect aim at stationary objects
    if ( Pawn(Target) == None ) {
        if ( !FiredAmmunition.bTossed )
            return rotator(Target.Location - projstart);
        else {
            FireDir = AdjustToss(projspeed,ProjStart,Target.Location,true);
            SetRotation(Rotator(FireDir));
            return Rotation;
        }
    }

    bLeadTargetNow = FiredAmmunition.bLeadTarget && bLeadTarget;
    bDefendCloseRange = ( (Target == Enemy) && DefendMelee(TargetDist) );
    aimerror = AdjustAimError(aimerror,TargetDist,bDefendCloseRange,FiredAmmunition.bInstantHit, bLeadTargetNow);

    // lead target with non instant hit projectiles
    if ( bLeadTargetNow ) {
        TargetVel = Target.Velocity;
        // hack guess at projecting falling velocity of target
        if ( Target.Physics == PHYS_Falling) {
            if ( Target.PhysicsVolume.Gravity.Z <= Target.PhysicsVolume.Default.Gravity.Z ) {
                TargetVel.Z = FMin(TargetVel.Z + FMax(-400, Target.PhysicsVolume.Gravity.Z * FMin(1,TargetDist/projSpeed)),0);
            } else {
                TargetVel.Z = FMin(0, TargetVel.Z);
            }
        }
        // more or less lead target (with some random variation)
        FireSpot += FMin(1, 0.7 + 0.6 * FRand()) * TargetVel * TargetDist/projSpeed;
        FireSpot.Z = FMin(Target.Location.Z, FireSpot.Z);
        /**
         *  If the target is within 1000uu, offset the Z coordinate of the
         *  FireSpot vector with aimAtFeetZDelta.  Otherwise, the husk will
         *  aim at behind the target, not at his feet.
         */
        if (aimAtFeetZDelta != 0.0 && Target.Physics == PHYS_Falling && bDefendCloseRange) {
            FireSpot.Z= Pawn.Location.Z + aimAtFeetZDelta;
        }

        if ( (Target.Physics != PHYS_Falling) && (FRand() < 0.55) && (VSize(FireSpot - ProjStart) > 1000) ) {
            // don't always lead far away targets, especially if they are moving sideways with respect to the bot
            TargetLook = Target.Rotation;
            if ( Target.Physics == PHYS_Walking )
                TargetLook.Pitch = 0;
            bClean = ( ((Vector(TargetLook) Dot Normal(Target.Velocity)) >= 0.71) && FastTrace(FireSpot, ProjStart) );
        }
        else // make sure that bot isn't leading into a wall
            bClean = FastTrace(FireSpot, ProjStart);
        if ( !bClean) {
            // reduce amount of leading
            if ( FRand() < 0.3 )
                FireSpot = Target.Location;
            else
                FireSpot = 0.5 * (FireSpot + Target.Location);
        }
    }

    bClean = false; //so will fail first check unless shooting at feet
    // Randomly determine if we should try and splash damage with the fire projectile

    if( FiredAmmunition.bTrySplash ) {
        if( Skill < 2.0 ) {
            if(FRand() > 0.85) {
                bWantsToAimAtFeet = true;
            }
        }
        else if( Skill < 3.0 ) {
            if(FRand() > 0.5) {
                bWantsToAimAtFeet = true;
            }
        }
        else if( Skill >= 3.0 ) {
            if(FRand() > 0.25) {
                bWantsToAimAtFeet = true;
            }
        }
    }

    if ( FiredAmmunition.bTrySplash && (Pawn(Target) != None) && (((Target.Physics == PHYS_Falling)
        && (Pawn.Location.Z + 80 >= Target.Location.Z)) || ((Pawn.Location.Z + 19 >= Target.Location.Z)
        && (bDefendCloseRange || bWantsToAimAtFeet))) ) {
        HitActor = Trace(HitLocation, HitNormal, FireSpot - vect(0,0,1) * (Target.CollisionHeight + 10), FireSpot, false);

        bClean = (HitActor == None);
        //So if we're too close, and not jumping, bClean is false
        //same distance but jumping, bClean is true
        if ( !bClean ) {
            FireSpot = HitLocation + vect(0,0,3);
            bClean = FastTrace(FireSpot, ProjStart);
        }
        else
            bClean = ( (Target.Physics == PHYS_Falling) && FastTrace(FireSpot, ProjStart) );
        /**
         *  Update the aimAtFeetZDelta variable with the appropriate offset
         *  once the Husk decides to aim at the target's feet.  Update the
         *  default property so all Super Husks can access it
         */
        if (bClean && TargetDist > 625.0) {
            aimAtFeetZDelta= FireSpot.Z - Pawn.Location.Z;
        }
    }

    if ( !bClean ) {
        //try middle
        FireSpot.Z = Target.Location.Z;
        bClean = FastTrace(FireSpot, ProjStart);
    }
    if ( FiredAmmunition.bTossed && !bClean && bEnemyInfoValid ) {
        FireSpot = LastSeenPos;
        HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
        if ( HitActor != None ) {
            bCanFire = false;
            FireSpot += 2 * Target.CollisionHeight * HitNormal;
        }
        bClean = true;
    }

    if( !bClean ) {
        // try head
        FireSpot.Z = Target.Location.Z + 0.9 * Target.CollisionHeight;
        bClean = FastTrace(FireSpot, ProjStart);
    }
    if ( !bClean && (Target == Enemy) && bEnemyInfoValid ) {
        FireSpot = LastSeenPos;
        if ( Pawn.Location.Z >= LastSeenPos.Z )
            FireSpot.Z -= 0.4 * Enemy.CollisionHeight;
        HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
        if ( HitActor != None ) {
            FireSpot = LastSeenPos + 2 * Enemy.CollisionHeight * HitNormal;
            if ( Monster(Pawn).SplashDamage() && (Skill >= 4) ) {
                HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
                if ( HitActor != None )
                    FireSpot += 2 * Enemy.CollisionHeight * HitNormal;
            }
            bCanFire = false;
        }
    }

    // adjust for toss distance
    if ( FiredAmmunition.bTossed ) {
        FireDir = AdjustToss(projspeed,ProjStart,FireSpot,true);
    }
    else {
        FireDir = FireSpot - ProjStart;
    }

    FireRotation = Rotator(FireDir);
    realYaw = FireRotation.Yaw;
    InstantWarnTarget(Target,FiredAmmunition,vector(FireRotation));

    FireRotation.Yaw = SetFireYaw(FireRotation.Yaw + aimerror);
    FireDir = vector(FireRotation);
    // avoid shooting into wall
    FireDist = FMin(VSize(FireSpot-ProjStart), 400);
    FireSpot = ProjStart + FireDist * FireDir;
    HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
    if ( HitActor != None ) {
        if ( HitNormal.Z < 0.7 ) {
            FireRotation.Yaw = SetFireYaw(realYaw - aimerror);
            FireDir = vector(FireRotation);
            FireSpot = ProjStart + FireDist * FireDir;
            HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
        }
        if ( HitActor != None ) {
            FireSpot += HitNormal * 2 * Target.CollisionHeight;
            if ( Skill >= 4 ) {
                HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
                if ( HitActor != None )
                    FireSpot += Target.CollisionHeight * HitNormal;
            }
            FireDir = Normal(FireSpot - ProjStart);
            FireRotation = rotator(FireDir);
        }
    }

    //Make it so the Husk always shoots the ground it the target is close
    SetRotation(FireRotation);
    return FireRotation;
}

defaultproperties
{
}
