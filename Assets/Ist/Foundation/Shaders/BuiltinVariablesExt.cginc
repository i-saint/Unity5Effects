#ifndef IstBuiltinVariablesExt_h
#define IstBuiltinVariablesExt_h

float3 GetObjectPosition()  { return float3(_Object2World[0][3], _Object2World[1][3], _Object2World[2][3]); }
float3 GetObjectForward()   { return normalize(-_Object2World[2].xyz); }
float3 GetObjectUp()        { return normalize(_Object2World[1].xyz); }
float3 GetObjectRight()     { return normalize(_Object2World[0].xyz); }

float3 GetCameraPosition()  { return _WorldSpaceCameraPos; }
float3 GetCameraForward()   { return -UNITY_MATRIX_V[2].xyz; }
float3 GetCameraUp()        { return UNITY_MATRIX_V[1].xyz; }
float3 GetCameraRight()     { return UNITY_MATRIX_V[0].xyz; }
float  GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }

float2 GetScreenSize()      { return _ScreenParams.xy; }
float2 GetPixelSize()       { return _ScreenParams.zw - 1.0; }
float  GetAspectRatio()     { return _ScreenParams.x / _ScreenParams.y; }

// screen_pos.x must be multiplies by aspect ratio
Ray GetCameraRay(float2 screen_pos)
{
    float3 cam_pos      = GetCameraPosition();
    float3 cam_forward  = GetCameraForward();
    float3 cam_up       = GetCameraUp();
    float3 cam_right    = GetCameraRight();
    float  cam_focal_len= GetCameraFocalLength();
    float3 cam_ray      = normalize(cam_right*screen_pos.x + cam_up*screen_pos.y + cam_forward*cam_focal_len);
    Ray r = { _WorldSpaceCameraPos.xyz , cam_ray };
    return r;
}

// screen_pos.x must be multiplies by aspect ratio
float3 IntersectionEyeViewPlane(float2 screen_pos, float3 plane_pos)
{
    float3 camera_dir = normalize(_WorldSpaceCameraPos.xyz - plane_pos);
    Plane plane = { camera_dir, dot(plane_pos, -camera_dir) };
    Ray ray = GetCameraRay(screen_pos);
    return IntersectionRayPlane(ray, plane);
}

float3 IntersectionEyeViewPlane(float3 world_pos, float3 plane_pos)
{
    float3 camera_dir = normalize(_WorldSpaceCameraPos.xyz - plane_pos);
    Plane plane = { camera_dir, dot(plane_pos, -camera_dir) };
    Ray ray = { _WorldSpaceCameraPos.xyz , normalize(world_pos-_WorldSpaceCameraPos.xyz)};
    return IntersectionRayPlane(ray, plane);
}

#endif // IstBuiltinVariablesExt_h
