
float4x4 tWV: WORLDVIEW ;
float4x4 tWVP : WORLDVIEWPROJECTION ;
float4x4 tWIT: WORLDINVERSETRANSPOSE ;

float tStep : GLOBAL_TIMESTEP ;
float4x4 tV : VIEW ;
float4x4 tVI : VIEWINVERSE ;
float4x4 tP : PROJECTION ;
//float4x4 tPI : PROJECTIONINVERSE ;
float4x4 tVP : VIEWPROJECTION ;
float4x4 tV_Prev : CAMERA_VIEW_PREV ;
float4x4 tP_Prev : CAMERA_PROJECTION_PREV ;
float4x4 tVP_Prev : CAMERA_VIEWPROJECTION_PREV ;

int selected_pGroup_Offset;

StructuredBuffer<float4> Buffer_posLifeT;
StructuredBuffer<float4> Buffer_velMass;
StructuredBuffer<float4> Buffer_colSize;

//#include "../../../../ParticlesSystem/dx11/particle_struct.fxh"
//StructuredBuffer<particle> p_Buffer : PARTICLES_Buffer;

float depthRadiusMult = 1;
float particleRot_to_normals_Amount;

float gVelocityGain : GLOBAL_MOTIONBLUR_MULT;

//float3 cam_Pos;
float2 sizeCloseupFadeOut_minMaxDist;
//float2 bornScaleAnim_InOut;

float SizeMult = 1;
float distWfactor = 1;

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
	float4 col : COLOR ;
	//float3 info : TEXCOORD1 ;
	float size : TEXCOORD2 ;
	float3 vel : TEXCOORD3 ;
	float3 normW : NORMAL ;
};

VS_OUT VS(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;
	
	uint id = In.iv + selected_pGroup_Offset;
	
	float4 posLifeT = Buffer_posLifeT[id];
	float4 velMass = Buffer_velMass[id];
	float4 colSize = Buffer_colSize[id];

	Out.posW = posLifeT.xyz;
	Out.normW = normalize(velMass.xyz);
	Out.col.xyz = colSize.xyz;
	Out.col.a = 1;//saturate(1-p_Buffer[id].info.x);
	//Out.info = p_Buffer[id].info;

	Out.size = colSize.w; //smoothstep(bornScaleAnim_InOut.x, bornScaleAnim_InOut.y, p_Buffer[id].lifeT);
	Out.vel = velMass.xyz;
	
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

	float4 posLifeT = Buffer_posLifeT[id];
//	float4 velMass = Buffer_velMass[id];
	float4 colSize = Buffer_colSize[id];

	Out.posW = posLifeT.xyz;
	
	//float lifeTscale = smoothstep(bornScaleAnim_InOut.x, bornScaleAnim_InOut.y, p_Buffer[id].lifeT);
	Out.size = colSize.w;//p_Buffer[id].size * lifeTscale;

	
    return Out;
}

//==============================================================================
// GEOMETRY SHADER =============================================================
//==============================================================================


float3x3 lookat(float3 dir,float3 up=float3(0,1,0)){float3 z=normalize(dir);float3 x=normalize(cross(up,z));float3 y=normalize(cross(z,x));return float3x3(x,y,z);} 

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
	float3 posW: POSITION1 ;
	float3 posW_Prev: POSITION2 ;
	float3 normWV : NORMAL ;
	float4 col : COLOR ;
	//float3 info : TEXCOORD0 ;
	float2 texCd : TEXCOORD1 ;
	//float size : TEXCOORD2 ;
	float3x3 rot : TEXCOORD3 ;
};

