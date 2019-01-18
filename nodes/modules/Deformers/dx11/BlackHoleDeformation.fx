
#include "../../../dx11/ParticlesSharedSettings.fxh"
uint groupCount;
uint groupIndexOffset;

StructuredBuffer<float> RndBuffer;// : RNDBUFFER;

//#include "h_Perlin.fxh"
//#include "h_ConeDeformers.fxh"

cbuffer cbPerDraw : register(b0)
{
	float4x4 cone_tVP;
	float4x4 cone_tVPInverse;
};

cbuffer cbRare : register(b1)
{
	float cone_Strength = 0.5;
	float cone_Gamma = 1;
	float4 cone_DistGradIntervals = float4(0,1, 5,6);
	float3 LensDir = float3(0,0,1);
}

// =====================================================

[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{
	uint particleIndex = DTid.x + groupIndexOffset;
	float3 Pos = Buffer_posLifeT[particleIndex].xyz;
	
	float rnd = RndBuffer[particleIndex % 512];
	Pos.y += rnd;
	
	float4 conePos = mul(float4(Pos, 1), cone_tVP);
	//conePos.y += rnd;
	conePos.xyz /= conePos.w;
	
	float3 vec = 0;
	float axisDist = 1;
	float axisDistFactor = 1;
	float nearFarCoef = 1;
	
	//float3 normPos = normalize(Pos);
	//float dotCoef = saturate(dot(normPos, LensDir));
	
//	vec = 
	
//	Buffer_colSize[particleIndex].xyz = dotCoef;//lerp(Col,  Col*3, colFactor);

	
	
	//if(abs(conePos.x)<1 && abs(conePos.y)<1 && conePos.z>0 && conePos.z<1 && conePos.w>0)
	{
	
		
		nearFarCoef = smoothstep(cone_DistGradIntervals.x, cone_DistGradIntervals.y, conePos.z);
		nearFarCoef *= smoothstep(cone_DistGradIntervals.w, cone_DistGradIntervals.z, conePos.z);

		axisDist = length(conePos.xy);
		axisDistFactor = (1 - saturate(axisDist));
		axisDistFactor = pow(axisDistFactor, cone_Gamma);
		
		float2 deformVec = normalize(conePos.xy) * axisDistFactor * conePos.w * nearFarCoef * cone_Strength;// + float2(0,1);
		vec.xy += deformVec * saturate(conePos.z);
		
		vec = mul(float4(vec,0), cone_tVPInverse).xyz;
		
		 
		
		// COL
		float Col = Buffer_colSize[particleIndex].xyz;
		float colFactor = axisDistFactor * nearFarCoef;
		Buffer_colSize[particleIndex] *= 1 + colFactor*abs(rnd);//lerp(Col,  Col*3, colFactor);

	}

	
	// POS
	Buffer_posLifeT[particleIndex].xyz += vec;
	
}

technique11 Main { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }
