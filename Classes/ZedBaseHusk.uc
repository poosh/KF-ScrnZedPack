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

    MaxFireRangeSq = Square(MaxFireRange);
    MaxShotsRemaining = ShotsRemaining;
    ShotsRemaining = 1 + rand(MaxShotsRemaining);
    MaxMeleeAttacks = 1 + rand(MaxMeleeAttacks);

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

simulated function ToggleAuxCollision(bool newbCollision)
{
    if ( MyExtCollision != none )
        super.ToggleAuxCollision(newbCollision);
}

function SpawnTwoShots()
{
    if ( Controller != none )
        super.SpawnTwoShots();
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
    ControllerClass=class'ScrnZedPack.ZedControllerHusk'
    MaxMeleeAttacks=2
    ShotsRemaining=1
    MaxFireRange=10000  // 200m
    // Husk doesn't have burning animations
    BurningWalkFAnims(0)="WalkF"
    BurningWalkFAnims(1)="WalkF"
    BurningWalkFAnims(2)="WalkF"
    BurningWalkAnims(0)="WalkB"
    BurningWalkAnims(1)="WalkL"
    BurningWalkAnims(2)="WalkR"
}
