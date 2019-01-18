#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

#include "h_Attractor.fxh"

// =====================================================

[numthreads(64, 1, 1)]
void ForceCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;
	
	float3 Pos = Buffer1[Index].xyz;

	Buffer3[Index].xyz +=  Attractors(Pos, RndBuffer[Index%2048].xyz, GaussBuffer[Index%2048].yzw);
}

[numthreads(64, 1, 1)]
void VelCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;
	
	float3 Pos = Buffer1[Index].xyz;
	
	Buffer2[Index].xyz += Attractors(Pos, RndBuffer[Index%2048].xyz, GaussBuffer[Index%2048].yzw);
}

technique11 AddToForce { pass P0{SetComputeShader( CompileShader( cs_5_0, ForceCS() ) );} }
technique11 AddToVel { pass P0{SetComputeShader( CompileShader( cs_5_0, VelCS() ) );} }
