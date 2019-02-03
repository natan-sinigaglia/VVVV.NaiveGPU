//@author: dottore

int ParticlesCount = 128;

ByteAddressBuffer InputCountBuffer;
RWStructuredBuffer<uint> Counter : BACKBUFFER;

//##############################################################################
//##############################################################################
//##############################################################################


[numthreads(1, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	uint EmittedCount = InputCountBuffer.Load(0);
	if(EmittedCount>0)
	{
		Counter[2] = !Counter[2];
		Counter[Counter[2]] = (Counter[!Counter[2]]+InputCountBuffer.Load(0)) % ParticlesCount;
	}
	
}	

[numthreads(1, 1, 1)]
void CS_reset( uint3 DTid : SV_DispatchThreadID )
{	
	Counter[0] = 0;	
	Counter[1] = 0;	
	Counter[2] = 0;	
}	

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 Counter_CS
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}

technique11 Reset_CS
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_reset() ) );
	}
}
