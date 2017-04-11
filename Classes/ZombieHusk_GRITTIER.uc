// Code originally was taken from Scary Ghost's Super Zombies mutator
class ZombieHusk_GRITTIER extends ZombieHusk;

#exec OBJ LOAD FILE=ScrnZedPack_T.utx

var int ShotsRemaining;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{//should be derived and used.
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.husk_grittier.husk_grittier_diff');
    myLevel.AddPrecacheMaterial(Texture'ScrnZedPack_T.husk_grittier.husk_grittier_emissive_mask');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_energy_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_env_cmb');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_fire_cmb');
    myLevel.AddPrecacheMaterial(Material'ScrnZedPack_T.husk_grittier.husk_grittier_shdr');
    myLevel.AddPrecacheMaterial(Combiner'ScrnZedPack_T.husk_grittier.husk_grittier_cmb');
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    ShotsRemaining = Rand(default.ShotsRemaining) + 1;
}

function TakeDamage(int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector momentum, class<DamageType> DamType, optional int HitIndex)
{
    if (InstigatedBy == none || class<KFWeaponDamageType>(DamType) == none)
        Super(Monster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType); // skip NONE-reference error
    else
        Super(KFMonster).TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType);
}

function RangedAttack(Actor A) {
    local int LastFireTime;

    if ( bShotAnim )
        return;

    if ( Physics == PHYS_Swimming ) {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius ) {
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        //PlaySound(sound'Claw2s', SLOT_Interact); KFTODO: Replace this
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if ( (KFDoorMover(A) != none ||
            (!Region.Zone.bDistanceFog && VSize(A.Location-Location) <= 65535) ||
            (Region.Zone.bDistanceFog && VSizeSquared(A.Location-Location) < (Square(Region.Zone.DistanceFogEnd) * 0.8)))  // Make him come out of the fog a bit
            && !bDecapitated )
    {
        bShotAnim = true;

        SetAnimAction('ShootBurns');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);

        if(--ShotsRemaining > 0) {
            NextFireProjectileTime= Level.TimeSeconds;
        }
        else {
            NextFireProjectileTime = Level.TimeSeconds + ProjectileFireInterval + (FRand() * 2.0);
            ShotsRemaining = Rand(default.ShotsRemaining) + 1;
        }
    }
}

function SpawnTwoShots() {
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;
    local KFMonsterController KFMonstControl;

    if( Controller!=None && KFDoorMover(Controller.Target)!=None ) {
        Controller.Target.TakeDamage(22,Self,Location,vect(0,0,0),Class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation,X,Y,Z);
    FireStart = GetBoneCoords('Barrel').Origin;
    if ( !SavedFireProperties.bInitialized ) {
        SavedFireProperties.AmmoClass = Class'SkaarjAmmo';
        SavedFireProperties.ProjectileClass = Class'HuskFireProjectileSE';
        SavedFireProperties.WarnTargetPct = 1;
        SavedFireProperties.MaxRange = 65535;
        SavedFireProperties.bTossed = False;
        SavedFireProperties.bTrySplash = true;
        SavedFireProperties.bLeadTarget = True;
        SavedFireProperties.bInstantHit = False;
        SavedFireProperties.bInitialized = True;
    }

    // Turn off extra collision before spawning vomit, otherwise spawn fails
    ToggleAuxCollision(false);

    FireRotation = Controller.AdjustAim(SavedFireProperties,FireStart,600);

    foreach DynamicActors(class'KFMonsterController', KFMonstControl) {
        if( KFMonstControl != Controller ) {
            if( PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75 ) {
                KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation),FireStart);
            }
        }
    }

    Spawn(Class'HuskFireProjectileSE',Self,,FireStart,FireRotation);

    // Turn extra collision back on
    ToggleAuxCollision(true);
}


defaultproperties
{
    DetachedArmClass=class'SeveredArmHusk'
    DetachedSpecialArmClass=class'SeveredArmHuskGun'
    DetachedLegClass=class'SeveredLegHusk'
    DetachedHeadClass=class'SeveredHeadHusk'

    Mesh=SkeletalMesh'KF_Freaks2_Trip.Burns_Freak'

    Skins(0)=Texture'ScrnZedPack_T.husk_grittier.husk_grittier_tatters'
    Skins(1)=Shader'ScrnZedPack_T.husk_grittier.husk_grittier_shdr'

    AmbientSound=Sound'KF_BaseHusk.Husk_IdleLoop'
    MoanVoice=Sound'KF_EnemiesFinalSnd.Husk_Talk'
    JumpSound=Sound'KF_EnemiesFinalSnd.Husk_Jump'
    MeleeAttackHitSound=sound'KF_EnemiesFinalSnd.Bloat_HitPlayer'

    HitSound(0)=Sound'KF_EnemiesFinalSnd.Husk_Pain'
    DeathSound(0)=Sound'KF_EnemiesFinalSnd.Husk_Death'

    ChallengeSound(0)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'
    ChallengeSound(1)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'
    ChallengeSound(2)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'
    ChallengeSound(3)=Sound'KF_EnemiesFinalSnd.Husk_Challenge'

    MenuName="Husk.se"
    ShotsRemaining=4
    ControllerClass=Class'ScrnZedPack.HuskZombieControllerSE'

    // Husk doesn't have burning animations
    BurningWalkFAnims(0)="WalkF"
    BurningWalkFAnims(1)="WalkF"
    BurningWalkFAnims(2)="WalkF"
    BurningWalkAnims(0)="WalkB"
    BurningWalkAnims(1)="WalkL"
    BurningWalkAnims(2)="WalkR"
}