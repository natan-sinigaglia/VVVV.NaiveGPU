#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"

#include "h_Perlin.fxh"

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

	float4 PosLifeT = Buffer1[Index];
	float3 Pos = PosLifeT.xyz;
	
	// PERLIN:
	float3 PerlinForce = 0;
	if(Perlin_Strenght.x>0 || Perlin_Strenght.y>0 || Perlin_Strenght.z>0)
	{
		PerlinForce = float3(	fBm(float4(Pos+float3(51,2.36,-5),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers),
								fBm(float4(Pos+float3(98.2,-9,-36),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers),
								fBm(float4(Pos+float3(0,10.69,6),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers));
		PerlinForce *=  Perlin_Strenght;// * saturate(PosLifeT.w-1);
	}

	// ADD TO FORCE
	Buffer3[Index].xyz += PerlinForce;
}

//==============================================================================
// ADD TO VEL ==================================================================
// (ONLY EULER)

[numthreads(64, 1, 1)]
void VelCS( uint3 DTid : SV_DispatchThreadID )
{
	if(DTid.x >= GroupCount) return;
	uint Index = DTid.x + GroupIndexOffset;

	float3 Pos = Buffer1[Index].xyz;
	
	// PERLIN:
	float3 PerlinForce = 0;
	if(Perlin_Strenght.x>0 || Perlin_Strenght.y>0 || Perlin_Strenght.z>0)
	{
		PerlinForce = float3(	fBm(float4(Pos+float3(51,2.36,-5),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers),
								fBm(float4(Pos+float3(98.2,-9,-36),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers),
								fBm(float4(Pos+float3(0,10.69,6),Perlin_Time), Perlin_Oct, Perlin_Freq, Perlin_Lacun, Perlin_Pers));
		
		PerlinForce *=  Perlin_Strenght;
	}
	
	// ADD TO VEL
	Buffer2[Index].xyz += PerlinForce;
}

//==============================================================================
//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================
//==============================================================================

technique11 AddToForce { pass P0{SetComputeShader( CompileShader( cs_5_0, ForceCS() ) );} }
technique11 AddToVel { pass P0{SetComputeShader( CompileShader( cs_5_0, VelCS() ) );} }
