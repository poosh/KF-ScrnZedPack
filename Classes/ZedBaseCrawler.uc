class ZedBaseCrawler extends ZombieCrawler
abstract;

var transient float NextMeleeTime;

simulated function PostBeginPlay()
{
    CurrentDamType = ZombieDamType[0];
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

event Bump(actor Other)
{
    local KFHumanPawn P;

    if ( !bPouncing )
        return;

    P = KFHumanPawn(Other);
    if ( P != none && (Normal(Velocity) dot Normal(P.Location - Location)) > 0.7) {
        P.TakeDamage(MeleeDamage * (0.95 + 0.10*frand()), self, self.Location, self.velocity, ZombieDamType[0]);
        if ( P.Health <=0 ) {
            P.SpawnGibs(self.rotation, 1);
        }
        //After impact, there'll be no momentum for further bumps
        bPouncing=false;
    }
}

function RangedAttack(Actor A)
{
    if (bShotAnim || Physics == PHYS_Swimming || Level.TimeSeconds < NextMeleeTime || !CanAttack(A))
        return;

    bShotAnim = true;
    SetAnimAction('Claw');
    //PlaySound(sound'Claw2s', SLOT_None); KFTODO: Replace this
    Controller.bPreparingMove = true;
    Acceleration = vect(0,0,0);
    NextMeleeTime = Level.TimeSeconds + 1.0;
}


defaultproperties
{
    ControllerClass=class'ZedControllerCrawler'
    Mass=20
    // Crawler does not have "Jump" animation
    TakeoffAnims(0)="ZombieSpring"
    TakeoffAnims(1)="ZombieSpring"
    TakeoffAnims(2)="ZombieSpring"
    TakeoffAnims(3)="ZombieSpring"
    AirAnims(0)="ZombieLeapIdle"
    AirAnims(1)="ZombieLeapIdle"
    AirAnims(2)="ZombieLeapIdle"
    AirAnims(3)="ZombieLeapIdle"
    LandAnims(0)="Landed"
    LandAnims(1)="Landed"
    LandAnims(2)="Landed"
    LandAnims(3)="Landed"
    AirStillAnim="Jump2"
    TakeoffStillAnim="ZombieSpring"

    // these should not use but just in case
    DoubleJumpAnims(0)="ZombieSpring"
    DoubleJumpAnims(1)="ZombieSpring"
    DoubleJumpAnims(2)="ZombieSpring"
    DoubleJumpAnims(3)="ZombieSpring"
    DodgeAnims(0)="ZombieSpring"
    DodgeAnims(1)="ZombieSpring"
    DodgeAnims(2)="ZombieSpring"
    DodgeAnims(3)="ZombieSpring"
}
