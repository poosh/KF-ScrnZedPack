class ZedBaseScrake extends ZombieScrake
abstract;

var int SawDamage;
var int OriginalMeleeDamage; // default melee damage, adjusted by game's difficulty

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    OriginalMeleeDamage = MeleeDamage;
    // fixed bug when saw damage didn't scale by diufficulty
    SawDamage = Max((DifficultyDamageModifer() * SawDamage),1);
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

simulated function ProcessHitFX()
{
    super.ProcessHitFX();

    // make sure the head is removed from decapitated zeds
    if (bDecapitated && !bHeadGibbed) {
        DecapFX(GetBoneCoords(HeadBone).Origin, rot(0,0,0), false, true);
    }
}

function bool CanAttack(Actor A)
{
    return class'ScrnZedFunc'.static.CanAttack(self, A);
}

function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
    return class'ScrnZedFunc'.static.MeleeDamageTarget(self, hitdamage, pushdir);
}

State SawingLoop
{
    function RangedAttack(Actor A)
    {
        super.RangedAttack(A);
        if ( bShotAnim ) {
            MeleeDamage = SawDamage;
        }
    }

    function EndState()
    {
        super.EndState();
        MeleeDamage = OriginalMeleeDamage;
    }
}


defaultproperties
{
    ControllerClass=class'ZedControllerScrake'
    SawDamage=10
}
