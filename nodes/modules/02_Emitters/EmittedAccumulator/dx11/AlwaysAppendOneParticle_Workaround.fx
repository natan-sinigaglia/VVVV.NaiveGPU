#include "../../../../dx11/ParticlesStruct.fxh"
#include "../../../../dx11/ParticlesSharedSettings.fxh"

AppendStructuredBuffer<pStruct> Output : BACKBUFFER;

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

[numthreads(1, 1, 1)]
void CS_Emit(csin input)
{
	// INIT NEW PARTICLE
	pStruct Out = (pStruct) -1;
	
	// SET POSITION
	Out.posLifeT.xyz = 9999;
		
	// ADD PARTICLE TO PARTICLEBUFFER
	Output.Append(Out);
			
}

technique11 EmitParticles
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Emit() ) );
	}
}