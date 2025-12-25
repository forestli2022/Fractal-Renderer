
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
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform int _MaxIterations;
            uniform float _Accuracy;
            uniform float _maxDistance;
            uniform float3 _LightDir, _LightCol;
            uniform float _LightIntensity;
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity, _ShadowPenumbra;
            uniform float _AoStepsize, _AoIntensity;
            uniform int _AoIterations;

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
               
            // Menger Sponge
            uniform float3 pos;
            uniform float menger_size;
            uniform int menger_iteration;
            uniform float4 Color;

            // distance Field
            float2 distanceField(float3 p) {
                return MengerSponge(p + pos.xyz, menger_size, menger_iteration);
            }

            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(
                    distanceField(p + offset.xyy).x - distanceField(p - offset.xyy).x,
                    distanceField(p + offset.yxy).x - distanceField(p - offset.yxy).x,
                    distanceField(p + offset.yyx).x - distanceField(p - offset.yyx).x);
                return normalize(n);
            }

            float3 hardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
                for (float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t).x;
                    if (h < 0.01) {
                        return 0.0;
                    }
                }
                return 1.0;
            }

            float3 softShadow(float3 ro, float3 rd, float mint, float maxt, float k)
            {
                float result = 1.0;
                for (float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t).x;
                    if (h < 0.01) {
                        return 0.0;
                    }
                    result = min(result, k * h / t);
                    t += h;
                }
                return result;
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float step = _AoStepsize;
                float ao = 0.0;
                float dist;
                for (int i = 1; i <= _AoIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - distanceField(p + n * dist).x) / dist);
                }
                return (1 - ao * _AoIntensity);
            }

            float3 shading(float3 p, float3 n, float3 c)
            {
                float3 result;
                // Diffuse Color
                float3 color = c;

                // directional light
                float3 light = (_LightCol * dot(-_LightDir, n) * 0.5 + 0.5) * _LightIntensity;

                // shadows
                float shadow = softShadow(p, -_LightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));

                // ambient occlusion
                float ao = AmbientOcclusion(p, n);

                result = color * light * shadow * ao;
                return result;
            }

            fixed4 raymarching(float3 ro, float3 rd, float depth) 
            {
                fixed4 result = fixed4(1, 1, 1, 1);
                const int max_iteration = _MaxIterations;
                float t = 0;

                for (int i = 0; i < max_iteration; i++) 
                {
                    if (t > _maxDistance || t >= depth)
                    {
                        // Environment
                        result = fixed4(rd, 0);
                        break;
                    }

                    float3 p = ro + rd * t;
                    // check for hit in distance field
                    float2 d = distanceField(p);
                    if (d.x < _Accuracy)
                    {
                        // shading
                        float3 n = getNormal(p);
                        float3 s = shading(p, n, saturate(Color * palette(d.y * 16)));
                        result = fixed4(s, 1);
                        break;
                    }
                    t += d.x;
                }

                return result;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                fixed3 col = tex2D(_MainTex, i.uv);
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}
