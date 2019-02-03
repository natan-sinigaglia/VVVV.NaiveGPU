RWStructuredBuffer<float4> PosLocked : POS_LOCKED;
//RWStructuredBuffer<float4> PrevPosInvWeight : PREVPOS_INVWEIGHT;
RWStructuredBuffer<float4> ForceTension : FORCE_TENSION;
//RWStructuredBuffer<float4> Info : INFO;

Texture2D ForceTex <string uiname="Force Texture";>;

float ForceAmount = 100;
bool EnableMaxForce;
float MaxForce = 1;

uint2 GetTexIndex(uint index, uint TexResX)
{ return uint2(index % TexResX, index / TexResX); }

// =============================================================================
// =============================================================================
// =============================================================================

[numthreads(64, 1, 1)]
void ApplyForceCS( uint3 DTid : SV_DispatchThreadID )
{	
	uint resX, resY;
	ForceTex.GetDimensions(resX, resY);
	uint2 TexIndex = GetTexIndex(DTid.x, resX);
	float4 texData = ForceTex.Load(uint3(TexIndex,0));
		
	if(PosLocked[DTid.x].w<1.0 && texData.w>0.)
	{	
		float3 force = texData.xyz;
		
		float vecLength = length(force);
		if(EnableMaxForce && vecLength>0)
		{
			float fStrength = vecLength * texData.w * ForceAmount;
			force = normalize(force) * min(fStrength, MaxForce);
		}
		else force *= texData.w * ForceAmount;
		
		ForceTension[DTid.x].xyz += force;
	}
}

//==============================================================================
// TECHNIQUES ==================================================================
//==============================================================================


technique11 ApplyForce
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, ApplyForceCS() ) );
	}
}

