
float tStep : TIMESTEP;
int ElementCount: ELEMENTCOUNT;

uint GroupCount;
uint GroupIndexOffset;
uint GroupLastIndex;

StructuredBuffer<float4> InitStateBuffer1 : INITSTATE_BUFFER1;
StructuredBuffer<float4> InitStateBuffer2 : INITSTATE_BUFFER2;
StructuredBuffer<float4> InitStateBuffer3 : INITSTATE_BUFFER3;
/*
	float4 (Pos XYZ, Mass)
	float4 (Drag, Thickness, Body ID, Local Index)
	float4 (Coord XYZ, Tag)
*/

StructuredBuffer<float4> RndBuffer : RNDBUFFER;
StructuredBuffer<float4> GaussBuffer : GAUSSBUFFER;



