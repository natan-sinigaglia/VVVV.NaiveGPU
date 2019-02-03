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

float velColMult = 1;

float4 InOutTime = float4(0, 0.3, 10, 20);

float4 col <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };


float radius = 0.05f;
 
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
		float4 velMass = Buffer_velMass[pIndex];
		
	    Out.PosWVP = posLifeT;
		
		float mass = velMass.w;
		float4 colSize = Buffer_colSize[pIndex];
		float3 col = lerp(1, colSize.xyz, saturate(mass*0.5));
		Out.Vcol = float4(col, lerp(0.3,1,saturate(mass * 0.5)) * lerp(0.5,1,colSize.w));
		
		Out.Vcol = float4(colSize.xyz, 1);
	}
    return Out;
}

//==============================================================================
// GEOMETRY SHADER =============================================================
//==============================================================================

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
	
	
	
	
	if(In[0].Vcol.w)
	{
		float4 PosWVP = In[0].PosWVP;
		
		float animScale = smoothstep(InOutTime.x, InOutTime.y, PosWVP.w);
		animScale *= smoothstep(InOutTime.w, InOutTime.z, PosWVP.w);
	
		for(int i=0; i<4 && In[0].PosWVP.w >= 0; i++)
	    {
	        float3 position = g_positions[i] * radius * animScale;// * Vcol.w;
	        position = mul( position, (float3x3)tVI ) + PosWVP.xyz;
	    	float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
	        Out.PosWVP = mul( float4(position,1.0), tVP );
	        
	        Out.TexCd = float4(g_texcoords[i], 0,1);	
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


