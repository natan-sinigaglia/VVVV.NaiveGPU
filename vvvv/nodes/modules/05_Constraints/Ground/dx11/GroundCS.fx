#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

cbuffer cbPerDraw : register(b0)
{
	float Ground_Level;
	float Ground_BounceCoef = 1;
	float Ground_Friction;
	
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
	float4 Buffer4Data = Buffer4[Index];
	
	float3 Pos = Buffer1Data.xyz;
	float3 Vel = Buffer2Data.xyz;
	
	float TouchLevel = Ground_Level + Buffer4Data.w;
	
	if(Pos.y <= TouchLevel)
	{
		Vel.y *= -Ground_BounceCoef;
		Vel.xz *= saturate(1-Ground_Friction);
	}
	
	Pos.y = max(Pos.y, TouchLevel);

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

	float4 PosMass = Buffer1[Index];
	float4 PrevPosThickness = Buffer2[Index];

	float3 Pos = Buffer1Data.xyz;
	//float Mass = PosMass.w;
	float3 PrevPos = PrevPosThickness.xyz;
	float Thickness = PrevPosThickness.w;
	
	float3 Vel = Pos - PrevPos;

	float TouchLevel = Ground_Level + Thickness;
	//bool Touching = Pos.y <= TouchLevel;
	
	// Ground Friction
	if(Pos.y <= TouchLevel)
	Vel.xz *= Ground_Friction;
	if(Pos.y < TouchLevel)
	Vel.y *= -Ground_BounceCoef;
	
	// Reflect Pos Y
	//float DeltaY = max(TouchLevel - Pos.y , 0) * Ground_BounceCoef;
	//Pos.y += 2 * DeltaY;
	Pos.y = max(Pos.y, TouchLevel);
		
	//PrevPos.y = Pos.y - Vel.y;
	
	Buffer1[Index].xyz = Pos;
	Buffer2[Index].xyz = Pos - Vel;}

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
