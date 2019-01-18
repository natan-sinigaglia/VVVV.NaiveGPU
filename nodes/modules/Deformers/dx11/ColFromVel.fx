
#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Size
*/

float4x4 tV : VIEW ;
float4x4 tVI : VIEWINVERSE ;
float PreMult = 1;
float Strength = 1;
float Gamma = 1;

float3 ColMultOffset;

float pows(float a, float b) 
{
	return pow(abs(a),b)*sign(a);
}

// =====================================================

[numthreads(64, 1, 1)]
void Vel_CS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	
	uint particleIndex = DTid.x + GroupIndexOffset;
		
	float3 Vel = Buffer2[particleIndex].xyz;

	float3 colMult = pow(length(Vel.xyz) * PreMult, Gamma) * Strength;
	colMult += ColMultOffset;
	
	Buffer4[particleIndex].xyz *= colMult;
	
}

[numthreads(64, 1, 1)]
void Force_CS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	
	uint particleIndex = DTid.x + GroupIndexOffset;
		
	float3 Force = Buffer3[particleIndex].xyz;

	float3 colMult = pow(length(Force.xyz) * PreMult, Gamma) * Strength;
	colMult += ColMultOffset;
	
	Buffer4[particleIndex].xyz *= colMult;
	
}

technique11 Vel { pass P0{SetComputeShader( CompileShader( cs_5_0, Vel_CS() ) );} }
technique11 Force { pass P0{SetComputeShader( CompileShader( cs_5_0, Force_CS() ) );} }
