
// =============================================================================
// VOLUME FIELD =================================================================
// =============================================================================

bool VolField_Enable = 0;
float4x4 VolField_tVolInv;
float3 VolField_Strength = (float3)0.1;

Texture3D VolFieldTexture;
SamplerState Vol_sam : Immutable
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = border;
    AddressV = border;
    AddressW = border;
};

float4 VolField(float3 Pos)
{	
	float3 Coord = mul(float4(Pos,1), VolField_tVolInv).xyz;
	Coord += 0.5;
	
	return VolFieldTexture.SampleLevel(Vol_sam, Coord, 0);
}