
// =============================================================================
// VORTEX CYLINDER HEADER ======================================================
// =============================================================================

cbuffer cb_TornadoStatic : register(b8)
{
	float3 tornado_Pos;
	float tornado_DistMult = 1;
	float tornado_Strength = 1;
	float tornado_axisNoiseAmount;
	float tornado_axisNoiseFreq;
	float4x4 tornado_forceT;
}
	float tornado_axisNoiseTime;

float3 tornado(float3 pos)
{
	float3 tornadoVec = 0;
	
	float2 centerPos = 	tornado_Pos.xz + 
						tornado_axisNoiseAmount * float2(	inoise(float4(float3(tornado_Pos.x,pos.y,tornado_Pos.z) * tornado_axisNoiseFreq, tornado_axisNoiseTime)),
															inoise(float4(float3(tornado_Pos.x-86.2,pos.y,tornado_Pos.z+35.684) * tornado_axisNoiseFreq, tornado_axisNoiseTime)) );

	float3 vec = float3(float3(centerPos.x,pos.y,centerPos.y) - pos);
	
	float dist = length(vec);
	dist = min(1, dist+0.8);
	float factor = tornado_DistMult/dist;	
		
	return factor * tornado_Strength * normalize(mul(normalize(vec), (float3x3)tornado_forceT));
}
