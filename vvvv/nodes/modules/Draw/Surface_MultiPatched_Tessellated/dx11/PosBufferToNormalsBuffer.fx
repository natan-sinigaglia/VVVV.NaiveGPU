
StructuredBuffer<float4> Pos;

RWStructuredBuffer<float4> NormalsBuffer : BACKBUFFER;

int2 clothRes = int2(8,8);
uint IndexOffset;

uint GridCoordToBufferIndex(uint2 coord)
{
	return coord.x + coord.y*clothRes.y;
}
// =============================================================================
// =============================================================================
// =============================================================================

[numthreads(64, 1, 1)]
void Normals_CS( uint3 DTid : SV_DispatchThreadID )
{
	uint count,dummy;
	Pos.GetDimensions(count,dummy);

	if(DTid.x>count) return;
	
	uint Index = DTid.x + IndexOffset;
	float3 pos = Pos[Index].xyz;
	
	int2 gridIndex = uint2(DTid.x%clothRes.x , floor(DTid.x/clothRes.x));
	
	int2 gridIndex_N = gridIndex + int2(0, -1);
	int2 gridIndex_S = gridIndex + int2(0, 1);
	int2 gridIndex_E = gridIndex + int2(1, 0);
	int2 gridIndex_W = gridIndex + int2(-1, 0);

	gridIndex_N = clamp(gridIndex_N , 0 , clothRes-1);
	gridIndex_S = clamp(gridIndex_S , 0 , clothRes-1);
	gridIndex_E = clamp(gridIndex_E , 0 , clothRes-1);
	gridIndex_W = clamp(gridIndex_W , 0 , clothRes-1);

	float3 pos_N = Pos[GridCoordToBufferIndex(gridIndex_N) + IndexOffset].xyz;
	float3 pos_S = Pos[GridCoordToBufferIndex(gridIndex_S) + IndexOffset].xyz;
	float3 pos_E = Pos[GridCoordToBufferIndex(gridIndex_E) + IndexOffset].xyz;
	float3 pos_W = Pos[GridCoordToBufferIndex(gridIndex_W) + IndexOffset].xyz;
	
	float3 tang = pos_W - pos_E;
	float3 binorm = pos_S - pos_N;
	float3 norm = normalize(cross(binorm, tang ));
		
	NormalsBuffer[DTid.x].xyz = norm;
}

//==============================================================================
// TECHNIQUES ==================================================================
//==============================================================================


technique11 Normals
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, Normals_CS() ) );
	}
}

