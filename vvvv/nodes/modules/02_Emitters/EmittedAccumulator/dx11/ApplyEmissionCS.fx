#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Size
*/

#include "../../../../dx11/ParticlesStruct.fxh"
StructuredBuffer<pStruct> EmittedPdata;
StructuredBuffer<uint> Counter; 

//=========================

[numthreads(1, 1, 1)]
void CS(uint3 DTid : SV_DispatchThreadID)
{
	uint prevPointer = Counter[!Counter[2]];
	uint currentPointer = Counter[Counter[2]];
	//if(DTid.x >= currentPointer-prevPointer) return;
	
	uint index = (DTid.x + prevPointer) % GroupCount + GroupIndexOffset;
	if(index >= (uint)ElementCount) return;
	
	pStruct p = EmittedPdata[DTid.x];

	Buffer1[index] = p.Buffer1;	Buffer2[index] = p.Buffer2;	Buffer3[index] = p.Buffer3;	Buffer4[index] = p.Buffer4;
}

//=========================

technique11 csmain { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }