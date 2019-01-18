
float4x4 tWV: WORLDVIEW ;
float4x4 tV : VIEW ;
float4x4 tP : PROJECTION ;
float4x4 tVP : VIEWPROJECTION ;
float4x4 tWVP : WORLDVIEWPROJECTION ;
float4x4 tVI : VIEWINVERSE ;
float4x4 tWIT: WORLDINVERSETRANSPOSE ;

int selected_pGroup_Offset;

#include "../../../../ParticlesSystem/dx11/particle_struct.fxh"
StructuredBuffer<particle> p_Buffer : PARTICLES_Buffer;

float depthRadiusMult = 1;
 
//==============================================================================
// FUNCTIONS ===================================================================
//==============================================================================

float Culling(float3 pos)
{
	float4 projected = mul(float4(pos, 1), tVP);
	projected.xyz /= projected.w;
	float result = 0;
	
	if(	all(projected.xy > -1.05) && 
		all(projected.xy < 1.05) && 
		projected.z > 0 && 
		projected.z < 1)
	{	result = 1;	}
	return result;
}

//==============================================================================
// VERTEX SHADER ===============================================================
//==============================================================================

struct VS_IN
{
	uint iv : SV_VertexID;
};

struct VS_OUT
{
    float3 posW: POSITION ;	
	float3 normW : NORMAL ;
	float3 col : COLOR ;
	float3 info : TEXCOORD1 ;
	float size : TEXCOORD2 ;
};

VS_OUT VS(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;
	
	uint id = In.iv + selected_pGroup_Offset;
	
    Out.posW = p_Buffer[id].pos;
	Out.normW = p_Buffer[id].rot;
	Out.col = p_Buffer[id].col;
	Out.info = p_Buffer[id].info;
	Out.size = p_Buffer[id].size;
	
    return Out;
}

//==============================================================================

struct VS_Depth_OUT
{
    float3 posW: POSITION ;	
	float size : TEXCOORD2 ;
};

VS_Depth_OUT VS_Depth(VS_IN In)
{
    VS_Depth_OUT Out = (VS_Depth_OUT)0;
		
	uint id = In.iv + selected_pGroup_Offset;

	Out.posW = p_Buffer[id].pos;
	Out.size = p_Buffer[id].size;
	
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
    float4 posWVP: SV_POSITION ;	
	float3 normWV : NORMAL ;
	float3 col : COLOR ;
	float3 info : TEXCOORD0 ;
	float2 texCd : TEXCOORD1 ;
};

[maxvertexcount(4)]
void GS(point VS_OUT In[1], inout TriangleStream<GS_OUT> SpriteStream)
{
    GS_OUT Out;
    
	bool enable = Culling(In[0].posW);
	if(Culling(In[0].posW))
	{		
		Out.info = In[0].info;
	    Out.col = In[0].col;
	    Out.normWV = mul(In[0].normW,(float3x3)tV);

		for(int i=0; i<4; i++)
		{
			float3 position = g_positions[i] * In[0].size;// * sizePerspCorrection;
		    position = mul(position, (float3x3)tVI ) + In[0].posW.xyz;
		    Out.posWVP = mul(float4(position,1.0), tVP);
		    Out.texCd = g_texcoords[i];	
			
		    SpriteStream.Append(Out);
		}
		SpriteStream.RestartStrip();
		
	}
}

//==============================================================================

struct GS_Depth_OUT
{
    float4 posWVP: SV_POSITION ;	
};

[maxvertexcount(4)]
void GS_Depth(point VS_Depth_OUT In[1], inout TriangleStream<GS_Depth_OUT> SpriteStream)
{
    GS_Depth_OUT Out;
    
	bool enable = Culling(In[0].posW);
	if(Culling(In[0].posW))
	{		
		for(int i=0; i<4; i++)
		{
			float3 position = g_positions[i] * In[0].size * depthRadiusMult;// * sizePerspCorrection;
		    position = mul(position, (float3x3)tVI ) + In[0].posW.xyz;
		    Out.posWVP = mul(float4(position,1.0), tVP);
			
		    SpriteStream.Append(Out);
		}
		SpriteStream.RestartStrip();
		
	}
}

//==============================================================================
// PIXEL SHADER ================================================================
//==============================================================================

float4 PS_circle_flat(GS_OUT In): SV_Target
{
	clip(1-length(In.texCd-.5)-0.5f);

	return float4(In.col,1);
}

float4 PS_circle_normals(GS_OUT In): SV_Target
{
	clip(1-length(In.texCd-.5)-0.5f);

	return float4(In.normWV*0.5+0.5,1);//In.Vcol;
}

float4 PS_circle_uv(GS_OUT In): SV_Target
{
	clip(1-length(In.texCd-.5)-0.5f);

	return float4(In.col,1);
}

//==============================================================================
// TECHIQUES ===================================================================
//==============================================================================

technique11 _main
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_circle_flat() ) );
	}
}

technique11 _Normals
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_circle_normals() ) );
	}
}

technique11 _UV
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_circle_uv() ) );
	}
}

technique11 _Depth
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS_Depth() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS_Depth() ) );
		//SetPixelShader( CompileShader( ps_5_0, PS_circle_uv() ) );
	}
}

