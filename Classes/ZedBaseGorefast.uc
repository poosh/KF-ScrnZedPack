class ZedBaseGorefast extends ZombieGorefast
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

function bool FlipOver()
{
    return class'ScrnZedFunc'.static.FlipOver(self);
}

function bool CanAttack(Actor A)
{
    return class'ScrnZedFunc'.static.CanAttack(self, A);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
    return class'ScrnZedFunc'.static.MeleeDamageTarget(self, hitdamage, pushdir);
}


defaultproperties
{
    ControllerClass=class'ZedControllerGorefast'
}
