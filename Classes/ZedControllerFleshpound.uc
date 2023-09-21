class ZedControllerFleshpound extends FleshpoundZombieController;

state ZombieCharge
{
    function BeginState()
    {
        local ZedBaseFleshpound FP;

        super.BeginState();
        FP = ZedBaseFleshpound(Pawn);
        if (FP != none && FP.bDelayedCharge) {
            FP.bDelayedCharge = false;
            RageFrustrationThreshhold = 0.1;
        }

    }
    function HearNoise(float Loudness, Actor NoiseMaker)
    {
        if ( NoiseMaker != none )
            super.HearNoise(Loudness, NoiseMaker);
    }
}
