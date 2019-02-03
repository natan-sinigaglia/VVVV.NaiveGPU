//==============================================================================
// VERLET MULTIBUFFER SETTINGS ================================================
//==============================================================================



interface iShapeConstrain
{    
    float3 ContrainPos(float3 pos);
};

class cBox : iShapeConstrain
{
    float3 ContrainPos(float3 pos)
    {    
        return pos;
    }
};

class cSphere : iShapeConstrain
{
    float3 ContrainPos(float3 pos)
    {    
        return pos;
    }
};

class cCylinder : iShapeConstrain
{
    float3 ContrainPos(float3 pos)
    {    
        return pos*2;
    }
};

cBox Box;
cSphere Sphere;
cCylinder Cylinder;
