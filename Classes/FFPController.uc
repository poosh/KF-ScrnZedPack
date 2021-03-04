//-----------------------------------------------------------
//Still behaves like a Fleshpound for the most part, although quicker to rage.
//Thanks to Scary for the work on this one. - Whisky
//-----------------------------------------------------------
class FFPController extends FleshpoundZombieController;

var float RageFrustrationThreshholdRand;

var transient bool bSmashDoor, bHitTarget;


//I fear nothing but you WILL fear me!!
//FFP will not bother trying to avoid nades when raged, prevents players from using their nades to stop her in a door.
//(I know because as a medic I was doing it all the time. - Whisky)
function FearThisSpot(AvoidMarker aSpot)
{
    local FemaleFP FFP;

    FFP = FemaleFP(Pawn);
    if (!FFP.bChargingPlayer)
    {
        if ( Skill > 1 + 2.0 * FRand() )
            super(Controller).FearThisSpot(aSpot);
    }
}

function BreakUpDoor(KFDoorMover Other, bool bTryDistanceAttack)
{
    bSmashDoor = true;
    super.BreakUpDoor(Other,bTryDistanceAttack);
}

state SpinAttack
{
ignores EnemyNotVisible, GetOutOfTheWayOfShot;

    function DoSpinDamage()
    {
        local Actor A;

        //log("FLESHPOUND DOSPINDAMAGE!");
        foreach CollidingActors(class'actor', A, (KFM.MeleeRange * 1.5)+pawn.CollisionRadius, pawn.Location)
            FemaleFP(pawn).SpinDamage(A);
    }

Begin:

WaitForAnim:
    While( KFM.bShotAnim )
    {
        Sleep(0.1);
        DoSpinDamage();
    }

    WhatToDoNext(152);
    if ( bSoaking )
        SoakStop("STUCK IN SPINATTACK!!!");
}

state ZombieCharge
{
    function BeginState()
    {
        super(KFMonsterController).BeginState();

        // reset rage timer only if FFP smashed a door or hits her target
        if ( bSmashDoor || bHitTarget ) {
            RageFrustrationThreshhold = default.RageFrustrationThreshhold
                    + RageFrustrationThreshholdRand * frand();
            RageFrustrationTimer = 0;
        }

        bSmashDoor = false;
        bHitTarget = false;
    }

    function Frustrate()
    {
        local FemaleFP FFP;

        FFP = FemaleFP(Pawn);

        if( FFP != none && !FFP.bChargingPlayer ) {
            FFP.bFrustrated = true;
            FFP.StartCharging();
        }
    }

    function Tick( float Delta )
    {
        Global.Tick(Delta);

        // Make the FFP rage if she hasn't reached the enemy
        // after a certain amount of time
        if ( RageFrustrationTimer < RageFrustrationThreshhold ) {
            RageFrustrationTimer += Delta;
            if ( RageFrustrationTimer >= RageFrustrationThreshhold ) {
                Frustrate();
            }
        }
    }
}

defaultproperties
{
     RageFrustrationThreshhold=20.0
     RageFrustrationThreshholdRand=10.0
}
