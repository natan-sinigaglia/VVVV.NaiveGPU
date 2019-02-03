#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

StructuredBuffer<float4> SpheresData1Buffer; // XYZ = pos ; W = radius
StructuredBuffer<float4> SpheresData2Buffer; // X = BounceCoef ; Y = Friction

//StructuredBuffer<float4> CylindersInfo; 
//StructuredBuffer<float4x4> simInfoBuffer;

cbuffer cbStatic : register(b2)
{
	float ContactThreshold = 0.005;
	uint SpheresDataBufferCount;
	uint SpheresDataBufferOffset;
}

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

	float4 Buffer1Data = Buffer1[Index];
	float4 Buffer2Data = Buffer2[Index];

	float3 Pos = Buffer1Data.xyz;
	float3 Vel = Buffer2Data.xyz;
	float Thickness = Buffer4[Index].w;

	bool friction = false;
	
	for(uint i=0; i<SpheresDataBufferCount; i++)
	{
		uint BufferIndex = i + SpheresDataBufferOffset;

		float4 SpheresData1 = SpheresData1Buffer[BufferIndex];
		float4 SpheresData2 = SpheresData2Buffer[BufferIndex];
		
		float BounceCoef = floor(SpheresData2.w) / 4096;
		float Friction = frac(SpheresData2.w);
		float3 SphereVel = SpheresData2.xyz;
		
		float3 vec = Pos - SpheresData1.xyz ;
		float dist = length(vec);
		float distDiff = SpheresData1.w - dist + Thickness;
		if(distDiff>0)
		{
			Pos += normalize(vec) * distDiff;
			Vel = reflect(Vel, normalize(vec)) * BounceCoef;
		}
		if(distDiff >= -ContactThreshold)
		Vel *= saturate(1-Friction);
	}
	
	Buffer1[Index].xyz = Pos;
	Buffer2[Index].xyz = Vel;
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

	float4 Buffer1Data = Buffer1[Index];
	float4 Buffer2Data = Buffer2[Index];

	float3 Pos = Buffer1Data.xyz;
	float3 Vel = Pos - Buffer2Data.xyz;
	float Thickness = Buffer2Data.w;

	bool friction = false;
	
	for(uint i=0; i<SpheresDataBufferCount; i++)
	{
		uint BufferIndex = i + SpheresDataBufferOffset;

		float4 SpheresData1 = SpheresData1Buffer[BufferIndex];
		float4 SpheresData2 = SpheresData2Buffer[BufferIndex];
		
		float BounceCoef = floor(SpheresData2.w) / 4096;
		float Friction = frac(SpheresData2.w);
		float3 SphereVel = SpheresData2.xyz;
		
		float3 vec = Pos - SpheresData1.xyz ;
		float dist = length(vec);
		float distDiff = SpheresData1.w - dist + Thickness;
		if(distDiff>0)
		{
			Pos += normalize(vec) * distDiff;
			Vel = reflect(Vel, normalize(vec)) * BounceCoef;
		}
		if(distDiff >= -ContactThreshold)
		Vel *= saturate(1-Friction);
	}
	
	Buffer1[Index].xyz = Pos;
	Buffer2[Index].xyz = Pos - Vel;
}


//==============================================================================
// TECHNIQUES ==================================================================
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
