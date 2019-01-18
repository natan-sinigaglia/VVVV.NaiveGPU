//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D texture2d <string uiname="Texture";>;

SamplerState g_samLinear <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tV : VIEW;
	float4x4 tVI : VIEWINVERSE;
	float4x4 tP : PROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tColor <string uiname="Color Transform";>;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
	float3 posWV : POSITION ;
    float4 TexCd: TEXCOORD0;
};

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
	Out.posWV = mul(input.PosO,mul(tW,tV)).xyz;
    Out.TexCd = mul(input.TexCd, tTex);
    return Out;
}


struct PS_Out
{
 float4 col : SV_Target; 
 float depth : SV_Depth; // try SV_DepthLess for perf
};


PS_Out PS(vs2ps In) //: SV_Target
{
	PS_Out Out = (PS_Out)0;
	
	float dist = length(In.TexCd.xy-.5); //get the distance form the center of the point-sprite
	clip(1-dist-0.5f);

	float4 posWVP = mul(float4(In.posWV,1), tP);
	
	Out.depth = posWVP.z/posWVP.w;
	Out.col = cAmb;
	
    return Out;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================


float sphere_radius = 1;
float3 lightDir;

PS_Out PS2(vs2ps In) //: SV_Target
{
	PS_Out Out = (PS_Out)0;

	// r^2 = (x - x0)^2 + (y - y0)^2 + (z - z0)^2
    float x = In.TexCd.x*2-1;
    float y = In.TexCd.y*2-1;
    float zz = 1.0 - x*x - y*y;

    if (zz <= 0.0)
      discard;

    float z = sqrt(zz);    
    float4 pos = float4(In.posWV, 1);
    pos.z += sphere_radius*z;
    pos = mul(pos, tP);
    Out.depth = 0.5*(pos.z / pos.w)+0.5;
    
    float3 normal = float3(x,y,z);
    float diffuseTerm = clamp(dot(normal, mul(float4(lightDir,0), tVI).xyz), 0.0, 1.0);

    Out.col = float4(float3(0.15,0.15,0.15) +  diffuseTerm * cAmb.xyz, 1.0);
	
    return Out;

}

technique10 Constant2
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS2() ) );
	}
}
