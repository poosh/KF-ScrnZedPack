class ZedBaseBloat extends ZombieBloat
abstract;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    class'ScrnZedFunc'.static.ZedBeginPlay(self);
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

function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;

    if ( bDecapitated || bDeleteMe || Health <= 0 || Controller == none )
        return; // no more head to puke from

    if( KFDoorMover(Controller.Target)!=None ) {
        Controller.Target.TakeDamage(22,Self,Location,vect(0,0,0),Class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation,X,Y,Z);
    FireStart = Location+(vect(30,0,64) >> Rotation)*DrawScale;
    if ( !SavedFireProperties.bInitialized ) {
        SavedFireProperties.AmmoClass = Class'SkaarjAmmo';
        SavedFireProperties.ProjectileClass = Class'KFBloatVomit';
        SavedFireProperties.WarnTargetPct = 1;
        SavedFireProperties.MaxRange = 500;
        SavedFireProperties.bTossed = False;
        SavedFireProperties.bTrySplash = False;
        SavedFireProperties.bLeadTarget = True;
        SavedFireProperties.bInstantHit = True;
        SavedFireProperties.bInitialized = True;
    }

    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);
    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);
    Spawn(Class'KFBloatVomit',,,FireStart,FireRotation);

    FireStart-=(0.5*CollisionRadius*Y);
    FireRotation.Yaw -= 1200;
    spawn(Class'KFBloatVomit',,,FireStart, FireRotation);

    FireStart+=(CollisionRadius*Y);
    FireRotation.Yaw += 2400;
    spawn(Class'KFBloatVomit',,,FireStart, FireRotation);
    // Turn extra collision back on
    ToggleAuxCollision(true);
}

simulated function ProcessHitFX()
{
    super.ProcessHitFX();

    // make sure the head is removed from decapitated zeds
    if (bDecapitated && !bHeadGibbed && Health > 0) {
        DecapFX(GetBoneCoords(HeadBone).Origin, rot(0,0,0), false, true);
    }
}


defaultproperties
{
    ControllerClass=class'ZedController'
    BurnEffect=Class'ScrnMonsterFlame'
    HeadHealth=50
    PlayerNumHeadHealthScale=0.2
    Mass=500
    ZappedDamageMod=2.0
}
