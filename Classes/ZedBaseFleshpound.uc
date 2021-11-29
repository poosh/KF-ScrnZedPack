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

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    local int OldHealth;
    local bool bIsHeadShot;
    local float HeadShotCheckScale;
    local class<KFWeaponDamageType> KFDamType;

    if (damageType == class 'DamTypeVomit')
        return;  // full resistance to Bloat vomit

    KFDamType = class<KFWeaponDamageType>(damageType);
    OldHealth = Health;
    if( Level.TimeSeconds > LastDamagedTime )
        TwoSecondDamageTotal = 0;
    LastDamagedTime = Level.TimeSeconds + 2;

    if ( KFDamType != none ) {
        HeadShotCheckScale = 1.0;
        // Do larger headshot checks if it is a melee attach
        if( class<DamTypeMelee>(damageType) != none )
            HeadShotCheckScale *= 1.25;
        bIsHeadShot = IsHeadShot(Hitlocation, normal(Momentum), HeadShotCheckScale);

        if ( !KFDamType.default.bIsExplosive ) {
            if( bIsHeadShot && KFDamType.default.HeadShotDamageMult >= 1.5 ) {
                // Don't reduce the damage so much if its a high headshot damage weapon
                Damage *= 0.75;
            }
            else if ( bIsHeadshot && Level.Game.GameDifficulty >= 5.0
                    && ClassIsChildOf(KFDamType, class'DamTypeCrossbow') )
            {
                // 65% damage reduction from xbow. M99 damage reduction apield in ScrnM99Bullet.AdjustZedDamage()
                Damage *= 0.35;
            }
            else {
                Damage *= 0.5;
            }
        }
        else if ( !ClassIsChildOf(KFDamType, class'DamTypeLAW') ) {
            if ( ClassIsChildOf(KFDamType, class'DamTypeFrag') || ClassIsChildOf(KFDamType, class'DamTypePipeBomb') ) {
                Damage *= 2.0;
            }
            else {
                Damage *= 1.25;
            }
        }
    }

    // fixes none-reference erros when taking enviromental damage -- PooSH
    if (InstigatedBy == none || KFDamType == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType); // skip NONE-reference error
    else
        super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);

    Damage = OldHealth - Health;
    TwoSecondDamageTotal += Damage;

    if ( Health <= 0 ) {
        DeviceGoNormal();
    }
    else if ( !bDecapitated && TwoSecondDamageTotal > RageDamageThreshold && !bChargingPlayer
            && !bZapped && (!(bCrispified && bBurnified) || bFrustrated) )
    {
        StartCharging();
    }
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
    ControllerClass=class'ScrnZedPack.ZedControllerFleshpound'
    AvoidAreaClass=class'ZedAvoidArea'
}
