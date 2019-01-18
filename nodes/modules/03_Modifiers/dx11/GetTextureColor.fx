

#include "../../../dx11/ParticlesSharedSettings.fxh"
uint groupCount;
uint groupIndexOffset;

Texture2D texRGB <string uiname="RGB";>;
Texture2D texIR <string uiname="IR";>;
Texture2D texRGBDepth <string uiname="RGBDepth";>;
Texture2D texWorld <string uiname="World";>;

cbuffer cbuf
{
	float4x4 tW : WORLD;
	//float4x4 invCullVol;
	bool useRawData;
	//float2 Resolution;
	//float3 scale <String uiname="Default Scale";> = { 1.0f,1.0f,1.0f };
	//int rndOffset;
	//float3 emissionDir;
	float4x4 kinect_tVP;
	float LerpValue;
}

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};


[numthreads(64, 1, 1)]
void CS( uint3 DTid : SV_DispatchThreadID )
{
	
	
	uint pIndex = DTid.x + groupIndexOffset;
	
	//float2 rndUV = rndBuffer[(DTid.x + rndOffset) % groupCount + groupIndexOffset].xy;

	float3 position = Buffer_posLifeT[pIndex].xyz;
	float4 pos = mul(float4 (position,1), kinect_tVP);
	float2 uv = pos.xy/pos.w;
	uv.x = (uv.x * 0.5 + 0.5);
	uv.y = (uv.y * -0.5 + 0.5);

	// get XY pixel id 
	//uint2 texId = uint2(pIndex, input.DTID.y); // for 4,4,1 threads
	//uint2 texId = int2(pIndex % Resolution.x ,pIndex / Resolution.x);
	
	uint w,h, dummy;
	texWorld.GetDimensions(0,w,h,dummy);
	
	// calculate sampling coordinates
	float2 texUv = uv;//texId * float2(w / Resolution.x , h / Resolution.y) / float2(w,h);
	//float halfPixel = (1.0f / Resolution.x) * 0.5f;
	//texUv += halfPixel;

	// get texture coordinate for sampling the rgb texture
	float2 texUvColor = texRGBDepth.SampleLevel(sPoint,texUv,0).rg;
	if(useRawData){
		texUvColor.x /= 1920.0f;
		texUvColor.y /= 1080.0f;
	}

	float3 sampledCol = texRGB.SampleLevel(sPoint,texUvColor,0).xyz;
	//float3 sampledCol = texIR.SampleLevel(sPoint,texUv,0).xxx;
	Buffer_colSize[pIndex].xyz = lerp(Buffer_colSize[pIndex].xyz, sampledCol, LerpValue);
	
}

technique11 GetColFromKinect
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}