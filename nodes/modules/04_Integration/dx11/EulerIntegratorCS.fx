#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Size
*/

int iterIndex : ITERATIONINDEX;
int iterCount : ITERATIONCOUNT;

// Velocity
float Drag;
float3 Gravity;

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	if(DTid.x >= (uint)ElementCount) return;
	
	float4 posLifeT = Buffer1[DTid.x];
	float lifeT = posLifeT.w ;
	
	if(lifeT < 0) return;
	
	float dT = tStep / iterCount;

	float3 pos = posLifeT.xyz;
	
	float4 velMass = Buffer2[DTid.x];	
	float3 Vel = velMass.xyz;
	float mass = max(velMass.w, 0.000001);
	
	float3 Force = Buffer3[DTid.x].xyz;
	
	
	// INTEGRATION
	// Drag force:
	Force += -Vel * Drag;
	
	float3 acc = Force / mass;
	acc += Gravity;
	Vel += acc * dT;
	Buffer2[DTid.x].xyz = Vel;
	
	float3 newPos = pos + Vel * dT;
	Buffer1[DTid.x] = float4(newPos, lifeT + dT);
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 integration
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}

