#include "UnityStandardInput.cginc"

// just for NormalizePerPixelNormal()
#include "UnityStandardCore.cginc"

// LightingStandardSpecular(), LightingStandardSpecular_GI(),
// LightingStandardSpecular_Deferred() and
// struct SurfaceOutputStandardSpecular are defined here.
#include "UnityPBSLighting.cginc"

struct appdata_vert {
	float4 vertex : POSITION;
	half3 normal : NORMAL;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float4 texcoord1 : TEXCOORD2; // lightmaps and meta pass (not sure)
	float4 texcoord2 : TEXCOORD3; // dynamig GI and meta pass (not sure)
#ifdef _TANGENT_TO_WORLD
	float4 tangent : TANGENT;
#endif
};

struct Input {
	float4 texcoords;
#if defined(_PARALLAXMAP)
	half3 viewDirForParallax;
#endif
};

void vert (inout appdata_vert v, out Input o) {
	UNITY_INITIALIZE_OUTPUT(Input,o);
	o.texcoords.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
	o.texcoords.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
#ifdef _PARALLAXMAP
	TANGENT_SPACE_ROTATION; // refers to v.normal and v.tangent
	o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
#endif
}

void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
#ifdef _PARALLAXMAP
	half3 viewDirForParallax = NormalizePerPixelNormal(IN.viewDirForParallax);
#else
	half3 viewDirForParallax = half3(0,0,0);
#endif
	float4 texcoords = IN.texcoords;
	texcoords = Parallax(texcoords, viewDirForParallax);
	half alpha = Alpha(texcoords.xy);
#if defined(_ALPHATEST_ON)
	clip (alpha - _Cutoff);
#endif
	o.Albedo = Albedo(texcoords);
	half4 specGloss = SpecularGloss(texcoords.xy);
	o.Specular = specGloss.rgb; // _SpecColor or _SpecGlossMap.rgb
#ifdef _NORMALMAP
	o.Normal = NormalInTangentSpace(texcoords);
	o.Normal = NormalizePerPixelNormal(o.Normal);
#endif
	o.Emission = Emission(texcoords.xy);
	o.Smoothness =specGloss.a; // _Glossiness or _SpecGlossMap.a
	o.Occlusion = Occlusion(texcoords.xy);
	o.Alpha = alpha;
}

void final (Input IN, SurfaceOutputStandardSpecular o, inout fixed4 color)
{
	color = OutputForward(color, color.a);
}
