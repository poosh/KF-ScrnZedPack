class ScrnMonsterFlame extends KFMonsterFlame;

var float MinDistSqHigh;
var float MinDistSqNormal;

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    if (Level.NetMode == NM_DedicatedServer || !bDynamicLight)
            return;

    if (Level.DetailMode == DM_Low) {
        bDynamicLight = false;
        LightType = LT_None;
        return;
    }

    Timer();
}

function Timer()
{
    local ScrnMonsterFlame Other;
    local float DistSq;
    local int count;
    local bool bOtherDL;

    if (bDeleteMe || Level.bDropDetail || Level.DetailMode == DM_Low) {
        bDynamicLight = false;
        LightType = LT_None;
        return;
    }

    if (Level.DetailMode == DM_SuperHigh) {
        DistSq = MinDistSqHigh;
    }
    else {
        DistSq = MinDistSqNormal;
    }

    foreach DynamicActors(class'ScrnMonsterFlame', Other) {
        if (Other == self || VSizeSquared(Other.Location - Location) > DistSq)
            continue;

        ++count;
        if (Other.bDynamicLight) {
            bOtherDL = true;
            break;
        }
    }

    if (bOtherDL) {
        bDynamicLight = false;
        LightType = LT_None;
    }
    else {
        bDynamicLight = true;
        LightType = default.LightType;
        LightRadius = default.LightRadius;
        if (count > 0) {
            LightRadius *= 1.0 + sqrt(count);
        }
    }

    SetTimer(0.1 + 0.1 * frand(), false);
}

defaultproperties
{
    bDynamicLight=true
    LightType=LT_Flicker
    LightHue=30
    LightSaturation=100
    LightBrightness=300
    LightRadius=4.0

    MinDistSqHigh=10000  //  2m
    MinDistSqNormal=40000  //4m
}
