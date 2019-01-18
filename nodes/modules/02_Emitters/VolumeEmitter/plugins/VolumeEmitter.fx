#include "../../../../dx11/ParticlesStruct.fxh"
#include "../../../../dx11/ParticlesSharedSettings.fxh"

AppendStructuredBuffer<pStruct> Output : BACKBUFFER;

StructuredBuffer<float3> SamplerPosition; 

StructuredBuffer<uint> Emitter_EmissionRateCoef; // default 0
StructuredBuffer<float4> Emitter_PosMass; //default float3(0,0,0) 
StructuredBuffer<float3> Emitter_Vel; //default float3(0,0,0)
StructuredBuffer<float3> Emitter_Dir; //default float3(0,0,0)
StructuredBuffer<float3> Emitter_Col; //default float3(1,1,1)

cbuffer cbPerDraw : register(b0)
{
	float PosRndAmount = 0;
	float VelRndAmount = 0;
	float MassRndAmount = 0;
	float3 ColRndAmount = 0;
	float EmitterVelInfluence = 0;
	float initialLifeT;
	bool spreadAlongPath;
}

int rndOffset;


// =============================================================================
// CS ==========================================================================
// =============================================================================

[numthreads(1, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{	
	uint Coef = Emitter_EmissionRateCoef[DTid.x];
	if(Coef>0)
	{
		pStruct Out = (pStruct)0;

		float4 emitterPosMass = Emitter_PosMass[DTid.x];	
		float3 emitterVel = Emitter_Vel[DTid.x];
		float3 emitterDir = Emitter_Dir[DTid.x];

		Out.posLifeT.xyz = emitterPosMass.xyz;
		Out.posLifeT.w = initialLifeT;
		Out.force = 0;
		Out.colSize = float4(Emitter_Col[DTid.x], 1);
		
		
		Out.velMass.xyz = emitterDir;
		Out.velMass.xyz += emitterVel * EmitterVelInfluence;
		Out.velMass.w = emitterPosMass.w;
		
		uint rndCount,dummy;
		gaussDirBuffer.GetDimensions(rndCount,dummy);

		for (uint i=0; i<Coef; i++)
		{
			Out.posLifeT.xyz = emitterPosMass.xyz;
			if(spreadAlongPath)
			Out.posLifeT.xyz -= (emitterVel / (float)Coef * (float3)i);	// shift the emission pos along current frame space coverage
			float3 rndDir = gaussDirBuffer[(DTid.x + i + rndOffset) % rndCount].xyz;
			
			Out.colSize.w = abs(rndDir.z);
			
			// Randomness:
			// POS
			if(PosRndAmount > 0)
			{
				Out.posLifeT.xyz += rndDir * PosRndAmount;
			}
			
			// MASS
			if(MassRndAmount > 0)
			{
				float rnd = rndBuffer[(DTid.x + i + rndOffset) % pCount].x - 0.5;
				Out.velMass.w += Out.velMass.w * rnd * MassRndAmount;
			}
			
			// VEL
			if(VelRndAmount > 0)
			{
				Out.velMass.xyz += rndDir.xzy * VelRndAmount;
			}

			// COL
			if(ColRndAmount.x > 0 || ColRndAmount.y > 0 || ColRndAmount.z > 0)
			{
				Out.colSize.xyz += -rndDir.zxy * ColRndAmount;
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



