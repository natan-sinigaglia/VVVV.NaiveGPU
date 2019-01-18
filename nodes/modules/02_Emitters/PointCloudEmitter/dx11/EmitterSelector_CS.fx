//@author: dottore

struct p
{
	float3 Pos;		// float3 pos (default 0,0,0) + float rnd (random value in 0 to 1 space)
	float3 Vel;		// float3 vel (default 0,0,0) + float rnd (random value in 0 to 1 space)
	float3 Col;		// float3 col (default 1,1,1) + float lifeT (default 0)
	float4 Info;	// float heat (default 0) + float dynamic (default 0) + 0 + 0
};
StructuredBuffer<p> EmittedBuffer;
ByteAddressBuffer InputCountBuffer;

StructuredBuffer<uint> RndIndex;

AppendStructuredBuffer<p> Selected : BACKBUFFER;

//==============================================================================
// CS ==========================================================================
//==============================================================================

[numthreads(1, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	uint cnt = InputCountBuffer.Load(0);
	uint index = RndIndex[DTid.x] % cnt;
	p SelectedP = EmittedBuffer[index];
		
	Selected.Append(SelectedP);	
}	

//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 Select
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}
