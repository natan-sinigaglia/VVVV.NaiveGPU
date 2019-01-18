#include "../../../../dx11/ParticlesSharedSettings.fxh"

#include "../../../../dx11/ParticlesStruct.fxh"
StructuredBuffer<pStruct> EmittedPdata;
StructuredBuffer<uint> Counter; 

uint groupCount;
uint groupIndexOffset;

float blackHole_EventHorizonRadius = 0.15;

//=========================

[numthreads(1, 1, 1)]
void CS(uint3 DTid : SV_DispatchThreadID)
{
	uint particleIndex = DTid.x + groupIndexOffset;

	float3 Pos = Buffer_posLifeT[particleIndex].xyz;

	
	
	
	
	
	uint prevPointer = Counter[!Counter[2]];
	uint currentPointer = Counter[Counter[2]];
	//if(DTid.x >= currentPointer-prevPointer) return;
	
	uint index = (DTid.x + prevPointer) % groupCount + groupIndexOffset;
		
	pStruct p = EmittedPdata[DTid.x];

	Buffer_posLifeT[index] = p.posLifeT;	Buffer_velMass[index] = p.velMass;	Buffer_force[index] = p.force;	Buffer_colSize[index] = p.colSize;
}

//=========================

technique11 csmain { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }