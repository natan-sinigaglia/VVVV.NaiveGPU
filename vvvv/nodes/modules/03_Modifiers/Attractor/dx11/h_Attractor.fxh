
// =============================================================================
// ATTRACTORS HEADER ===========================================================
// =============================================================================

cbuffer cbStatic : register(b2)
{
	uint AttractorsPerGroup;
	uint DataBufferIndexOffset;
}

StructuredBuffer<float4> Attractor_PosGaussOffset;
StructuredBuffer<float4> Attractor_RadiusStrengthGamma; 
StructuredBuffer<float4> Attractor_VecRotation; 


float4x4 rotateVVVV(float rotX, float rotY, float rotZ)
{
	 float sx = sin(rotX);
	 float cx = cos(rotX);
	 float sy = sin(rotY);
	 float cy = cos(rotY);
	 float sz = sin(rotZ);
	 float cz = cos(rotZ);
	
   return float4x4( cz * cy + sz * sx * sy, sz * cx, cz * -sy + sz * sx * cy , 0,
                   -sz * cy + cz * sx * sy, cz * cx, sz *  sy + cz * sx * cy , 0,
                    cx * sy				  ,-sx     , cx * cy                 , 0,
                    0                     , 0      , 0                       , 1);
}

//Multiple attractors
float3 Attractors(float3 p, float3 Rnd, float3 RndDir)
{
	//uint count, dummy;
	//Attractor_PosGaussOffset.GetDimensions(count,dummy);
	
	float3 vec = 0;
	for(uint i=0 ; i<AttractorsPerGroup; i++)
	{
		uint BufferIndex = i + DataBufferIndexOffset;
		float4 PosGaussOffset = Attractor_PosGaussOffset[BufferIndex];
		float4 RadiusStrengthGamma = Attractor_RadiusStrengthGamma[BufferIndex];
		float4 VecRotation = Attractor_VecRotation[BufferIndex];
		
		float3 TrgPos = PosGaussOffset.xyz + RndDir * PosGaussOffset.w;
		float3 attrVec = TrgPos - p;
		float3 Rot = VecRotation.xyz + (Rnd-0.5) * VecRotation.w;
		Rot *= 6.283185307179;
		attrVec = mul(float4(attrVec,1), rotateVVVV(Rot.x, Rot.y, Rot.z)).xyz;

		float attrRadius = RadiusStrengthGamma.x;
		float attrStrength = RadiusStrengthGamma.y;

		float attrForce = length(attrVec) / attrRadius;
		attrForce = 1 - attrForce;
		attrForce = saturate(attrForce);
		attrForce = pow(attrForce, RadiusStrengthGamma.z);
		attrVec = attrVec * attrForce * attrStrength;
		vec += attrVec;
	}
	return vec;
}