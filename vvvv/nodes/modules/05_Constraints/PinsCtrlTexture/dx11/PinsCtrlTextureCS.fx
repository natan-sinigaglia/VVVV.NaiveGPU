#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

float Strength = 1;

Texture2D pinsTex <string uiname="Pins Texture";>;
SamplerState linearSampler <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

//==============================================================================
//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================
//==============================================================================

//==============================================================================
// EULER INTEGRATION ===========================================================
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Thickness
*/

[numthreads(64, 1, 1)]
void EulerCS( uint3 DTid : SV_DispatchThreadID )
{	
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float4 Buffer4Data = Buffer4[Index];

	uint resX, resY;
	pinsTex.GetDimensions(resX, resY);
	float4 TexData = pinsTex.Load(uint3(Buffer4Data.xy * float2(resX-1,resY-1),0));
	//float4 TexData = pinsTex.SampleLevel(linearSampler, Buffer4Data.xy,0);
	TexData.w *= Strength;
		
	float4 Buffer1Data = Buffer1[Index];
	float Mass = Buffer2[Index].w;
	
	if(TexData.w <= 0) return;
	
	else if(TexData.w >= 0.999)
	{
		Buffer2[Index].w = -abs(Buffer2[Index].w);
		Buffer1Data.xyz = TexData.xyz;
	}
	else
	Buffer1Data.xyz = lerp(Buffer1Data.xyz, TexData.xyz, TexData.w * TexData.w);
	
	Buffer1[Index] = Buffer1Data;
}

//==============================================================================
// VERLET INTEGRATION ==========================================================
/*
	Buffer1 = Pos, Mass;
	Buffer2 = PrevPos, Thickness;
	Buffer3 = Force, Drag;
	Buffer4 = Info (UVZ coords, ObjectID);
*/

[numthreads(64, 1, 1)]
void VerletCS( uint3 DTid : SV_DispatchThreadID )
{	
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float4 Buffer4Data = Buffer4[Index];

	uint resX, resY;
	pinsTex.GetDimensions(resX, resY);
	float4 TexData = pinsTex.Load(uint3(Buffer4Data.xy * float2(resX-1,resY-1),0));
	//float4 TexData = pinsTex.SampleLevel(linearSampler, Buffer4Data.xy,0);
		
	
	if(TexData.w <= 0) return;

	float4 Buffer1Data = Buffer1[Index];
	float Mass = Buffer1Data.w;

	if(TexData.w >= 0.9999)
	{
		Buffer1Data.w = -abs(Mass);
		Buffer1Data.xyz = TexData.xyz;
	}
	else
	{
		Buffer1Data.xyz = lerp(Buffer1Data.xyz, TexData.xyz, saturate(TexData.w * TexData.w));
		Buffer1Data.w = Mass;
	}
	Buffer1[Index] = Buffer1Data;
}

//==============================================================================
//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================
//==============================================================================

technique11 Euler
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, EulerCS() ) );
	}
}

technique11 Verlet
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, VerletCS() ) );
	}
}
