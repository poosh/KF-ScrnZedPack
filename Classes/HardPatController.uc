class HardPatController extends ZedControllerBoss;

var NavigationPoint MidGoals[2];
var byte ReachOffset;
var Actor OldPathsCheck[3];


function FindPathAround()
{
    local Actor Res;
    local NavigationPoint N;
    local NavigationPoint OldPts[12];
    local byte i;
    local bool bResult;

    if( Enemy==None || VSizeSquared(Enemy.Location-Pawn.Location)<360000 )
        return; // No can do this.

    // Attempt to find an alternative path to enemy.
    /* This works by:
        - finding shortest path to enemy
        - block middle path point
        - if the path is still about same to enemy, try block the new path and repeat up to 6 times.
    */
    for( i=0; i<ArrayCount(OldPts); ++i )
    {
        Res = FindPathToward(Enemy);
        if( Res==None )
            break;
        if( i>0 && CompareOldPaths() )
        {
            bResult = true;
            break;
        }
        N = GetMidPoint();
        if( N==None )
            break;
        N.bBlocked = true;
        OldPts[i] = N;
        if( i==0 )
            SetOldPaths();
    }

    // Unblock temp blocked paths.
    for( i=0; i<ArrayCount(OldPts); ++i )
        if( OldPts[i]!=None )
            OldPts[i].bBlocked = false;
    if( !bResult )
        return;

    // Fetch results and switch state.
    GetMidGoals();
    if( ReachOffset<2 )
        GoToState('PatFindWay');
}

function NavigationPoint GetMidPoint()
{
    local byte n;

    for( n=0; n<ArrayCount(RouteCache); ++n )
        if( RouteCache[n]==None )
            break;
    if( n==0 )
        return None;
    return NavigationPoint(RouteCache[(n-1)*0.5]);
}

function bool CompareOldPaths()
{
    local byte n,i;

    for( i=0; i<6; ++i )
    {
        if( RouteCache[i]==None )
            break;
        for( n=0; n<ArrayCount(OldPathsCheck); ++n )
            if( RouteCache[i]==OldPathsCheck[n] )
                return false;
    }
    return true;
}

function SetOldPaths()
{
    local byte n;

    for( n=0; n<ArrayCount(OldPathsCheck); ++n )
        OldPathsCheck[n] = RouteCache[n+1];
    if( RouteCache[1]==None )
        OldPathsCheck[0] = RouteCache[0];
}

function GetMidGoals()
{
    local byte n;

    for( n=0; n<ArrayCount(RouteCache); ++n )
        if( RouteCache[n]==None )
            break;
    if( n==0 )
    {
        ReachOffset = 2;
        return;
    }
    --n;
    MidGoals[0] = NavigationPoint(RouteCache[n*0.5]);
    MidGoals[1] = NavigationPoint(RouteCache[n]);
    if( MidGoals[0]==MidGoals[1] )
        ReachOffset = 1;
    else ReachOffset = 0;
}

function bool CanKillMeYet()
{
    return false;
}

state PatFindWay
{
Ignores Timer,SeePlayer,HearNoise,DamageAttitudeTo,EnemyChanged,Startle,Tick;

    final function PickDestination()
    {
        if( ReachOffset>=2 )
        {
            GotoState('ZombieHunt');
            return;
        }
        if( ActorReachable(MidGoals[ReachOffset]) )
        {
            MoveTarget = MidGoals[ReachOffset];
            ++ReachOffset;
        }
        else
        {
            MoveTarget = FindPathToward(MidGoals[ReachOffset]);
            if( MoveTarget==None )
                ++ReachOffset;
        }
    }
    function BreakUpDoor( KFDoorMover Other, bool bTryDistanceAttack )
    {
        Global.BreakUpDoor(Other,bTryDistanceAttack);
        Pawn.GoToState('');
    }
Begin:
    PickDestination();
    if( MoveTarget==None )
        Sleep(0.5f);
    else MoveToward(MoveTarget,MoveTarget,,False);
    GoTo'Begin';
}

defaultproperties
{
}
