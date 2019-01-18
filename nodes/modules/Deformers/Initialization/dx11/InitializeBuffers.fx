#include "../../../../dx11/ElementBuffers.fxh"

StructuredBuffer<float4> In_Buffer1 ;
StructuredBuffer<float4> In_Buffer2 ;
StructuredBuffer<float4> In_Buffer3 ;
StructuredBuffer<float4> In_Buffer4 ;


//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	Buffer1[DTid.x] = In_Buffer1[DTid.x];
	Buffer2[DTid.x] = In_Buffer2[DTid.x];
	Buffer3[DTid.x] = In_Buffer3[DTid.x];
	Buffer4[DTid.x] = In_Buffer4[DTid.x];
}

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 main
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}

