
// =============================================================================
// VORTEX CYLINDER HEADER ======================================================
// =============================================================================

StructuredBuffer<float4x4> vortexCyl_invTransform;
StructuredBuffer<float4x4> vortexCyl_vecTransform;
StructuredBuffer<float4> vortexCyl_properties; // radiusGamma, Ygamma, y force , vortexForce




float3 vortexCyl(float3 p)
{
	float3 vortexVec = 0;
	
	uint count,dummy;
	vortexCyl_invTransform.GetDimensions(count,dummy);
	
	[allow_uav_condition] 
	for(uint i=0 ; i<count; i++)
	{
		float3 posT = mul(float4(p,1), vortexCyl_invTransform[i]).xyz;

		float factor = length(posT.xz);
		if(factor <= 1)
		{
			// radius gamma:
			factor = pow(saturate(1-factor), vortexCyl_properties[i].x);
			// Y gamma:
			factor *= 1-pow(saturate(abs(posT.y)), vortexCyl_properties[i].y);
			
			//factor = factor*(vortexCyl_properties[i].w-vortexCyl_properties[i].z) + vortexCyl_properties[i].z;
			
			//vortexVec = max(grad, factor);
			posT = mul(posT, (float3x3)vortexCyl_vecTransform[i]);
			vortexVec += saturate(factor) * vortexCyl_properties[i].w * normalize(float3(posT.x,vortexCyl_properties[i].z, posT.z));
		}
	}
	return vortexVec;
}
