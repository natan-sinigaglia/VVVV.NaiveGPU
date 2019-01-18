
#include "../../../dx11/ElementBuffers.fxh"
#include "../../../dx11/Common.fxh"

// EULER INTEGRATION ===========================================================
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Size
*/

// VERLET INTEGRATION ==========================================================
/*
	Buffer1 = Pos, Mass;
	Buffer2 = PrevPos, Thickness;
	Buffer3 = Force, Drag;
	Buffer4 = Info (UVZ coords, ObjectID);
*/

//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(64, 1, 1)]
void EulerCS( uint3 DTid : SV_DispatchThreadID )
{	
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	Buffer3[Index].xyz = 0;
}

[numthreads(64, 1, 1)]
void VerletCS( uint3 DTid : SV_DispatchThreadID )
{	
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	Buffer3[Index].xyz = 0;
	Buffer1[Index].w = abs(Buffer1[Index].w);
}

//==============================================================================
//TECHNIQUES ===================================================================
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
