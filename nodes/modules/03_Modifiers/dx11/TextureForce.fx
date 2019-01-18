/*
#include <packs/dx11.particles/nodes/modules/Core/fxh/Core.fxh>
#include <packs\dx11.particles\nodes\modules\Core\fxh\IndexFunctions_Particles.fxh>
#include <packs\dx11.particles\nodes\modules\Core\fxh\IndexFunctions_DynBuffer.fxh>
#include <packs/dx11.particles/nodes/modules/Core/fxh/TextureFunctions.fxh>
*/
#include "../../../dx11/ParticlesSharedSettings.fxh"
uint groupCount;
uint groupIndexOffset;

float Mult = 1;

// =====================================================
//                  TEXTURE FUNCTIONS

SamplerState s0: IMMUTABLE {Filter = MIN_MAG_MIP_POINT;AddressU=Border;AddressV=Border;};

float3 GetRGB(Texture2D tex, float3 position, float4x4 tVP)
{
	float4 pos = mul(float4 (position,1), tVP);
	float2 uv = pos.xy/pos.w;
	uv.x = (uv.x * 0.5 + 0.5);
	uv.y = (uv.y * -0.5 + 0.5);
	return tex.SampleLevel (s0, uv, 0).rgb * float3(1,-1,1);
}

// =====================================================

float4x4 tVP;
Texture2D tex;

[numthreads(64, 1, 1)]
void CSVel( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;
	Buffer_velMass[particleIndex].xyz += GetRGB(tex, Buffer_posLifeT[particleIndex].xyz, tVP) * Mult;
}

[numthreads(64, 1, 1)]
void CSForce( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;
	Buffer_force[particleIndex].xyz += GetRGB(tex, Buffer_posLifeT[particleIndex].xyz, tVP) * Mult;
}

technique11 AddToVel { pass P0{SetComputeShader( CompileShader( cs_5_0, CSVel() ) );} }
technique11 AddToForce { pass P0{SetComputeShader( CompileShader( cs_5_0, CSForce() ) );} }
