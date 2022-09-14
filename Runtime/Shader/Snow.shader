// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Przekop/SnowShader/Snow"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Tint("Tint", Color) = (0,0,0,0)
		[Normal]_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range( 0 , 1)) = 0
		[Header(Glitter)][NoScaleOffset][SingleLineTexture]_GlitterSample("GlitterSample", 2D) = "white" {}
		[HDR]_GlitterColor("Glitter Color", Color) = (1,1,1,1)
		_glitterSize("glitterSize", Range( 0 , 1)) = 1
		_GlitterSpacing("Glitter Spacing", Range( 0 , 1)) = 0.36
		_GlitterIntensity("Glitter Intensity", Range( 0 , 1)) = 0
		[Toggle(_ANIMATEGLITTER_ON)] _AnimateGlitter("Animate Glitter", Float) = 0
		_GlitterAnimationspeed("Glitter Animation speed", Float) = 0
		[Toggle(_GLITTERUSESLITHINGDATA_ON)] _GlitterUsesLithingData("Glitter Uses Lithing Data", Float) = 0
		[Header(Subsurface scattering)][Toggle(_USESSS_ON)] _UseSSS("Use SSS", Float) = 1
		[Toggle(_SSSUSESNDOTL_ON)] _SSSUsesNDotL("SSS Uses NDotL", Float) = 1
		[HDR]_SSScolor("SSS color", Color) = (0.2156863,0.8862746,0.8352942,1)
		[Toggle(_SSSUSELIGHTCOLOR_ON)] _SSSUseLightColor("SSS Use Light Color", Float) = 0
		_SnowLightTransmition("Snow Light Transmition", Range( 0 , 1)) = 0.03540839
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma shader_feature_local _USESSS_ON
		#pragma shader_feature_local _SSSUSESNDOTL_ON
		#pragma shader_feature_local _SSSUSELIGHTCOLOR_ON
		#pragma shader_feature_local _GLITTERUSESLITHINGDATA_ON
		#pragma shader_feature_local _ANIMATEGLITTER_ON
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
		};

		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float _NormalScale;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform float4 _Tint;
		uniform float _SnowLightTransmition;
		uniform float4 _SSScolor;
		uniform float _GlitterSpacing;
		uniform sampler2D _GlitterSample;
		uniform float _glitterSize;
		uniform float _GlitterAnimationspeed;
		uniform float _GlitterIntensity;
		uniform float4 _GlitterColor;


		inline float4 TriplanarSampling2_g53( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		float3 HSVToRGB( float3 c )
		{
			float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		float3 RGBToHSV(float3 c)
		{
			float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
			float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
			float d = q.x - min( q.w, q.y );
			float e = 1.0e-10;
			return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float3 tex2DNode33 = UnpackScaleNormal( tex2D( _NormalMap, uv_NormalMap ), _NormalScale );
			o.Normal = tex2DNode33;
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			o.Albedo = ( tex2D( _MainTex, uv_MainTex ) * _Tint ).rgb;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float fresnelNdotV73_g53 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode73_g53 = ( 0.0 + 0.1 * pow( 1.0 - fresnelNdotV73_g53, 1.4 ) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 NormalInput77_g53 = tex2DNode33;
			float dotResult48_g53 = dot( ase_worldlightDir , normalize( (WorldNormalVector( i , NormalInput77_g53 )) ) );
			float NDotL133_g53 = saturate( dotResult48_g53 );
			#ifdef _SSSUSESNDOTL_ON
				float staticSwitch79_g53 = NDotL133_g53;
			#else
				float staticSwitch79_g53 = 1.0;
			#endif
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float temp_output_142_0_g53 = ( _SnowLightTransmition * 0.5 );
			float fresnelNdotV26_g53 = dot( ase_normWorldNormal, ( ase_worldlightDir * float3( -1,-1,-1 ) ) );
			float fresnelNode26_g53 = ( 0.0 + temp_output_142_0_g53 * pow( 1.0 - fresnelNdotV26_g53, 1.2 ) );
			float fresnelNdotV16_g53 = dot( ase_normWorldNormal, ase_worldlightDir );
			float fresnelNode16_g53 = ( -0.03 + temp_output_142_0_g53 * pow( 1.0 - fresnelNdotV16_g53, 1.2 ) );
			float fresnelNdotV86_g53 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode86_g53 = ( 0.01 + 1.0 * pow( 1.0 - fresnelNdotV86_g53, 1.0 ) );
			float3 temp_cast_1 = (1.0).xxx;
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			#ifdef _SSSUSELIGHTCOLOR_ON
				float3 staticSwitch129_g53 = ase_lightColor.rgb;
			#else
				float3 staticSwitch129_g53 = temp_cast_1;
			#endif
			#ifdef _USESSS_ON
				float4 staticSwitch72_g53 = ( max( ( fresnelNode73_g53 * staticSwitch79_g53 ) , saturate( ( min( fresnelNode26_g53 , fresnelNode16_g53 ) * fresnelNode86_g53 ) ) ) * _SSScolor * float4( staticSwitch129_g53 , 0.0 ) );
			#else
				float4 staticSwitch72_g53 = float4( 0,0,0,0 );
			#endif
			float4 temp_cast_3 = (_GlitterSpacing).xxxx;
			float4 temp_cast_4 = (( _GlitterSpacing + 0.01 )).xxxx;
			float3 objToWorldDir125_g53 = mul( unity_ObjectToWorld, float4( float3( 0,1,0 ), 0 ) ).xyz;
			float2 temp_cast_5 = (( length( objToWorldDir125_g53 ) * ( ( 1.0 - _glitterSize ) * 10.0 ) )).xx;
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			ase_vertexNormal = normalize( ase_vertexNormal );
			float4 triplanar2_g53 = TriplanarSampling2_g53( _GlitterSample, ase_vertex3Pos, ase_vertexNormal, 4.0, temp_cast_5, 1.0, 0 );
			float3 hsvTorgb111_g53 = RGBToHSV( triplanar2_g53.xyz );
			float mulTime42_g53 = _Time.y * _GlitterAnimationspeed;
			float3 hsvTorgb113_g53 = HSVToRGB( float3(( hsvTorgb111_g53.x * mulTime42_g53 ),hsvTorgb111_g53.y,hsvTorgb111_g53.z) );
			#ifdef _ANIMATEGLITTER_ON
				float4 staticSwitch40_g53 = float4( hsvTorgb113_g53 , 0.0 );
			#else
				float4 staticSwitch40_g53 = triplanar2_g53;
			#endif
			float4 smoothstepResult51_g53 = smoothstep( temp_cast_3 , temp_cast_4 , staticSwitch40_g53);
			float dotResult4_g53 = dot( (float4( -1,-1,-1,-1 ) + (smoothstepResult51_g53 - float4( 0,0,0,0 )) * (float4( 1,1,1,1 ) - float4( -1,-1,-1,-1 )) / (float4( 1,1,1,1 ) - float4( 0,0,0,0 ))) , float4( ( 1.0 - ase_worldViewDir ) , 0.0 ) );
			#ifdef _GLITTERUSESLITHINGDATA_ON
				float staticSwitch13_g53 = ( dotResult4_g53 * saturate( NDotL133_g53 ) * ase_lightColor.a );
			#else
				float staticSwitch13_g53 = dotResult4_g53;
			#endif
			o.Emission = ( staticSwitch72_g53 + ( saturate( staticSwitch13_g53 ) * ( _GlitterIntensity * 100.0 ) * _GlitterColor ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
318;212;1119;542;708.0201;382.8002;1.338435;True;False
Node;AmplifyShaderEditor.RangedFloatNode;34;-732.2228,49.97691;Inherit;False;Property;_NormalScale;Normal Scale;3;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;33;-429.4444,32.62936;Inherit;True;Property;_NormalMap;NormalMap;2;1;[Normal];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;30;-463.0652,-377.7794;Inherit;True;Property;_MainTex;MainTex;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;32;-368,-192;Inherit;False;Property;_Tint;Tint;1;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;114;-395.5763,235.6511;Inherit;False;SnowHelper;4;;53;30eb8b96fe7c7774481564c9c5c1dc63;0;1;69;FLOAT3;0,0,0;False;2;COLOR;17;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-128,-384;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;23;-140.9084,231.1174;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;218.4909,10.32175;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Przekop/SnowShader/Snow;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;33;5;34;0
WireConnection;114;69;33;0
WireConnection;31;0;30;0
WireConnection;31;1;32;0
WireConnection;23;0;114;17
WireConnection;23;1;114;0
WireConnection;0;0;31;0
WireConnection;0;1;33;0
WireConnection;0;2;23;0
ASEEND*/
//CHKSM=394219E3F9BDD1DF0F5F3A178D9577B44BF6BBA1