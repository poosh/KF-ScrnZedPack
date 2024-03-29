class FFPVentEmitter extends VehicleExhaustEffect;

defaultproperties
{
     MaxSpritePPSOne=20
     MaxSpritePPSTwo=22
     IdleSpritePPSOne=5
     IdleSpritePPSTwo=7

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         UseVelocityScale=True
         Acceleration=(X=70.000000,Z=20.000000)
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=50))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255))
         FadeOutStartTime=0.100000
         MaxParticles=20
         UseRotationFrom=PTRS_Actor
         SpinsPerSecondRange=(X=(Min=-0.075000,Max=0.075000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=0.070000,RelativeSize=0.500000)
         SizeScale(2)=(RelativeTime=0.370000,RelativeSize=1.100000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=2.500000)
         StartSizeRange=(X=(Min=15.000000,Max=30.000000))
         InitialParticlesPerSecond=5.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'Effects_Tex.Vehicles.Gasoline_Smoke'
         TextureUSubdivisions=2
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.300000)
         StartVelocityRange=(X=(Min=45.000000,Max=300.000000),Y=(Min=-45.000000,Max=45.000000),Z=(Min=-45.000000,Max=45.000000))
         VelocityScale(0)=(RelativeVelocity=(X=1.000000,Y=1.000000,Z=1.000000))
         VelocityScale(1)=(RelativeTime=0.300000,RelativeVelocity=(X=0.200000,Y=1.000000,Z=1.000000))
         VelocityScale(2)=(RelativeTime=1.000000,RelativeVelocity=(Y=0.400000,Z=0.400000))
     End Object
     Emitters(0)=SpriteEmitter1

     Begin Object Class=SpriteEmitter Name=SpriteEmitter2
         FadeOut=True
         FadeIn=True
         AutoReset=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         UseVelocityScale=True
         Acceleration=(X=70.000000,Z=20.000000)
         ColorScale(0)=(Color=(B=128,G=128,R=128,A=50))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255))
         FadeOutStartTime=0.100000
         MaxParticles=20
         AutoResetTimeRange=(Min=5.000000,Max=10.000000)
         UseRotationFrom=PTRS_Actor
         SpinsPerSecondRange=(X=(Min=-0.075000,Max=0.075000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=0.070000,RelativeSize=0.500000)
         SizeScale(2)=(RelativeTime=0.370000,RelativeSize=1.100000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=2.500000)
         StartSizeRange=(X=(Min=11.000000,Max=21.000000))
         InitialParticlesPerSecond=5.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'Effects_Tex.Vehicles.Deisel_Smoke'
         TextureUSubdivisions=2
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.300000)
         StartVelocityRange=(X=(Min=45.000000,Max=300.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-10.000000,Max=10.000000))
         VelocityScale(0)=(RelativeVelocity=(X=1.000000,Y=1.000000,Z=1.000000))
         VelocityScale(1)=(RelativeTime=0.400000,RelativeVelocity=(X=0.150000,Y=1.000000,Z=1.000000))
         VelocityScale(2)=(RelativeTime=1.000000,RelativeVelocity=(Y=0.400000,Z=0.400000))
     End Object
     Emitters(1)=SpriteEmitter2

     AutoDestroy=True
     bNetTemporary=True
     RemoteRole=ROLE_None
     LifeSpan=8
     bHardAttach=False
     bDirectional=True
}
