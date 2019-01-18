#include "../../../../dx11/ElementBuffers.fxh"
#include "../../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, Mass;
	Buffer2 = PrevPos, Thickness;
	Buffer3 = Force, Drag;
	Buffer4 = Info (UVZ coords, ObjectID);
*/


int IterIndex : ITERATIONINDEX ;

#define EPS 1e-6f

//int ThreadsCount;

cbuffer cbStatic : register(b0)
{
	uint GroupPassesCount = 1;
	uint BufferPassOffset;
	
	float RestLengthMult = 1;
	float RndRestLength = 0;
	float StiffnessMult = 1;
	float UnfoldStiffnessMult = 1;
}


//==============================================================================
// SPRINGS SPECIFIC ============================================================
//==============================================================================
/*
#if !defined(SPRINGS_PASSCOUNT)
#define SPRINGS_PASSCOUNT 4
#endif
*/
//StructuredBuffer<int> CountBuffer;
//StructuredBuffer<int> OffsetBuffer;

StructuredBuffer<float2> PassesBuffer; // float2 (Pairs Count, Pairs Index Offset)

StructuredBuffer<float4> PairsBuffer; 
/*
X = Index A
Y = Index B
z = Rest Length
w = Type (Int part) , Stiffness (Frac Part)
*/

//StructuredBuffer<float4> BodySpringsSettingsBuffer;

// difference scalar
float diffScalar(float dist, float restLength)
{
	return (restLength - dist) / dist;
}

// =============================================================================
// CS ==========================================================================
// =============================================================================

[numthreads(64, 1, 1)]
void SpringsCS( uint3 DTid : SV_DispatchThreadID )
{
	uint PassIndex = (uint)IterIndex % GroupPassesCount;
	uint BufferPassIndex = PassIndex + BufferPassOffset;
	
	uint2 PairsInfoBuffer = PassesBuffer[BufferPassIndex]; // float2 (Pairs Count, Pairs Index Offset)

	// if spring index bigger then springPairs in current pass > return
	if(DTid.x >= PairsInfoBuffer.x) return;

	uint PairIndex = DTid.x + PairsInfoBuffer.y;
	float4 Pair = PairsBuffer[PairIndex];
	
/*	
	if(DTid.x >= (uint)ThreadsCount) return;
	// springs count provided by element spring topology data:
	uint PassSpringsCount = CountBuffer[(uint)IterIndex % SPRINGS_PASSCOUNT];	
	// evaluate just the exact number of springs per pass:
	if(DTid.x >= PassSpringsCount) return;
	// spring index in topology:
	uint springID = DTid.x % PassSpringsCount;
	// get pairs pass offset
	uint passOffset = OffsetBuffer[(uint)IterIndex % SPRINGS_PASSCOUNT];
	// get pair ID
	uint pairID = passOffset + springID;
	// retrieve pair info
	// float4 (pointA index, pointB index, distance, tag)
	float4 Pair = PairsBuffer[pairID];
*/	
	float RestLength = Pair.z;
	float Stiffness = frac(Pair.w);
	bool IsUnfoldType = floor(Pair.w)>0;
	
	
	// modified points indices:
	uint pointAIndex = Pair.x;
	uint pointBIndex = Pair.y;
	
	float4 PosMass_A = Buffer1[pointAIndex];
	float LocalIndex_A = Buffer4[pointAIndex].w;
	float4 PosMass_B = Buffer1[pointBIndex];
	
	// body index:
	uint bodyID = Buffer4[pointAIndex].w;

	float3 posA = PosMass_A.xyz;
	float3 posB = PosMass_B.xyz;
	float A_Mass = abs(PosMass_A.w);  
	float B_Mass = abs(PosMass_B.w);
	bool isLockedA = PosMass_A.w < 0;
	bool isLockedB = PosMass_B.w < 0;

	float massSum = A_Mass + B_Mass;

	RestLength *= 1 + RndBuffer[bodyID].w * RndRestLength;

	// get springs settings per element
	//uint settingsCount,dummy;
	//BodySpringsSettingsBuffer.GetDimensions(settingsCount,dummy);

	//float4 BodySpringsSettings = BodySpringsSettingsBuffer[bodyID%settingsCount];
	//float RestLengthMult = BodySpringsSettings.x;
	//float StrengthMult = BodySpringsSettings.z;
	//float UnfoldStrengthMult = BodySpringsSettings.w;
	
	// evaluate spring vector:
	float3 delta = posA - posB;
	float dist = length(delta) + EPS;
	//float diff = diffScalar( dist, Pair.z * restL);	
	float diff = diffScalar( dist, RestLength * RestLengthMult);	
	//float3 vec = delta * diff * strength;	
	float3 vec = delta * diff * Stiffness * StiffnessMult;	
	
	// Mult unfolding springs strength
	if(IsUnfoldType) 
	vec *= UnfoldStiffnessMult;
	// move pair points using evaluated spring vector:
	if(!isLockedA)
	{
		float factorA = isLockedB ? 1 : (B_Mass/massSum);
		Buffer1[pointAIndex].xyz += vec * factorA;
	}
	if(!isLockedB)
	{
		float factorB = isLockedA ? 1 : (A_Mass/massSum);
		Buffer1[pointBIndex].xyz -= vec * factorB;
	}
}

//==============================================================================
// TECHNIQUES ==================================================================
//==============================================================================


technique11 Springs
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, SpringsCS() ) );
	}
}
