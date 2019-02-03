#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

StructuredBuffer<float4> SpheresData1Buffer; // XYZ = pos ; W = radius
StructuredBuffer<float2> SpheresData2Buffer; // X = BounceCoef ; Y = Friction

//StructuredBuffer<float4> CylindersInfo; 
//StructuredBuffer<float4x4> simInfoBuffer;

float ContactThreshold = 0.005;

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
	float4 Buffer1Data = Buffer1[DTid.x];
	float4 Buffer2Data = Buffer2[DTid.x];

	float3 Pos = Buffer1Data.xyz;
	float3 Vel = Buffer2Data.xyz;

	uint count,dummy;
	SpheresData1Buffer.GetDimensions(count,dummy);

	bool friction = false;
	
	for(uint i=0; i<count; i++)
	{
		float4 SpheresData1 = SpheresData1Buffer[i];
		float2 SpheresData2 = SpheresData2Buffer[i];
		
		float3 vec = Pos - SpheresData1.xyz ;
		float dist = length(vec);
		float distDiff = SpheresData1.w - dist + Buffer2Data.w;
		if(distDiff>0)
		{
			Pos += normalize(vec) * distDiff;
			Vel = reflect(Vel, normalize(vec)) * SpheresData2.x;
		}
		if(distDiff >= -ContactThreshold)
		Vel *= saturate(1-SpheresData2.y);
	}
	
	Buffer1[DTid.x].xyz = Pos;
	Buffer2[DTid.x].xyz = Vel;
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
	float4 Buffer1Data = Buffer1[DTid.x];
	float4 Buffer2Data = Buffer2[DTid.x];

	float3 Pos = Buffer1Data.xyz;
	float3 Vel = Pos - Buffer2Data.xyz;

	uint count,dummy;
	SpheresData1Buffer.GetDimensions(count,dummy);

	bool friction = false;
	
	for(uint i=0; i<count; i++)
	{
		float4 SpheresData1 = SpheresData1Buffer[i];
		float2 SpheresData2 = SpheresData2Buffer[i];
		
		float3 vec = Pos - SpheresData1.xyz ;
		float dist = length(vec);
		float distDiff = SpheresData1.w - dist + Buffer2Data.w;
		if(distDiff>0)
		{
			Pos += normalize(vec) * distDiff;
			Vel = reflect(Vel, normalize(vec)) * SpheresData2.x;
		}
		if(distDiff >= -ContactThreshold)
		Vel *= saturate(1-SpheresData2.y);
	}
	
	Buffer1[DTid.x].xyz = Pos;
	Buffer2[DTid.x].xyz = Pos - Vel;
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
