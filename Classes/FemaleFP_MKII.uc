class FemaleFP_MKII extends FemaleFP;

struct SDamageResistance
{
    var class<KFWeaponDamageType> DamType;
    var byte ResistanceLevel;
    var float AdaptTime;
};
var array<SDamageResistance> DamageRes;
var array<float> ResistanceLevels;
var float AdaptInterval; // how long does it takes for FFP to adapt to received damage

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    local int OldHealth;
    local class<KFWeaponDamageType> KFDamType;
    local int i;

    if ( damageType == class'DamTypeVomit' || damageType == class'DamTypeTeslaBeam' )
        return;  // full resistance

    // optimizes typecasting and make code comre compact -- PooSH
    KFDamType = class<KFWeaponDamageType>(damageType);
    oldHealth= Health;

    if ( KFDamType != none ) {
        if ( KFDamType.default.bIsExplosive ) {
            if ( KFDamType == class'DamTypeFrag' )
                Damage *= 2.00;
            else if ( !ClassIsChildOf(KFDamType, class'DamTypeLAW'))
                Damage *= 1.25;
        }
        else if ( ClassIsChildOf(KFDamType, class'DamTypeCrossbow') )
            KFDamType = class'DamTypeCrossbowHeadShot'; // apply same resistance on similar damage types
        else if ( ClassIsChildOf(KFDamType, class'DamTypeM99SniperRifle') ) {
            KFDamType = class'DamTypeM99HeadShot';
            Damage *= 0.75; // additional damage resistance to M99
        }
        else if ( ClassIsChildOf(KFDamType, class'DamTypeCrossbuzzsaw') ) {
            KFDamType = class'DamTypeCrossbuzzsawHeadShot';
            Damage *= 0.75;
        }

        for ( i=0; i<DamageRes.length; ++i ) {
            if ( DamageRes[i].DamType == KFDamType ) {
                if ( Level.TimeSeconds < DamageRes[i].AdaptTime ) {
                    if ( DamageRes[i].ResistanceLevel > 0 )
                        Damage *= ResistanceLevels[DamageRes[i].ResistanceLevel-1]; // skin is not adapted to this damage type yet
                }
                else {
                    Damage *= ResistanceLevels[DamageRes[i].ResistanceLevel];
                    if ( DamageRes[i].ResistanceLevel + 1 < ResistanceLevels.length ) {
                        DamageRes[i].ResistanceLevel++;
                        DamageRes[i].AdaptTime = Level.TimeSeconds + AdaptInterval;
                    }
                }
                break;
            }
        }
        if ( i == DamageRes.length ) {
            // new damage type
            DamageRes.insert(i, 1);
            DamageRes[i].DamType = KFDamType;
            DamageRes[i].AdaptTime = Level.TimeSeconds + AdaptInterval;
        }
    }

    // Shut off her "Device" when dead
    if (Damage >= Health)
        PostNetReceive();

    // fixes none-reference erros when taking enviromental damage -- PooSH
    if (InstigatedBy == none || KFDamType == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType); // skip NONE-reference error
    else
        super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);


    Damage = OldHealth - Health;

    // Starts charging if single damage > 300 or health drops below 50% on hard difficulty or below,
    // or health <75% on Suicidal/HoE
    // -- PooSH
    if ( Health > 0 && !bDecapitated && !bChargingPlayer
            && !bZapped && (!(bCrispified && bBurnified) || bFrustrated)
            && (Damage > RageDamageThreshold || Health < HealthMax*0.5
                || (Level.Game.GameDifficulty >= 5.0 && Health < HealthMax*0.75)) )
        StartCharging();
}

simulated function DeviceGoRed()
{
    Skins[3]=Shader'ScrnZedPack_T.FFP.FFPLights_Blue_shader';
    Skins[1]=Combiner'ScrnZedPack_T.FFP.FFP_Metal_B_cmb';
    Skins[4]=Shader'ScrnZedPack_T.FFP.FFP_Skin1_B_Sdr';
}

simulated function DeviceGoNormal()
{
    Skins[3]=Shader'ScrnZedPack_T.FFP.FFPLights_Green_shader';
    Skins[1]=Combiner'ScrnZedPack_T.FFP.FFP_Metal_G_cmb';
    Skins[4]=Shader'ScrnZedPack_T.FFP.FFP_Skin1_Sdr';
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.FFP.BraTexture');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.FFP.FFP_Metal_G_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.FFP.FFP_Metal_B_cmb');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFPLights_Green_shader');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFPLights_Blue_shader');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFP_Skin1_Sdr');
    myLevel.AddPrecacheMaterial(Shader'ScrnZedPack_T.FFP.FFP_Skin1_B_Sdr');
}

defaultproperties
{
    MenuName="Female FleshPound MKII"
    Skins(1)=Combiner'ScrnZedPack_T.FFP.FFP_Metal_G_cmb'
    Skins(2)=Combiner'ScrnZedPack_T.FFP.FFP_Metal_G_cmb'
    Skins(3)=Shader'ScrnZedPack_T.FFP.FFPLights_Green_shader'
    Skins(4)=Shader'ScrnZedPack_T.FFP.FFP_Skin1_Sdr'

    HeadHealth=800 // up from 600 to prevent easy killing in small team game
    PlayerNumHeadHealthScale=0.175 // same head health as FFP1 in 6p game

    AdaptInterval=0.5
    ResistanceLevels(0)=0.5
    ResistanceLevels(1)=0.25
    ResistanceLevels(2)=0.15
    DamageRes(0)=(DamType=class'KFMod.DamTypeCrossbowHeadShot')
    DamageRes(1)=(DamType=class'KFMod.DamTypeM99HeadShot')
