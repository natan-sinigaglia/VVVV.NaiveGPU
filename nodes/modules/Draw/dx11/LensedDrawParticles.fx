//@author: dottore
//@help: standard constant shader
//@tags: color
//@credits: 

//#include "../../../dx11/ParticlesSharedSettings.fxh"
StructuredBuffer<float4> Buffer_posLifeT;
StructuredBuffer<float4> Buffer_velMass;
StructuredBuffer<float4> Buffer_colSize;


uint groupCount;
uint groupIndexOffset;

float4x4 tV : VIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tVI : VIEWINVERSE;

float distWfactor = 1;

float4 col <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };


float SizeMult = 1;
 
// particle quad texture:
Texture2D texture2d;
SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

//==============================================================================
// VERTEX SHADER ===============================================================
//==============================================================================

struct VS_IN
{
	uint iv : SV_VertexID;
};

struct VS_OUT
{
    float4 PosWVP: SV_POSITION ;	
	float4 Vcol : COLOR ;
};

VS_OUT VS(VS_IN In)
{
    //inititalize all fields of output struct with 0
    VS_OUT Out = (VS_OUT)-1;
	
	uint pIndex = In.iv + groupIndexOffset;
	
	float4 posLifeT = Buffer_posLifeT[pIndex];
	
	
	if(posLifeT.w >= 0)
	{
		float4 colSize = Buffer_colSize[pIndex];
		
	    Out.PosWVP = posLifeT;
				
		Out.Vcol = colSize;		
		Out.Vcol.xyz *= col.xyz;
		
	}

    return Out;
}

//==============================================================================
// GEOMETRY SHADER =============================================================
//==============================================================================

float3 g_positions[4]:IMMUTABLE =
{
    float3( -1, 1, 0 ),
    float3( 1, 1, 0 ),
    float3( -1, -1, 0 ),
    float3( 1, -1, 0 ),
};
float2 g_texcoords[4]:IMMUTABLE = 
{ 
    float2(0,1), 
    float2(1,1),
    float2(0,0),
    float2(1,0),
};


struct GS_OUT
{
    float4 PosWVP: SV_POSITION ;	
	float4 TexCd : TEXCOORD0 ;
	float4 Vcol : COLOR ;
};

[maxvertexcount(4)]
void GS(point VS_OUT In[1], inout TriangleStream<GS_OUT> SpriteStream)
{
    GS_OUT Out;
    
	float4 Vcol = In[0].Vcol;
	
	float Size = In[0].Vcol.w;
	
	
	
	if(Size > 0)
	{
		float4 PosWVP = In[0].PosWVP;
		float wFactor = mul( float4(PosWVP.xyz,1.0), tVP ).w;
		
		float uvFactor = min(0.5 * distWfactor / wFactor, 1);
		float SizeWFactor = max(wFactor, distWfactor);
			
		float radiusCoef = Size * SizeMult * SizeWFactor * 0.01;
				
		
		for(int i=0; i<4; i++)
	    {
	        float3 position = g_positions[i] * radiusCoef;// * Vcol.w;
	        position = mul( position, (float3x3)tVI ) + PosWVP.xyz;
	    	//float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
	        Out.PosWVP = mul( float4(position,1.0), tVP );
	        
	    	float2 uv = g_texcoords[i] - 0.5;
	    	uv *= uvFactor;
	    	uv += 0.5;
	        Out.TexCd = float4(uv, 0,1);	
	    	
	        Out.Vcol = float4(Vcol.xyz, 1);
	    	
	        SpriteStream.Append(Out);
	    }
	    SpriteStream.RestartStrip();
	}
}

//==============================================================================
// PIXEL SHADER ================================================================
//==============================================================================

float4 PS_quad(GS_OUT In): SV_Target
{
	return In.Vcol;
}

float4 PS_circle(GS_OUT In): SV_Target
{
	if(length(In.TexCd.xy-.5)>.5){discard;}

	return In.Vcol;
}

float4 PS_texture(GS_OUT In): SV_Target
{
    float4 col = texture2d.Sample( g_samLinear, In.TexCd.xy)*In.Vcol;
	//return In.Vcol;
	return col;
}

//==============================================================================
// TECHIQUES ===================================================================
//==============================================================================

technique11 _quad
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_quad() ) );
	}
}

technique11 _circle
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_circle() ) );
	}
}

technique11 _texture
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_texture() ) );
	}
}


