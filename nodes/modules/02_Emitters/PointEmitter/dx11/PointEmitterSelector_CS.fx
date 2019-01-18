#include "../../../../dx11/ParticlesStruct.fxh"
#include "../../../../dx11/Common.fxh"
/*
	Buffer1 = Pos, LifeTime
	Buffer2 = Vel, Mass
	Buffer3 = Force
	Buffer4 = Col, Size
*/
StructuredBuffer<float4> Emitter_Buffer1;
StructuredBuffer<float4> Emitter_Buffer2;
StructuredBuffer<float4> Emitter_Buffer3;
StructuredBuffer<float4> Emitter_Buffer4;

AppendStructuredBuffer<pStruct> Output : BACKBUFFER;

StructuredBuffer<uint> Emitter_EmissionRateCoef;

cbuffer cbPerDraw : register(b0)
{
	float PosRndAmount = 0;
	float SizeRndAmount = 0;
	float VelRndAmount = 0;
	float MassRndAmount = 0;
	float3 ColRndAmount = 0;
	float EmitterVelInfluence = 0;
	bool SpreadAlongPath;
}

int rndOffset;


// =============================================================================
// CS ==========================================================================
// =============================================================================

[numthreads(1, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	uint count0, count1, count2, count3, count4, dummy;
	Emitter_EmissionRateCoef.GetDimensions(count0,dummy);
	Emitter_Buffer1.GetDimensions(count1,dummy);
	Emitter_Buffer2.GetDimensions(count2,dummy);
	Emitter_Buffer3.GetDimensions(count3,dummy);
	Emitter_Buffer4.GetDimensions(count4,dummy);

	uint Coef = Emitter_EmissionRateCoef[DTid.x%count0];
	if(Coef>0)
	{
		pStruct Out = (pStruct)0;

		Out.Buffer1 = Emitter_Buffer1[DTid.x%count1];
		Out.Buffer2 = Emitter_Buffer2[DTid.x%count2];
		Out.Buffer3 = Emitter_Buffer3[DTid.x%count3];
		Out.Buffer4 = Emitter_Buffer4[DTid.x%count4];		
		/*
			Buffer1 = Pos, LifeTime
			Buffer2 = Vel, Mass
			Buffer3 = Force
			Buffer4 = Col, Size
		*/
		
		float3 EmitterVel = Out.Buffer2.xyz;		
		
		Out.Buffer2.xyz *= EmitterVelInfluence;
		Out.Buffer2.xyz += Out.Buffer3.xyz;		
		
		uint rndCount;
		GaussBuffer.GetDimensions(rndCount,dummy);

		for (uint i=0; i<Coef; i++)
		{
			//Out.Buffer1.xyz = emitterPosMass.xyz;
			if(SpreadAlongPath)
			Out.Buffer1.xyz -= (EmitterVel / (float)Coef * (float3)i);	// shift the emission pos along current frame space coverage
			float4 Gauss = GaussBuffer[(DTid.x + i + rndOffset) % 4096];
			
			//Out.Buffer4.w = abs(Gauss.z);
			
			// Randomness:
			// POS
			if(PosRndAmount > 0)
			{
				Out.Buffer1.xyz += Gauss.xyz * PosRndAmount;
			}
			
			// MASS
			if(MassRndAmount > 0)
			{
				float rnd = RndBuffer[(DTid.x + i + rndOffset) % ElementCount].x - 0.5;
				Out.Buffer2.w += Out.Buffer2.w * rnd * MassRndAmount;
			}
			
			// VEL
			if(VelRndAmount > 0)
			{
				Out.Buffer2.xyz += Gauss.xzy * VelRndAmount;
			}

			// COL
			if(ColRndAmount.x > 0 || ColRndAmount.y > 0 || ColRndAmount.z > 0)
			{
				Out.Buffer4.xyz += -Gauss.zxy * ColRndAmount;
			}
			
			// SIZE
			if(SizeRndAmount > 0)
			{
				Out.Buffer4.w += -Gauss.w * SizeRndAmount;
			}

			Output.Append(Out);
		}
	}
}

// =============================================================================
// TECHNIQUES ==================================================================
// =============================================================================

technique11 Emit
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}



