#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"

int iterIndex : ITERATIONINDEX;
int iterCount : ITERATIONCOUNT;

cbuffer cbDynamic : register(b0)
{
	float tStepMult = 1;
	float3 Gravity = float3(0, -9.81, 0);
}

cbuffer cbStatic : register(b1)
{
	float DragMult = 1;
	float MassMult = 1;
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
	Buffer4 = Col, Size
*/

[numthreads(64, 1, 1)]
void EulerCS( uint3 DTid : SV_DispatchThreadID )
{	
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;
	
	float4 posLifeT = Buffer1[Index];
	float lifeT = posLifeT.w ;
	
	if(lifeT < 0) return;
	
	float dT = tStep / iterCount;

	float3 pos = posLifeT.xyz;
	
	float4 velMass = Buffer2[Index];	
	float3 Vel = velMass.xyz;
	float mass = max(abs(velMass.w), 0.000001);
	
	float3 Force = Buffer3[Index].xyz;
	
	
	// INTEGRATION
	// Drag force:
	Force += -Vel * DragMult;
	
	//get acceleration from force (by dividing by Mass):
	float3 acc = Force / mass;
	acc += Gravity;

	// get final velocity:
	Vel += acc * dT;
	Buffer2[Index].xyz = Vel;
	
	float3 newPos = pos + Vel * dT;
	Buffer1[Index] = float4(newPos, lifeT + dT);
	Buffer2[Index].w = mass;
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

	float4 PosMass = Buffer1[Index];
	float4 PrevPosThickness = Buffer2[Index];
	float4 ForceDrag = Buffer3[Index];
	
	float3 Pos = PosMass.xyz;
	float Mass = abs(PosMass.w);
	float3 PrevPos = PrevPosThickness.xyz;
	float Thickness = PrevPosThickness.w;
	float3 Force = ForceDrag.xyz;
	float Drag = ForceDrag.w * DragMult;
	
	float3 Vel = Pos - PrevPos;
	
	// Drag force:
	Force += -Vel * Drag;
	
	//get acceleration from force (by dividing by Mass):
	float3 Acc = (Force / (Mass * MassMult));
	Acc += Gravity;
	
	// get final velocity:
	float finalTimeStep = tStep * tStepMult;
	Vel += Acc * (finalTimeStep * finalTimeStep);
	
	Buffer1[Index].xyz = Pos + Vel;
	Buffer2[Index].xyz = Pos;
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
