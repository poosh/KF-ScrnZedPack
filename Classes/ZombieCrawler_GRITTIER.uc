// Code originally was taken from Scary Ghost's Super Zombies mutator
class ZombieCrawler_GRITTIER extends ZombieCrawler;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    PounceSpeed= Rand(221)+330;
    MeleeRange= Rand(41)+50;
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

defaultproperties
{
    DetachedArmClass=class'SeveredArmCrawler'
	DetachedLegClass=class'SeveredLegCrawler'
	DetachedHeadClass=class'SeveredHeadCrawler'

    Mesh=SkeletalMesh'KF_Freaks_Trip.Crawler_Freak'

    Skins(0)=Combiner'ScrnZedPack_T.crawler_grittier.crawler_grittier_cmb'

    AmbientSound=Sound'KF_BaseCrawler.Crawler_Idle'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Crawler_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Crawler_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Crawler_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Crawler_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Crawler_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Crawler_Acquire'

    MenuName="Crawler.se"
    GroundSpeed=190.000000
    WaterSpeed=175.000000
}

