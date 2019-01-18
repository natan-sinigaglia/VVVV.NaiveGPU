//@author: dottore

#include "../../../../dx11/ParticlesStruct.fxh"
#include "../../../../dx11/ParticlesSharedSettings.fxh"

AppendStructuredBuffer<pStruct> Output : BACKBUFFER;

Texture2D texture2d <string uiname="PointCloud Texture";>;
float2 texRes;
 

float4x4 tW : WORLD ;

int elemCount : ELEMENTCOUNT;

float InitialLifeT;
float Mass = 1;
float3 EmissionVel;
float ColMass_Mult;


float4 BitsToColor(float f)
{
	uint u=asuint( f );
	float4 c=((u>>8)%256)/255.;
	c=float4(
	(u>>0)%256,
	(u>>8)%256,
	(u>>16)%256,
	(u>>24)%256
	)/255.;
	return c;
}

//==============================================================================
// CS ==========================================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	//if(DTid.x >= (uint)elemCount) return;
	uint pIndex = DTid.x + (DTid.y*texRes.x);	
	if(pIndex >= (uint)elemCount) return;
	
	pStruct Out = (pStruct)0;

	float4 txData = texture2d.Load(DTid);
	float3 PosW = mul(float4(txData.xyz, 1), tW).xyz;
	
	//COLOR
	float3 Col = BitsToColor(txData.w).rgb;
	Out.colSize = float4(Col, 1);

	Out.posLifeT = float4(PosW, InitialLifeT);
	Out.velMass = float4( EmissionVel, Mass + length(Col)*ColMass_Mult);
	Out.force = 0;
	
	
	Output.Append(Out);	
}	

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 Emit
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}
