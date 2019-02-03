
#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Size
*/

uint groupCount;
uint groupIndexOffset;

cbuffer cbPerDraw : register(b0)
{
	float4 InOutTime = float4(0, 0.3, 10, 20);
	float SizeMult = 0.05f;
	float RndSizeAmount = 0;
}

// =====================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;

	float4 Buffer1Data = Buffer1[particleIndex];
	float LifeT = Buffer1Data.w;
	
	// Life Time Fading
	float animScale = smoothstep(InOutTime.x, InOutTime.y, LifeT);
	animScale *= smoothstep(InOutTime.w, InOutTime.z, LifeT);
	
	float rndScale = RndBuffer[particleIndex%4096].x * RndSizeAmount + 1;
	Buffer4[particleIndex].w *= animScale * SizeMult * rndScale;
}

technique11 Main { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }
