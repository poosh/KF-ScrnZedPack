class ZedBaseBoss extends ZombieBoss
abstract;

var class<ZedAvoidArea> AvoidAreaClass;
var ZedAvoidArea AvoidArea;

var bool bEndGameBoss;  // is this the end-game boss or just spawned mid-game

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( ROLE==ROLE_Authority ) {
        SyringeCount = 3; // no healing for mid-game bosses
        Health *= 0.75; // less hp for mid-game bosses

        AvoidArea = Spawn(AvoidAreaClass,self);
        if ( AvoidArea != none )
            AvoidArea.InitFor(Self);
    }

    class'ScrnZedFunc'.static.ZedBeginPlay(self);
}

simulated function Destroyed()
{
    class'ScrnZedFunc'.static.ZedDestroyed(self);

    if( AvoidArea != none )
        AvoidArea.Destroy();

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
    if( AvoidArea != none ) {
        AvoidArea.Destroy();
        AvoidArea = none;
    }
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
    local float DamagerDistSq;
	local float UsedPipeBombDamScale;
	local KFHumanPawn P;
	local int NumPlayersSurrounding;
	local bool bDidRadialAttack;
    local Pawn OldEnemy;
    local KFMonsterController MC;

    MC = KFMonsterController(Controller);
    OldEnemy = Controller.Enemy;

    if ( Level.TimeSeconds > LastMeleeExploitCheckTime ) {
        LastMeleeExploitCheckTime = Level.TimeSeconds + 1.0;
        NumLumberJacks = 0;
        NumNinjas = 0;

        foreach CollidingActors(class'KFHumanPawn', P, 150, Location) {
            if ( P.Health <= 0 )
                continue;

            NumPlayersSurrounding++;

            if( KFMeleeGun(P.Weapon) != none ) {
                if( Axe(P.Weapon) != none || Chainsaw(P.Weapon) != none ) {
                    NumLumberJacks++;
                }
                else {
                    NumNinjas++;
                }
            }
        }
        if( NumPlayersSurrounding >= 3 ) {
            bDidRadialAttack = true;
            GotoState('RadialAttack');
        }
    }

    bOnlyDamagedByCrossbow = bOnlyDamagedByCrossbow && class<DamTypeCrossbow>(DamType) != none;

    // Scale damage from the pipebomb down a bit if lots of pipe bomb damage happens
    // at around the same times. Prevent players from putting all thier pipe bombs
    // in one place and owning the patriarch in one blow.
    if ( class<DamTypePipeBomb>(DamType) != none ) {
       UsedPipeBombDamScale = FMax(0,(1.0 - PipeBombDamageScale));
       PipeBombDamageScale += 0.075;
       if( PipeBombDamageScale > 1.0 )
           PipeBombDamageScale = 1.0;
       Damage *= UsedPipeBombDamScale;
    }

    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);

    if( Health <= 0 )
        return;

    if ( KFMonster(InstigatedBy) != none ) {
        // prevent zeds from attacking their daddy
        if ( InstigatedBy.Controller.Enemy == self && KFMonsterController(InstigatedBy.Controller) != none ) {
            KFMonsterController(InstigatedBy.Controller).ChangeEnemy(OldEnemy, InstigatedBy.Controller.CanSee(OldEnemy));
        }
        // and daddy from attacking his children
        if ( MC.Enemy == InstigatedBy ) {
            MC.ChangeEnemy(OldEnemy, MC.CanSee(OldEnemy));
        }
    }

    if( Level.TimeSeconds - LastDamageTime > 10 ) {
        ChargeDamage = 0;
    }
    else {
        LastDamageTime = Level.TimeSeconds;
        ChargeDamage += Damage;
    }

    if( InstigatedBy != none && InstigatedBy.IsPlayerPawn() && ShouldChargeFromDamage() && ChargeDamage > 200 ) {
        // If someone close up is shooting us, just charge them
        DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
        if( DamagerDistSq < 490000 ) {
            SetAnimAction('transition');
            ChargeDamage=0;
            LastForceChargeTime = Level.TimeSeconds;
            GoToState('Charging');
            return;
        }
    }

    if( !bDidRadialAttack && NeedHealing() && ShouldKnockDownFromDamage() ) {
        bShotAnim = true;
        Acceleration = vect(0,0,0);
        SetAnimAction('KnockDown');
        HandleWaitForAnim('KnockDown');
        MC.bUseFreezeHack = True;
        GoToState('KnockDown');
    }
}

function bool NeedHealing()
{
    return SyringeCount < 3 && Health < HealingLevels[SyringeCount];
}

function bool ShouldKnockDownFromDamage()
{
    return true;
}

state RadialAttack
{
    function bool ShouldKnockDownFromDamage()
    {
        return false;
    }
}

state KnockDown // Knocked
{
    function bool ShouldKnockDownFromDamage()
    {
        return false;
    }
}

State Escaping
{
    function bool ShouldKnockDownFromDamage()
    {
        return false;
    }
}


defaultproperties
{
    AvoidAreaClass=class'ZedAvoidArea'
}
