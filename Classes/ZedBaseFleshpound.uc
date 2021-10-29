class ZedBaseFleshpound extends ZombieFleshpound
abstract;

var class<ZedAvoidArea> AvoidAreaClass;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( ROLE==ROLE_Authority ) {
        AvoidArea = Spawn(AvoidAreaClass,self);
        if ( AvoidArea != none )
            AvoidArea.InitFor(Self);
    }
    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function PostNetBeginPlay()
{
    // we dont need AvoidArea on the client
    EnableChannelNotify ( 1,1);
    AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
    super.PostNetBeginPlay();
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

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    if( AvoidArea != none ) {
        AvoidArea.Destroy();
        AvoidArea = none;
    }
    Super(KFMonster).Died(Killer,damageType,HitLocation);
}

function bool SameSpeciesAs(Pawn P)
{
    return P.IsA('ZombieFleshPound') || P.IsA('FemaleFP');
}

defaultproperties
{
    AvoidAreaClass=class'ZedAvoidArea'
}
