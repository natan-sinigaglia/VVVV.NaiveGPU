
#include "../../../dx11/ParticlesSharedSettings.fxh"
uint groupCount;
uint groupIndexOffset;

#include "h_Perlin.fxh"
#include "h_Tornado.fxh"


// =====================================================

[numthreads(64, 1, 1)]
void CSVel( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;

	float3 Pos = Buffer_posLifeT[particleIndex].xyz;
	
	// PERLIN:
	float3 PerlinForce = tornado(Pos);
	
	Buffer_velMass[particleIndex].xyz += PerlinForce;
}

[numthreads(64, 1, 1)]
void CSForce( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;

	float3 Pos = Buffer_posLifeT[particleIndex].xyz;
	
	// PERLIN:
	float3 PerlinForce = tornado(Pos);

	Buffer_force[particleIndex].xyz += PerlinForce;
}

technique11 AddToVel { pass P0{SetComputeShader( CompileShader( cs_5_0, CSVel() ) );} }
technique11 AddToForce { pass P0{SetComputeShader( CompileShader( cs_5_0, CSForce() ) );} }
