// for debugging
class BrainDeadFemaleFP extends FemaleFP;

event PostBeginPlay()
{
	Super.PostBeginPlay();

    SetMovementPhysics();
}

defaultproperties
{
     ControllerClass=None
}
