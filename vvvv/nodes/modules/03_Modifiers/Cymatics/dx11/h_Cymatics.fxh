
uint DataBufferIndexOffset;
uint CymaticPointsPerGroup;

StructuredBuffer<float4> Data1Buffer <string uiname="PositionXYZ, Gamma";>;
StructuredBuffer<float4> Data2Buffer <string uiname="Radius, Strength, Frequency, Phase";>; 

//StructuredBuffer<float4> ScalarColGradient <string uiname="Scalar Color Gradient";>;
//float2 MinDeltaScalarGradientMap <string uiname="Min Delta Scalar Color Gradient Map";> = float2(0, 1);
/*
float mapScalar(float coord)
{
	return (coord-MinDeltaScalarGradientMap.x)*MinDeltaScalarGradientMap.y ;
}
*/
#define pi 3.14159265358979

/*		
float phaseShift;


		dir = sourcePos[i%count] - pos;
		dist = length(dir);
		value += (sin(dist * sourceProperties[index2].w + phaseShift) 
				* sourceProperties[index2].x) / (4*pi*dist*dist);
*/


// CYMATIC FIELD SCALAR:	

float Cymatics_Scalar(float3 pos)
{
	float finalScalar = 0;
	
	for (uint i = 0; i < CymaticPointsPerGroup; i++)
	{
		uint BufferIndex = i + DataBufferIndexOffset;
		float4 Data1 = Data1Buffer[BufferIndex];
		float4 Data2 = Data2Buffer[BufferIndex];
		
		float3 vec = Data1.xyz - pos;
		float dist = length(vec);	
		
		float strength = dist / Data2.x;
		strength = 1 - strength;
		strength = saturate(strength);
		strength = pow(strength, Data1.w);

		float scalar = sin((dist * Data2.z) + Data2.w * 6.2831853071796);
		scalar *= strength * Data2.y;
				
		//transform attraction vector:
/*		float3 Rot = AirCSVariables.Cymatic_ForceRotation + (Rnd-0.5) * AirCSVariables.Attractor_RandomRotationAmount;
		vec = mul(float4(vec,1), rotateVVVV(Rot.x, Rot.y, Rot.z)).xyz;
*/

		finalScalar += scalar;

		
	}
	return finalScalar;
}


// CYMATIC FIELD VECTOR:

float3 Cymatics_Vector(float3 pos)
{
	uint count, dummy;
	Data1Buffer.GetDimensions(count,dummy);

	float3 finalVector = 0 ;
	
	for (uint i = 0; i < count; i++)
	{
		float4 Data1 = Data1Buffer[i];
		float4 Data2 = Data2Buffer[i];
		
		float3 vec = Data1.xyz - pos;
		float dist = length(vec);	
		
		float strength = dist / Data2.x;
		strength = 1 - strength;
		strength = saturate(strength);
		strength = pow(strength, Data1.w);

		float scalar = sin((dist * Data2.z) + Data2.w * 6.2831853071796);
		scalar *= strength * Data2.y;
				
		//transform attraction vector:
/*		float3 Rot = AirCSVariables.Cymatic_ForceRotation + (Rnd-0.5) * AirCSVariables.Attractor_RandomRotationAmount;
		vec = mul(float4(vec,1), rotateVVVV(Rot.x, Rot.y, Rot.z)).xyz;
*/
		
		finalVector += normalize(vec) * scalar;
	}
	return finalVector;
}

// CYMATIC FIELD SCALAR And VECTOR:

float4 Cymatics_VectorScalar(float3 pos)
{
	uint count, dummy;
	Data1Buffer.GetDimensions(count,dummy);

	float finalScalar = 0;
	float3 finalVector = 0 ;
	
	for (uint i = 0; i < count; i++)
	{
		float4 Data1 = Data1Buffer[i];
		float4 Data2 = Data2Buffer[i];
		
		float3 vec = Data1.xyz - pos;
		float dist = length(vec);	
		
		float strength = dist / Data2.x;
		strength = 1 - strength;
		strength = saturate(strength);
		strength = pow(strength, Data1.w);

		float scalar = sin((dist * Data2.z) + Data2.w * 6.2831853071796);
		scalar *= strength * Data2.y;
				
		//transform attraction vector:
/*		float3 Rot = AirCSVariables.Cymatic_ForceRotation + (Rnd-0.5) * AirCSVariables.Attractor_RandomRotationAmount;
		vec = mul(float4(vec,1), rotateVVVV(Rot.x, Rot.y, Rot.z)).xyz;
*/

		finalScalar += scalar;
		finalVector += normalize(vec) * scalar;
	}
	return float4(finalVector, finalScalar);
}
