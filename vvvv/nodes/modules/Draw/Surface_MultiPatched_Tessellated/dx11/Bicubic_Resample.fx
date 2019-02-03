//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

float4x4 tWVP: WORLDVIEWPROJECTION;

Texture2D ctrlTex;
Texture1D filterTex;

SamplerState samp
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState sampFilter
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = wrap;
    AddressV = wrap;
};

SamplerState sampPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 tTex <string uiname="Texture Transform";>;

//texture size XY
float2 size_source;


// ------------------------------------------------------
// FUNCTION:
// ------------------------------------------------------

float3 filter(float x)
{
  x = frac(x);
  float x2 = x*x;
  float x3 = x2*x;
  float w0 = (  -x3 + 3*x2 - 3*x + 1)/6.0;
  float w1 = ( 3*x3 - 6*x2       + 4)/6.0;
  float w2 = (-3*x3 + 3*x2 + 3*x + 1)/6.0;
  float w3 = x3/6;
  
  float h0 = 1 - w1/(w0+w1) + x;
  float h1 = 1 + w3/(w2+w3) - x;
  
  return float3(h0, h1, w0+w1);
}

bool UseKernelTexture;

	
// ---------------------------------------------------------------

struct VS_IN
{
	float4 PosO : POSITION ;
	float2 TexCd : TEXCOORD0 ;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION ;
    float2 TexCd: TEXCOORD0 ;
};

vs2ps VS(VS_IN input)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //position (projected)
    Out.PosWVP  = mul(input.PosO, tWVP);
    Out.TexCd = mul(input.TexCd, tTex);
    return Out;
}

// ---------------------------------------------------------------

float4 PS_Tex1(vs2ps In): SV_Target
{
//pixel size XY
  float2 pix = 1.0/size_source;

  //calc filter texture coordinates
  float2 w = In.TexCd*size_source-float2(0.5, 0.5);

  // fetch offsets and weights from filter function
  float3 hg_x = UseKernelTexture ? filterTex.Sample(sampFilter, w.x ).xyz : filter(-w.x);
  float3 hg_y = UseKernelTexture ? filterTex.Sample(sampFilter, w.y ).xyz : filter(-w.y);

  float2 e_x = {pix.x, 0};
  float2 e_y = {0, pix.y};

  // determine linear sampling coordinates
  float2 coord_source10 = In.TexCd + hg_x.x * e_x;
  float2 coord_source00 = In.TexCd - hg_x.y * e_x;
  float2 coord_source11 = coord_source10 + hg_y.x * e_y;
  float2 coord_source01 = coord_source00 + hg_y.x * e_y;
  coord_source10 = coord_source10 - hg_y.y * e_y;
  coord_source00 = coord_source00 - hg_y.y * e_y;

  // fetch four linearly interpolated inputs
  float4 tex_source00 = ctrlTex.Sample(samp, coord_source00 );
  float4 tex_source10 = ctrlTex.Sample(samp, coord_source10 );
  float4 tex_source01 = ctrlTex.Sample(samp, coord_source01 );
  float4 tex_source11 = ctrlTex.Sample(samp, coord_source11 );

  // weight along y direction
  tex_source00 = lerp( tex_source00, tex_source01, hg_y.z );
  tex_source10 = lerp( tex_source10, tex_source11, hg_y.z );

  // weight along x direction
  tex_source00 = lerp( tex_source00, tex_source10, hg_x.z );

  return tex_source00;
}

// ---------------------------------------------------------------

float4 PS_Tex2(vs2ps In): SV_Target
{
    return ctrlTex.Sample( samp, In.TexCd);
}

// -------------------------------------------------------------

float4 PS_Tex3(vs2ps In): SV_Target
{
    return ctrlTex.Sample( sampPoint, In.TexCd);
}

// ---------------------------------------------------------------

technique10 Bicubic_Resample
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex1() ) );
	}
}

technique10 Linear_Resample
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex2() ) );
	}
}

technique10 Ctrl_Texture
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex3() ) );
	}
}



