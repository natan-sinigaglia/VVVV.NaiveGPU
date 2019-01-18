
// =============================================================================
// BLACK HOLE HEADER ===========================================================
// =============================================================================

#include "h_Perlin.fxh"

cbuffer cb_BHoleStatic : register(b4)
{
	// Black Hole Properties
	float4x4 blackHole_Transform;
	float4x4 blackHole_invTransform;
	float blackHole_EventHorizonRadius = 0.15;

	// Vortex
	float Vortex_Angle_DistGamma = 1;
	float2 Vortex_Angle_InOutShift = float2(0.22, 0.05);
	float Vortex_Strength_DistGamma = 1;
	float2 Vortex_Strength_InOut = float2(1, 0);
	
	// Accretion Disk
	float Accretion_Strength;
	float Accretion_Strength_DistGamma = 1;
	
	
	// VolField
	float VolField_DistGamma = 1;
	
	// Velocity Factor
	float VelMult_DistGamma = 1;
	float2 VelMult_MinMax = float2(0.9, 1);
	
	// Perlin
	bool Perlin_Enable = 1;
	float Perlin_DistGamma = 1;
	
	float GlobalForceToCenter = 0.003;

}

float2 rotate2D(float2 pos, float angle)
{
    float2 outPos;
    outPos.x = pos.x * cos(angle) - pos.y * sin(angle);
    outPos.y = pos.y * cos(angle) + pos.x * sin(angle);
    return outPos;
}


struct BlackHoleStruct
{
	float3 vec;
	float centerDist;
	float vecMult;
};

BlackHoleStruct blackHoleComplex(float3 p)
{
	BlackHoleStruct Out;
	
	float3 posT = mul(float4(p,1), blackHole_invTransform).xyz;

	float3 vec = -posT * GlobalForceToCenter;
	vec.y = 0;
	float vecMult = 1;
	float centerDist = 1;
	
	
	
	if(abs(posT.x)<=1 && abs(posT.y)<=1 && abs(posT.z)<=1)
	{
		// Main Gradient
		centerDist = length(posT.xyz) * 2;
		float gradToEventOrizon = smoothstep(1, blackHole_EventHorizonRadius, centerDist);
		
		// Vortex
		float angleGrad = 1-pow(gradToEventOrizon, Vortex_Angle_DistGamma);
		float angleShift = lerp(Vortex_Angle_InOutShift.x, Vortex_Angle_InOutShift.y, angleGrad);
		float3 VortexVec = -posT;
		VortexVec.y = 0;
		VortexVec.xz = rotate2D(VortexVec.xz, angleShift * 6.2831853071796);	
		float strength = lerp(Vortex_Strength_InOut.x, Vortex_Strength_InOut.y, 1-pow(gradToEventOrizon, Vortex_Strength_DistGamma));
		vec += normalize(VortexVec) * strength;
		
		// Accretion Disk
		vec.y += -posT.y * pow(gradToEventOrizon, Accretion_Strength_DistGamma) * Accretion_Strength;
		
		// Perlin
		if(Perlin_Enable)
		{
			float3 PerlinForce = float3(	fBm(float4(posT+float3(51,2.36,-5),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers),
								fBm(float4(posT+float3(98.2,-9,-36),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers),
								fBm(float4(posT+float3(0,10.69,6),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers));
			vec += PerlinForce * pow(gradToEventOrizon, Perlin_DistGamma) * Perlin_Strenght;
		}

		// Vel Mult
		vecMult = pow(gradToEventOrizon, VelMult_DistGamma);
		vecMult = lerp(VelMult_MinMax.y, VelMult_MinMax.x, vecMult);
		
		vec = mul(float4(vec,0), blackHole_Transform).xyz;
	}
	Out.vec = vec;
	Out.centerDist = centerDist;
	Out.vecMult = vecMult;
	
	return Out;
}
