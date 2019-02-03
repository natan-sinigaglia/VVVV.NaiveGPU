
#include "../../../dx11/ParticlesSharedSettings.fxh"
uint groupCount;
uint groupIndexOffset;

float4x4 tV : VIEW ;
float4x4 tVI : VIEWINVERSE ;
float strength = 1;
float power = 1;

float pows(float a, float b) 
{
	return pow(abs(a),b)*sign(a);
}

// =====================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= groupCount) return;
	
	uint particleIndex = DTid.x + groupIndexOffset;
	float3 PosW = Buffer_posLifeT[particleIndex].xyz;

	// Fisheye algorithm
    //float z = pos.z + ( (((pos.x-CamPos.x)*(pos.x-CamPos.x)) +((pos.y-CamPos.y)*(pos.y-CamPos.y))) * strength);
	float4 PosV = mul(float4(PosW, 1), tV);
    float dist = ((PosV.x * PosV.x) + (PosV.y * PosV.y)) * strength;
	dist = pows(dist, power);
    PosV.z += dist;
	PosW = mul(PosV, tVI).xyz;

	Buffer_posLifeT[particleIndex].xyz = PosW;
	
}

technique11 Main { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }
