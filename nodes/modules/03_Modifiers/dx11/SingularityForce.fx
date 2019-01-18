
#include "../../../dx11/ParticlesSharedSettings.fxh"
uint groupCount;
uint groupIndexOffset;

StructuredBuffer<float3> GaussDirBuffer : GAUSSDIRBUFFER;
StructuredBuffer<float3> RndBuffer : RNDBUFFER;

uint rndOffset;

float globalMult = 1;
float gamma = 1;
float3 dir = float3(0, -1, 0);
bool absY;
float radius = 1;

// =====================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;

	float4 PosLifeT = Buffer_posLifeT[particleIndex];
	float3 Pos = PosLifeT.xyz;
	//float3 Vel = Buffer_velMass[particleIndex].xyz;
	float3 Force = Buffer_force[particleIndex].xyz;
	
	float3 Direction = dir;
	
	if(absY) Direction.y = sign(Direction.y);
	
	float3 singularityForce = pow(saturate(radius/length(Pos.xz)), gamma) * Direction;
	Force += singularityForce * globalMult * PosLifeT.w;
		
	Buffer_force[particleIndex].xyz = Force;
}

technique11 ApplySingularity { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }
