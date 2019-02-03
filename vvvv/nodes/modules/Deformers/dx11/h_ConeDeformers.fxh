
// =============================================================================
// CONE DEFORMER HEADER ========================================================
// =============================================================================

float4x4 cone_tVP;
float4x4 cone_tVPInverse;
float cone_Strength = 0.5;
float cone_Gamma = 1;
float4 cone_DistGradIntervals = float4(0,1, 5,6);

// VECTOR OUTPUT

float3 ConeDeformer(float3 pos, uint coneID)
{
	float4 conePos = mul(float4(pos, 1), cone_tVP);
	conePos.xyz /= conePos.w;
	
	float3 vec = 0;

	//if(abs(conePos.x)<1 && abs(conePos.y)<1 && conePos.z>0 && conePos.z<1 && conePos.w>0)
	if(abs(conePos.x)<1 && abs(conePos.y)<1 && conePos.z<1 && conePos.w>0)
	{	
		float nearFarCoef = smoothstep(cone_DistGradIntervals.x, cone_DistGradIntervals.y, conePos.z);
		nearFarCoef *= smoothstep(cone_DistGradIntervals.w, cone_DistGradIntervals.z, conePos.z);

		float axisDist = length(conePos.xy);
		float axisDistFactor = (1 - saturate(axisDist));
		axisDistFactor = pow(axisDistFactor, cone_Gamma);
		
		vec.xy += normalize(conePos.xy) * axisDistFactor * cone_Strength * conePos.w * nearFarCoef;
		vec = mul(float4(vec,0), cone_tVPInverse).xyz;		
	}
	return vec;
}

// STRUCTURE OUTPUT

struct coneData
{
	float4 conePos;
	float3 vec;
	float axisDistFactor;
	float nearFarCoef;
};

coneData ConeDeformerData(float3 pos, uint coneID)
{
	coneData Out = (coneData)0;
	
	float4 conePos = mul(float4(pos, 1), cone_tVP);
	conePos.xyz /= conePos.w;
	Out.conePos = conePos;
	
	if(abs(conePos.x)<1 && abs(conePos.y)<1 && conePos.z>0 && conePos.z<1 && conePos.w>0)
	{
	
		float3 vec = 0;
		
		float nearFarCoef = smoothstep(cone_DistGradIntervals.x, cone_DistGradIntervals.y, conePos.z);
		nearFarCoef *= smoothstep(cone_DistGradIntervals.w, cone_DistGradIntervals.z, conePos.z);
		Out.nearFarCoef = nearFarCoef;

		float axisDist = length(conePos.xy);
		float axisDistFactor = (1 - saturate(axisDist));
		axisDistFactor = pow(axisDistFactor, cone_Gamma);
		Out.axisDistFactor = axisDistFactor;
		
		conePos.y += RndBuffer
		vec.xy += normalize(conePos.xy) * axisDistFactor * cone_Strength * conePos.w * nearFarCoef;// + float2(0,1);
		
		vec = mul(float4(vec,0), cone_tVPInverse).xyz;
		Out.vec = vec;
		
	//	Out.PosWVP.xyz += vec;
		
	//	float colFactor = axisDistFactor * nearFarCoef;
	//	Out.Vcol.x = lerp(Out.Vcol.x, Out.Vcol.x + conePos.y*2, colFactor);
	}
	return Out;
}