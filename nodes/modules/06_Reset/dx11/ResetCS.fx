
#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"

float3 ResetPos;

//==============================================================================
//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================
//==============================================================================

//==============================================================================
// EULER INTEGRATION ===========================================================
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Thickness
*/

[numthreads(64, 1, 1)]
void EulerCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float4 InitState1 = InitStateBuffer1[Index];
	float4 InitState2 = InitStateBuffer2[Index];
	/*
		float4 (Pos XYZ, Mass)
		float4 (Drag, Thickness, Body ID, Local Index)
		float4 (Coord XYZ, Tag)
	*/
	
	Buffer1[Index] = float4(InitState1.xyz + ResetPos, 0);
	Buffer2[Index] = float4(0,0,0, InitState1.w);
	Buffer3[Index] = float4(0,0,0, 0);
	Buffer4[Index] = float4(1,1,1,InitState2.y);
}

//==============================================================================
// VERLET INTEGRATION ==========================================================
/*
	Buffer1 = Pos, Mass;
	Buffer2 = PrevPos, Thickness;
	Buffer3 = Force, Drag;
	Buffer4 = Info (UVZ coords, ObjectID);
*/

[numthreads(64, 1, 1)]
void VerletCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float4 InitState1 = InitStateBuffer1[Index]; // float4 (Pos XYZ, Mass)
	float4 InitState2 = InitStateBuffer2[Index]; // float4 (Drag, Thickness, Body ID, Local Index)
	float4 InitState3 = InitStateBuffer3[Index]; // float4 (Coord XYZ, Tag)

	InitState1.xyz += ResetPos;
	
	Buffer1[Index] = InitState1;
	Buffer2[Index] = float4(InitState1.xyz, InitState2.y);
	Buffer3[Index] = float4(0,0,0, InitState2.x);
	Buffer4[Index] = float4(InitState3.xyz, InitState2.z);
}

//==============================================================================
//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================
//==============================================================================

technique11 Euler
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, EulerCS() ) );
	}
}

technique11 Verlet
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, VerletCS() ) );
	}
}
