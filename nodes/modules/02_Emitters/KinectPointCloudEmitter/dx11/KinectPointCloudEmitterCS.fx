#include "../../../../dx11/ParticlesStruct.fxh"
#include "../../../../dx11/ParticlesSharedSettings.fxh"

AppendStructuredBuffer<pStruct> Output : BACKBUFFER;

//Texture2D texRGB <string uiname="RGB";>;
//Texture2D texIR <string uiname="IR";>;
//Texture2D texRGBDepth <string uiname="RGBDepth";>;
Texture2D texWorld <string uiname="World";>;
Texture1D texPalette <string uiname="Color Palette";>;
SamplerState LinearClampSampler
{
	Filter  = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

//Texture2D texPlayer <string uiname="Player Texture";>;

float2 rndUVOffset;

float ColorPaletteSamplerCoordMult = 1;

// =====================================================
//                  TEXTURE FUNCTIONS
Texture3D VolumeTexture3D;
SamplerState volumeSampler
{
	Filter  = MIN_MAG_MIP_LINEAR;
	AddressU = Border;
	AddressV = Border;
	AddressW = Border;
};
float4x4 Vol_tInv;

cbuffer cbuf
{
	float4x4 tW : WORLD;
	bool useRawData;
	float2 Resolution;
	float3 scale <String uiname="Default Scale";> = { 1.0f,1.0f,1.0f };
	int rndOffset;
	float3 emissionDir;
	float velThreshold = 0.1;
	float emissionVelMult = 1;
	float Mass = 1;
	float RndMass;
	float VelRndAmount = 0;
	float ColMult = 1;
}

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

[numthreads(64, 1, 1)]
void CS_Emit(csin input)
{
	//if(input.DTID.x >= EmitterSize) return;
	
	float2 rndUV = rndBuffer[(input.DTID.x + rndOffset) % pCount].xy;
	
	// get XY pixel id 
	//uint2 texId = uint2(input.DTID.x, input.DTID.y); // for 4,4,1 threads
	uint2 texId = int2(input.DTID.x % Resolution.x ,input.DTID.x / Resolution.x);
	
	//uint w,h, dummy;
	//texWorld.GetDimensions(0,w,h,dummy);
	
	// calculate sampling coordinates
	float2 texUv = rndUV;//texId * float2(w / Resolution.x , h / Resolution.y) / float2(w,h);
	float halfPixel = (1.0f / Resolution.x) * 0.5f;
	texUv += halfPixel;

	//uint2 pixelID = int2(input.DTID.x % Resolution.x ,input.DTID.x / Resolution.x);
	
	// get texture coordinate for sampling the rgb texture
/*	float2 texUvColor = texRGBDepth.SampleLevel(sPoint,texUv,0).rg;
	if(useRawData){
		texUvColor.x /= 1920.0f;
		texUvColor.y /= 1080.0f;
	}
*/	
	float3 GaussRnd = rndBuffer[input.DTID.x].y;
	float mass = 0;//texMass.SampleLevel(sPoint,texUv,0).r;
	mass = GaussRnd.y * RndMass + Mass;
	float3 position = texWorld.SampleLevel(sPoint,texUv,0).xyz  +  float3(rndUVOffset,0);
	//float mass = texMass.Load(uint3(pixelID, 0)).r;
	//float3 position = texWorld.Load(uint3(pixelID, 0)).xyz  +  float3(rndUVOffset,0);
	
	float3 posW = mul(float4(position,1),tW).xyz;
		
	float4 volPos = mul(float4(posW,1), Vol_tInv);
	float3 velO =  VolumeTexture3D.SampleLevel(volumeSampler,(volPos.xyz + 0.5 ),0).xyz ;
	float3 vel = velO * emissionVelMult * (GaussRnd * VelRndAmount + 1);
	//float emissionMaskValue = texEmissionMask.SampleLevel(sPoint,texUv,0).x;
	
	float initialVelOlength = length(velO);
	// set particle if depth-value and texUvColor coords are valid
	if ( 
			position.z > 0.01 
			&& texUv.x >= 0  
			&& texUv.x < 1  
			&& texUv.y >= 0  
			&& texUv.y < 1
			&& initialVelOlength > velThreshold
		)
	{
		// INIT NEW PARTICLE
		pStruct Out = (pStruct) 0;
		
		// SET POSITION
		Out.posLifeT.xyz = posW;
		
		// SET COLOR
		float3 col = 1;
		// Col from Vel:
		float3 PaletteCol = texPalette.SampleLevel(LinearClampSampler, initialVelOlength * ColorPaletteSamplerCoordMult, 0).rgb ;
		col = PaletteCol;//length(velO) * (vel+0.5) * ColMult;

		//float3 PlayerCol = texPlayer.SampleLevel(sPoint,texUv,0).xyz;
		//col *= PlayerCol;
		//float3 IRCol = texIR.SampleLevel(sPoint,texUv,0).x;
		//col *= IRCol;
		
		//Out.colSize = float4(texRGB.SampleLevel(sPoint,texUvColor,0).xyz, 1);
		

		Out.colSize = float4(col, 1);
				
		//Out.velMass = float4(vel*5, mass);
		Out.velMass = float4(emissionDir + vel, mass);
	
		// ADD PARTICLE TO PARTICLEBUFFER
		Output.Append(Out);
	}
}

technique11 EmitParticles
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Emit() ) );
	}
}