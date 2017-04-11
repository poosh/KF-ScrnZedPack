//-----------------------------------------------------------
//Still behaves like a Fleshpound for the most part, although quicker to rage.
//Thanks to Scary for the work on this one. - Whisky
//-----------------------------------------------------------
class FFPController extends FleshpoundZombieController;

var bool bFindNewEnemy, bSmashDoor, bStartled, bAttackedTarget, bMissTarget;
var float prevRageTimer,prevRageThreshold;

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

function PostBeginPlay() 
{
    super.PostBeginPlay();
    prevRageThreshold= default.RageFrustrationThreshhold + (Frand() * 5); 
}

function bool FindNewEnemy() 
{
    bFindNewEnemy= true;
    return super.FindNewEnemy();
}

function BreakUpDoor(KFDoorMover Other, bool bTryDistanceAttack) 
{
    bSmashDoor= true;
    super.BreakUpDoor(Other,bTryDistanceAttack);
}

function Startle(Actor Feared) 
{
    bStartled= True;
    super.Startle(Feared);
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
        super.BeginState();

        if (!bSmashDoor && ((bAttackedTarget && bMissTarget) || bFindNewEnemy || bStartled)) 
		{
            RageFrustrationTimer= prevRageTimer;
            RageFrustrationThreshhold= prevRageThreshold;
        }
        bFindNewEnemy= false;
        bSmashDoor= false;
        bStartled= false;
        bAttackedTarget= false;
        bMissTarget= false;
    }

    function EndState() 
	{
        prevRageTimer= RageFrustrationTimer;
        prevRageThreshold= RageFrustrationThreshhold;
    }
    
	function Tick( float Delta )
	{
		local FemaleFP FFP;
        
        Global.Tick(Delta);

        // Make the FP rage if we haven't reached our enemy after a certain amount of time
		if( RageFrustrationTimer < RageFrustrationThreshhold ) {
            RageFrustrationTimer += Delta;

            if( RageFrustrationTimer >= RageFrustrationThreshhold ) {
                FFP = FemaleFP(Pawn);

                if( FFP != none && !FFP.bChargingPlayer ) {
                    FFP.StartCharging();
                    FFP.bFrustrated = true;
                }
            }
		}
	}    
}

defaultproperties
{
     RageFrustrationThreshhold=30.000000
}
