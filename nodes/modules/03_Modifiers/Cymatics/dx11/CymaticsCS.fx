#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

#include "h_Cymatics.fxh"

//==============================================================================
//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================
//==============================================================================

//==============================================================================
// ADD TO FORCE ================================================================

[numthreads(64, 1, 1)]
void ForceCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;
	
	float4 Buffer1Data = Buffer1[Index];
	
	// ADD TO FORCE
	Buffer3[Index].xyz += Cymatics_Vector(Buffer1Data.xyz);
}

//==============================================================================
// ADD TO VEL ==================================================================
// (ONLY EULER)

[numthreads(64, 1, 1)]
void VelCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;
	
	float4 Buffer1Data = Buffer1[Index];
	
	// ADD TO VEL
	Buffer2[Index].xyz += Cymatics_Vector(Buffer1Data.xyz);
}

//==============================================================================
//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================
//==============================================================================

technique11 AddToForce { pass P0{SetComputeShader( CompileShader( cs_5_0, ForceCS() ) );} }
technique11 AddToVel { pass P0{SetComputeShader( CompileShader( cs_5_0, VelCS() ) );} }
