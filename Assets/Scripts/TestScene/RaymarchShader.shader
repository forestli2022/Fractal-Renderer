Shader "PeerPlay/NewImageEffectShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "Assets/Scripts/RayMarchingBasic/DistanceFunctions.cginc"

            sampler2D _MainTex;
            // Setup
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform int _MaxIterations;
            uniform float _maxDistance;
            uniform float _Accuracy;
            // Light
            uniform float3 _LightDir, _LightCol;
            uniform float _LightIntensity;
            // Shadow
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity, _ShadowPenumbra;
            // AO
            uniform float _AoStepsize, _AoIntensity;
            uniform int _AoIterations;
            uniform float _StepSize;
            // Reflection
            uniform int _ReflectionCount;
            uniform float _ReflectionIntensity;
            uniform float _EnvReflIntensity;
            uniform samplerCUBE _ReflectionCube;



            // Colour
            uniform fixed3 _BackgroundColor;
            uniform fixed4 _MainColour;
            uniform fixed4 _SphereColour[8];
            uniform float _ColourIntensity;
            // SDF
            uniform float4 _sphere;
            uniform float _sphereSmooth;
            uniform float _degreeRotate;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;
                o.ray /= abs(o.ray.z);
                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }

            float3 RotateY(float3 v, float degree){
                float rad = 0.0174532925 * degree;
                float cosY = cos(rad);
                float sinY = sin(rad);
                return float3(cosY * v.x - sinY * v.z, v.y, sinY * v.x + cosY * v.z);
            }

            // distance Field, rgb -> colour, a -> distance
            float4 distanceField(float3 p)
            {
                float4 plane = float4(_MainColour.rgb, sdPlane(p, float3(0, 1, 0), 0));
                float4 sphere = float4(_SphereColour[0].rgb, sdSphere(p - _sphere.xyz, _sphere.w));
                for(int i=1; i<8; i++){
                    float4 sphereAdd = float4(_SphereColour[i].rgb, sdSphere(RotateY(p, _degreeRotate * i) - _sphere.xyz, _sphere.w));
                    sphere = opSmoothUnionColoured(sphere, sphereAdd, _sphereSmooth);
                }
                return opSmoothUnionColoured(sphere, plane, _sphereSmooth);
            }

            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.01, 0.0);
                float3 n = float3(
                distanceField(p + offset.xyy).w - distanceField(p - offset.xyy).w,
                distanceField(p + offset.yxy).w - distanceField(p - offset.yxy).w,
                distanceField(p + offset.yyx).w - distanceField(p - offset.yyx).w);
                return normalize(n);
            }

            float softShadow(float3 surfacePoint, float3 lightDir, float mint, float maxt, float k)
            {
                float3 origin = surfacePoint + 0.001 * lightDir;

                float3 ro = origin;
                float3 rd = lightDir;
                
                float res = 1.0;
                float t = 0.0;

                for (int i = mint; i < maxt; i++)
                {
                    float h = distanceField(ro + rd * t).w;

                    if (h < 0.0001)
                    return 0.0;

                    if (t > maxt)
                    break;

                    res = min(res, k * h / t);
                    t += h;
                }

                return res;
            }
            
            float AmbientOcclusion(float3 p, float3 n)
            {
                float step = _AoStepsize;
                float ao = 0.0;
                float dist;
                for (int i = 1; i <= _AoIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - distanceField(p + n * dist).w) / dist);
                }
                return (1 - ao * _AoIntensity);
            }

            float3 shading(float3 p, float3 n, fixed3 c)
            {
                float3 result;
                // Diffuse Color
                float3 color = c.rgb * _ColourIntensity;

                // directional light
                float3 light = (_LightCol * dot(-_LightDir, n) * 0.5 + 0.5) * _LightIntensity;

                // shadows
                float shadow = softShadow(p, -_LightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));

                // ambient occlusion
                float ao = AmbientOcclusion(p, n);

                // diffuse reflection
                float dif = clamp(dot(n, _LightDir), 0.0, 1.0) + 0.5;

                // gamma correction
                color = pow(color, float3(1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2));

                result = color * light * shadow * ao * dif;
                return result;
            }

            bool raymarching(float3 ro, float3 rd, float depth, float maxDistance, int maxIterations, inout float3 p, inout fixed3 dColour) 
            {
                bool hit;
                const int max_iteration = _MaxIterations;
                float t = 0.01;

                for (int i = 0; i < maxIterations; i++) 
                {
                    if (t > maxDistance || t >= depth)
                    {
                        // Environment
                        hit = false;
                        break;
                    }

                    p = ro + rd * t;
                    // check for hit in distance field
                    float4 d = distanceField(p);
                    if (abs(d.w) < _Accuracy)
                    {
                        dColour = d.rgb;
                        hit = true;
                        break;
                    }
                    
                    t += d.w * _StepSize;
                }
                // fog
                //result.xyz = lerp(result.xyz, _BackgroundColor, 1.0 - exp(-0.000000002 * t * t * t));
                return hit;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                // fixed3 col = _BackgroundColor;
                fixed3 col = tex2D(_MainTex, i.uv);
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result;
                float3 hitPosition;
                fixed3 dColour;
                bool hit = raymarching(rayOrigin, rayDirection, depth, _maxDistance, _MaxIterations, hitPosition, dColour);
                if(hit){
                    // shading
                    float3 n = getNormal(hitPosition);
                    float3 s = shading(hitPosition, n, dColour);
                    result = fixed4(s, 1);
                    // reflection!
                    result += fixed4(texCUBE(_ReflectionCube, n).rgb * _EnvReflIntensity * _ReflectionIntensity, 0);
                    if(_ReflectionCount > 0){
                        rayDirection = normalize(reflect(rayDirection, n));
                        rayOrigin = hitPosition + rayDirection * 0.01;
                        hit = raymarching(rayOrigin, rayDirection, _maxDistance, _maxDistance * 0.5, _MaxIterations / 2, hitPosition, dColour);
                        if(hit){
                            // shading
                            float3 n = getNormal(hitPosition);
                            float3 s = shading(hitPosition, n, dColour);
                            result += fixed4(s * _ReflectionIntensity, 0);
                            if(_ReflectionCount > 1){
                                rayDirection = normalize(reflect(rayDirection, n));
                                rayOrigin = hitPosition + rayDirection * 0.01;
                                hit = raymarching(rayOrigin, rayDirection, _maxDistance, _maxDistance * 0.25, _MaxIterations / 4, hitPosition, dColour);
                                if(hit){
                                    float3 n = getNormal(hitPosition);
                                    float3 s = shading(hitPosition, n, dColour);
                                    result += fixed4(s * _ReflectionIntensity * 0.5, 0);
                                }
                            }
                        }
                    }
                }else
                {
                    result = fixed4(0, 0, 0, 0);
                }
                
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}
