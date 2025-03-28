class ZedBaseHusk extends ZombieHusk
    abstract;

var() int MaxMeleeAttacks;
var() float MaxFireRange;
var transient float MaxFireRangeSq;
var() int ShotsRemaining;  // how many fireballs Husk can shoot without cooldown
var transient int MaxShotsRemaining;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Controller != none) {
        // and why TWI removed this feature...
        MyAmmo = spawn(GetAmmunitionClass());

        MaxFireRangeSq = Square(MaxFireRange);
        MaxShotsRemaining = ShotsRemaining;
        ShotsRemaining = 1 + rand(MaxShotsRemaining);
        MaxMeleeAttacks = 1 + rand(MaxMeleeAttacks);
    }

    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);
    super.Destroyed();
}

function class<Ammunition> GetAmmunitionClass()
{
    if (class'ScrnZedFunc'.default.bLegacyHusk) {
        return AmmunitionClass;
    }
    return class'HuskAmmoG';
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

function bool FlipOver()
{
    return class'ScrnZedFunc'.static.FlipOver(self);
}

simulated function ProcessHitFX()
{
    super.ProcessHitFX();

    // make sure the head is removed from decapitated zeds
    if (bDecapitated && !bHeadGibbed && Health > 0) {
        DecapFX(GetBoneCoords(HeadBone).Origin, rot(0,0,0), false, true);
    }
}

simulated function ToggleAuxCollision(bool newbCollision)
{
    if ( MyExtCollision != none )
        super.ToggleAuxCollision(newbCollision);
}

// let's edit original code to avoid copy-cats in every seasonal zed class
function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;
    local KFMonsterController KFMonstControl;

    // do not shoot if we are brainless, falling, dying or being moved by other husk
    if (Controller == none || IsInState('ZombieDying') || IsInState('GettingOutOfTheWayOfShot') || Physics == PHYS_Falling)
        return;

    if (KFDoorMover(Controller.Target) != None)
    {
        Controller.Target.TakeDamage(22, Self, Location, vect(0, 0, 0), class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation, X, Y, Z);
    FireStart = GetBoneCoords('Barrel').Origin;

    // back to roots, use MyAmmo variable
    if (!SavedFireProperties.bInitialized)
    {
        SavedFireProperties.AmmoClass = MyAmmo.Class;
        SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
        SavedFireProperties.WarnTargetPct = MyAmmo.WarnTargetPct;
        SavedFireProperties.MaxRange = MyAmmo.MaxRange;
        SavedFireProperties.bTossed = MyAmmo.bTossed;
        SavedFireProperties.bTrySplash = MyAmmo.bTrySplash;
        SavedFireProperties.bLeadTarget = MyAmmo.bLeadTarget;
        SavedFireProperties.bInstantHit = MyAmmo.bInstantHit;
        SavedFireProperties.bInitialized = true;
    }

    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);

    FireRotation = Controller.AdjustAim(SavedFireProperties, FireStart, 600);

    foreach DynamicActors(class'KFMonsterController', KFMonstControl)
    {
        // ignore zeds that the husk actually can't see, Joabyy
        if (KFMonstControl == none || KFMonstControl == Controller || !LineOfSightTo(KFMonstControl))
            continue;

        if (PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75)
        {
            KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation),FireStart);
        }
    }

    // added projectile owner, maybe some one will use it
    Spawn(SavedFireProperties.ProjectileClass, self, ,FireStart, FireRotation);

    // Turn extra collision back on
    ToggleAuxCollision(true);
}


function RangedAttack(Actor A)
{
    local int LastFireTime;
    local float DistSq;

    if ( bShotAnim )
        return;

    DistSq = VSizeSquared(A.Location - Location);

    if ( Physics == PHYS_Swimming ) {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    else if ( (MaxMeleeAttacks > 0 || Level.Game.GameDifficulty < 5)
            && DistSq < Square(MeleeRange + CollisionRadius + A.CollisionRadius) )
    {
        MaxMeleeAttacks--;
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( !bDecapitated && DistSq < MaxFireRangeSq
            && (!Region.Zone.bDistanceFog || DistSq < Square(Region.Zone.DistanceFogEnd * 0.8)) )
    {
        bShotAnim = true;

        SetAnimAction('ShootBurns');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);

        MaxMeleeAttacks = 1 + rand(default.MaxMeleeAttacks);
        if ( --ShotsRemaining > 0 ) {
            NextFireProjectileTime= Level.TimeSeconds;
        }
        else {
            NextFireProjectileTime = Level.TimeSeconds + ProjectileFireInterval + (FRand() * 2.0);
            ShotsRemaining = 1 + rand(MaxShotsRemaining);
        }
    }
}

function RemoveHead()
{
    super.RemoveHead();
    MaxMeleeAttacks = 100;  // cannot shot if decapitated
}


defaultproperties
{
    ControllerClass=class'ZedControllerHusk'
    AmmunitionClass=class'HuskAmmo'
    MaxMeleeAttacks=2
    ShotsRemaining=1
    MaxFireRange=10000  // 200m
    ScoringValue=35  // up from 17
    ZappedDamageMod=1.5  // down from 2.0
    // Husk doesn't have burning animations
    BurningWalkFAnims(0)="WalkF"
    BurningWalkFAnims(1)="WalkF"
    BurningWalkFAnims(2)="WalkF"
    BurningWalkAnims(0)="WalkB"
    BurningWalkAnims(1)="WalkL"
    BurningWalkAnims(2)="WalkR"
}
