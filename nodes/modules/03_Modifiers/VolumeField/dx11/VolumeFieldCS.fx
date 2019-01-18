#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

cbuffer cbPerDraw : register(b0)
{
	float4x4 VolumeField_tW : WORLD;
	float3 VolumeField_Strength = 1;
}

Texture3D VolumeTexture3D;
SamplerState volumeSampler
{
	Filter  = MIN_MAG_MIP_LINEAR;
	AddressU = Border;
	AddressV = Border;
	AddressW = Border;
};

//==============================================================================
//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================
//==============================================================================

//==============================================================================
// ADD TO FORCE ================================================================

[numthreads(64, 1, 1)]
void ForceCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float4 p = mul(float4(Buffer1[Index].xyz,1), VolumeField_tW);
	float3 force =  VolumeTexture3D.SampleLevel(volumeSampler,((p.xyz) + 0.5 ),0).xyz * VolumeField_Strength;

	Buffer3[Index].xyz += force;
}

//==============================================================================
// ADD TO VEL ==================================================================
// (ONLY EULER)

[numthreads(64, 1, 1)]
void VelCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float4 p = mul(float4(Buffer1[Index].xyz,1), VolumeField_tW);
	float3 vel =  VolumeTexture3D.SampleLevel(volumeSampler,((p.xyz) + 0.5 ),0).xyz * VolumeField_Strength;

	Buffer2[Index].xyz += vel;
}

//==============================================================================
//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================
//==============================================================================

technique11 AddToForce { pass P0{SetComputeShader( CompileShader( cs_5_0, ForceCS() ) );} }
technique11 AddToVel { pass P0{SetComputeShader( CompileShader( cs_5_0, VelCS() ) );} }
