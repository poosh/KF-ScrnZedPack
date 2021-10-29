class ZedAvoidArea extends FleshPoundAvoidArea;

var float CollisionRadiusMult;

function InitFor(KFMonster M)
{
    if ( M == none )
        return;

    KFMonst = M;
    SetCollisionSize(fmax(CollisionRadius, KFMonst.CollisionRadius * CollisionRadiusMult),
            KFMonst.CollisionHeight + CollisionHeight);
    SetBase(KFMonst);
    SetTimer(1.0, true);
}

function Timer()
{
    if ( KFMonst == none || KFMonst.Health <= 0 ) {
        SetTimer(0, false);
        return;
    }
    StartleBots();
}

function MonsterAvoidMeIfRelevant(KFMonster M)
{
    local KFMonsterController MC;

    if ( !RelevantTo(M) )
        return;

    MC = KFMonsterController(M.Controller);
    if ( MC != none ) {
        MC.AvoidThisMonster(KFMonst);
    }
}

function bool RelevantTo(Pawn P)
{
    local KFMonster M;

    M = KFMonster(P);

    return KFMonst != none && KFMonst.Health > 0
            && M != none && M.Health > 0 && !M.bShotAnim
            && !KFMonst.SameSpeciesAs(M) && !M.SameSpeciesAs(KFMonst)
            && VSizeSquared(KFMonst.Velocity) >= 75
            && KFMonst.Velocity dot (P.Location - KFMonst.Location) > 0;
}

function Touch( actor Other )
{
    MonsterAvoidMeIfRelevant(KFMonster(Other));
}

function StartleBots()
{
    local KFMonster M;

    foreach CollidingActors(class'KFMonster', M, CollisionRadius) {
        MonsterAvoidMeIfRelevant(M);
    }
}

defaultproperties
{
    CollisionRadiusMult=3.0
    CollisionRadius=50.0
    CollisionHeight=40.0
}
