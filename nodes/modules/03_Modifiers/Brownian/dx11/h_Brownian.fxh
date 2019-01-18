
int Brownian_IndexShift;
float3 Brownian_Strenght;

float3 Brownian(uint index)
{
	//uint count,dummy;
	//GaussBuffer.GetDimensions(count,dummy);
	
	uint RndIndex = index + Brownian_IndexShift;
	RndIndex = RndIndex % 2048;
	return GaussBuffer[RndIndex].xyz * Brownian_Strenght;
}
