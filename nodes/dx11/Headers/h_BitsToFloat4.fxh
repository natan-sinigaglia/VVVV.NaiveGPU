
float Float4ToBits(float4 c)
{
	uint u=(uint(saturate(c.x)*255)<<0)
	|(uint(saturate(c.y)*255)<<8)
	|(uint(saturate(c.z)*255)<<16)
	|(uint(saturate(c.w)*255)<<24);
	return asfloat( u );
}

float4 BitsToFloat4(float f)
{
	uint u=asuint( f );
	float4 c=((u>>8)%256)/255.;
	c=float4(
	(u>>0)%256,
	(u>>8)%256,
	(u>>16)%256,
	(u>>24)%256
	)/255.;
	return c;
}