[maxvertexcount(4)]
void GS(point VS_OUT In[1], inout TriangleStream<GS_OUT> SpriteStream)
{
    GS_OUT Out;
    
	float3 posW = In[0].posW;
	if(Culling(posW))
	{		
		//Out.info = In[0].info;
	    Out.col = In[0].col;
	    Out.normWV = mul(In[0].normW,(float3x3)tV);
		//Out.size = In[0].size;
		
		Out.posW = posW;
		Out.posW_Prev = posW - In[0].vel * tStep;
		
		Out.rot = lookat(mul(float4(posW - tVI[3].xyz, 0), tV));

		float camDist = distance(tVI[3].xyz , posW);
		float camDistMult = smoothstep(sizeCloseupFadeOut_minMaxDist.x, sizeCloseupFadeOut_minMaxDist.y, camDist);
		

		
		
		
		float wFactor = mul( float4(posW,1.0), tVP ).w;
		
		float uvFactor = min(0.5 * distWfactor / wFactor, 1);
		float SizeWFactor = max(wFactor, distWfactor);
			
		float radiusCoef = In[0].size * SizeMult * SizeWFactor * 0.01 * camDistMult;
		
		Out.col.w = radiusCoef;
		
		
		
		
		
		for(int i=0; i<4; i++)
		{
			float3 position = g_positions[i]  * radiusCoef;//* camDistMult;// * In[0].size * sizePerspCorrection;
		    position = mul(position, (float3x3)tVI ) + posW;
			//Out.posWV = mul(float4(position,1.0), tV).xyz;
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
	float2 texCd : TEXCOORD1 ;
};

[maxvertexcount(4)]
void GS_Depth(point VS_Depth_OUT In[1], inout TriangleStream<GS_Depth_OUT> SpriteStream)
{
    GS_Depth_OUT Out;
    
	if(Culling(In[0].posW))
	{	
		for(int i=0; i<4; i++)
		{
			float3 position = g_positions[i] * In[0].size * depthRadiusMult;// * sizePerspCorrection;
		    position = mul(position, (float3x3)tVI ) + In[0].posW.xyz;
		    Out.posWVP = mul(float4(position,1.0), tVP);
		    Out.texCd = g_texcoords[i];	
			
		    SpriteStream.Append(Out);
		}
		SpriteStream.RestartStrip();
		
	}
}

//==============================================================================
// PIXEL SHADER ================================================================
//==============================================================================

#include "../../../../../../rendering/RenderEngine/fxh/MRT_struct.fxh"

PS_OUT PS_circle(GS_OUT In)
{
	clip(1-length(In.texCd-.5)-0.5f);

	PS_OUT Out = (PS_OUT)0;
	
	Out.col = float4(In.col.xyz, 1);
	Out.normV = float4(0.5,0.5,0,0);
	//Out.normV = float4(Out.normV.xyz+In.normWV.xyz)*0.5+0.5, 0);
	
	float4 posWVP = mul(float4(In.posW,1), tVP);
	float4 prevPosWVP = mul(float4(In.posW_Prev,1), tVP_Prev);
	Out.vel = posWVP.xy/posWVP.w - prevPosWVP.xy/prevPosWVP.w;
    Out.vel *= 0.5 *gVelocityGain;
	Out.vel += 0.5;
	
    return Out;
}


PS_OUT_WriteDepth PS_Sphere_Impostors(GS_OUT In)
{
	clip(1-length(In.texCd-.5)-0.5f);

	PS_OUT_WriteDepth Out = (PS_OUT_WriteDepth)0;
	
	Out.col = float4(In.col.xyz, 1);

	
	float x = In.texCd.x*2-1;
    float y = In.texCd.y*2-1;
    float zz = 1.0 - x*x - y*y;

    float z = -sqrt(zz);    
    float4 pos = mul(float4(In.posW, 1), tV);
    pos.z += z * In.col.w;// * In.size;// * sphere_radius;
    pos = mul(pos, tP);
	
    Out.depth = (pos.z / pos.w);

	float3 norm = float3(x,y,z);
	norm = mul(norm, In.rot).xyz;
	//norm = mul(float4(norm,0), tVI).xyz;
	//norm = mul(float4(norm,1),float4(In.posW,1));
	
	norm = lerp(norm, In.normWV, particleRot_to_normals_Amount);
	
	Out.normV = float4(normalize(norm)*0.5+0.5, 1);//In.normWV*0.5+0.5;

	float4 posWVP = mul(float4(In.posW,1), tVP);
	float4 prevPosWVP = mul(float4(In.posW_Prev,1), tVP_Prev);
	Out.vel = posWVP.xy/posWVP.w - prevPosWVP.xy/prevPosWVP.w;
    Out.vel *= 0.5 * gVelocityGain;
	Out.vel += 0.5;

    return Out;
}

float PS_circle_depth(GS_Depth_OUT In): SV_Target
{
	clip(1-length(In.texCd-.5)-0.5f);

	return 1;
}


//==============================================================================
// TECHIQUES ===================================================================
//==============================================================================

technique11 _circle
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_circle() ) );
	}
}

technique11 _Sphere_Impostors
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Sphere_Impostors() ) );
	}
}

technique11 _circle_Depth
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS_Depth() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS_Depth() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_circle_depth() ) );
	}
}

