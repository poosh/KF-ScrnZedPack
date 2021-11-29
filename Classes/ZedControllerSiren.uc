class ZedControllerSiren extends SirenZombieController;

state ZombieCharge
{
    function HearNoise(float Loudness, Actor NoiseMaker)
    {
        if ( NoiseMaker != none )
            super.HearNoise(Loudness, NoiseMaker);
    }
}
