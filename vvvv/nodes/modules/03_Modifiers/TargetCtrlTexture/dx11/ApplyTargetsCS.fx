#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, Mass;
	Buffer2 = PrevPos, Thickness;
	Buffer3 = Force, Drag;
	Buffer4 = Info (UVZ coords, ObjectID);
*/

Texture2D trgTex <string uiname="Target Texture";>;

float ForceAmount = 100;
bool EnableMaxForce;
float MaxForce = 1;

uint2 GetTexIndex(uint index, uint TexResX)
{ return uint2(index % TexResX, index / TexResX); }

// =============================================================================
// =============================================================================
// =============================================================================

[numthreads(64, 1, 1)]
void TargetCS( uint3 DTid : SV_DispatchThreadID )
{	
	uint resX, resY;
	trgTex.GetDimensions(resX, resY);
	uint2 TexIndex = GetTexIndex(DTid.x, resX);
	float4 texData = trgTex.Load(uint3(TexIndex,0));
	
	float4 PosMass = Buffer1[DTid.x];
	
	if(texData.w>0.)
	{	
		float3 force = texData.xyz - PosMass.xyz;
		
		float vecLength = length(force);
		if(EnableMaxForce && vecLength>0)
		{
			float fStrength = vecLength * texData.w * ForceAmount;
			force = normalize(force) * min(fStrength, MaxForce);
		}
		else force *= texData.w * ForceAmount;
		
		Buffer3[DTid.x].xyz += force;
	}
}

//==============================================================================
// TECHNIQUES ==================================================================
//==============================================================================


technique11 Target
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, TargetCS() ) );
	}
}

