StructuredBuffer<float> floatBuffer;
StructuredBuffer<float2> float2Buffer;
StructuredBuffer<float3> float3Buffer;
StructuredBuffer<float4> float4Buffer;

// Global:
RWTexture2D<float> OutputTextureFloat : BACKBUFFER;
RWTexture2D<float2> OutputTextureFloat2 : BACKBUFFER;
RWTexture2D<float3> OutputTextureFloat3 : BACKBUFFER;
RWTexture2D<float4> OutputTextureFloat4 : BACKBUFFER;

float2 size : TARGETSIZE;
uint IndexOffset;

//==============================================================================

[numthreads(8, 8, 1)]
void CS_float(uint3 DTid : SV_DispatchThreadID)
{	
	if(DTid.x>=(uint)size.x || DTid.y>=(uint)size.y) return;
	uint index = DTid.x + DTid.y*size.x + IndexOffset;
	OutputTextureFloat[DTid.xy] = floatBuffer[index];
}

[numthreads(8, 8, 1)]
void CS_float2(uint3 DTid : SV_DispatchThreadID)
{	
	if(DTid.x>=(uint)size.x || DTid.y>=(uint)size.y) return;
	uint index = DTid.x + DTid.y*size.x + IndexOffset;
	OutputTextureFloat2[DTid.xy] = float2Buffer[index];
}

[numthreads(8, 8, 1)]
void CS_float3(uint3 DTid : SV_DispatchThreadID)
{	
	if(DTid.x>=(uint)size.x || DTid.y>=(uint)size.y) return;
	uint index = DTid.x + DTid.y*size.x + IndexOffset;
	OutputTextureFloat3[DTid.xy] = float3Buffer[index];
}

[numthreads(8, 8, 1)]
void CS_float4(uint3 DTid : SV_DispatchThreadID)
{	
	if(DTid.x>=(uint)size.x || DTid.y>=(uint)size.y) return;
	uint index = DTid.x + DTid.y*size.x + IndexOffset;
	OutputTextureFloat4[DTid.xy] = float4Buffer[index];
}

//==============================================================================

technique11 texture_2D_float
{
	pass P0
	{	SetComputeShader( CompileShader( cs_5_0, CS_float() ) );	}
}

technique11 texture_2D_float2
{
	pass P0
	{	SetComputeShader( CompileShader( cs_5_0, CS_float2() ) );	}
}

technique11 texture_2D_float3
{
	pass P0
	{	SetComputeShader( CompileShader( cs_5_0, CS_float3() ) );	}
}

technique11 texture_2D_float4
{
	pass P0
	{	SetComputeShader( CompileShader( cs_5_0, CS_float4() ) );	}
}
