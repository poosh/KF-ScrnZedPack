class ZedBaseBoss extends ZombieBoss
abstract;

var bool bEndGameBoss;  // is this the end-game boss or just spawned mid-game

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    SyringeCount = 3; // no healing for mid-game bosses
    Health *= 0.75; // less hp for mid-game bosses
    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);
    super.Destroyed();
}

function bool MakeGrandEntry()
{
    bEndGameBoss = true;
    SyringeCount = 0; // restore healing for end-game boss
    Health = HealthMax; // restore original hp
    return Super.MakeGrandEntry();
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    Super(KFMonster).Died(Killer,damageType,HitLocation);
    if ( bEndGameBoss )
        KFGameType(Level.Game).DoBossDeath();
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


defaultproperties
{
}
