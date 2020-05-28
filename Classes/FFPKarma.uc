/*
    This object is used to load bRagdolls config variable
    Clients, who have no config (and probabaly have no karma data), 
    will have karma ragdoll death animations turned off.
    
    @author PooSH 
    @author Marco 
*/

Class FFPKarma extends Object
    Config(FemaleFPMut)
    PerObjectConfig;

var config bool bRagdolls;
var config bool bAutoDetect;

var private bool bHasInit,bRagdoll;

static final function InitConfig(LevelInfo Level)
{
    local FFPKarma D;

    Default.bHasInit = true;

    if ( Level.NetMode == NM_DedicatedServer ) {
        Default.bRagdoll = false;
    }
    else if ( Level.PlatformIsWindows() ) {
        // DIR command doesn't work on Linux. Not sure about MacOS
        Default.bRagdoll = Level.GetLocalPlayerController().ConsoleCommand("DIR ../KarmaData/FFPKarma.ka") ~= "FFPKarma.ka";
    }
    else {
        // read from config. create config file, if it doesn't exist
        D = New(None,"FemaleFPKarma") Class'FFPKarma';
        Default.bRagdoll = D.bRagdolls;
        if ( Level.PlatformIsWindows() ) {
            if ( Level.GetLocalPlayerController().ConsoleCommand("DIR ../KarmaData/FFPKarma.ka") ~= "FFPKarma.ka" ) {
                // karma file exists
                if ( default.bAutoDetect )
                    Default.bRagdolls = true; // enable it in config for the next use, but don't enable it now. For cases, when karma file is obtained via MusicLoader
            }
            else {
                // karma file doesn't exist - disable ragdoll animations
                Default.bRagdolls = false;
                Default.bRagdoll = false;
            }
        }
        D.SaveConfig();
    }
}
static final function bool UseRagdoll(LevelInfo Level)
{
    if( !Default.bHasInit )
        InitConfig(Level);
    return Default.bRagdoll;
}

defaultproperties
{
    bAutoDetect=True
}
