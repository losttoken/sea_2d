Shader "Unlit/sea_2d"
{
    Properties
    {

        u_sea ("水底背景", 2D) = "white" {}


        u_noise ("噪声", 2D) = "white" {}
        u_noise2 ("噪声2", 2D) = "white" {}
        u_freq ("频谱", 2D) = "white" {}

        u_under_water ("水下纹理", 2D) = "white" {}
        u_wave ("折射水面法线", 2D) = "white" {}
        u_far_wave ("远处水面法线", 2D) = "white" {}

        u_depth ("深度", 2D) = "white" {}




        u_fract_x ("折射偏移调整x方向",Range(-1.0,1.0))=0.0
        u_fract_y ("折射偏移调整y方向",Range(-1.0,1.0))=0.0


        
        u_spec ("高光倍率",Range(0.0,100.0))=1.0
        u_spec_power ("高光度",Range(0.0,20.0))=15.2
        u_foam_x ("远处浪花的采样频率x",Range(0.0,50.0))=1.0
        u_foam_y ("远处浪花的采样频率y",Range(0.0,50.0))=1.0
        u_foam_speed_x ("远处浪花流速倍率x",Range(-5.0,5.0))=3.0
        u_foam_speed_y ("远处浪花流速倍率y",Range(-5.0,5.0))=-1.0


        u_offset ("大波流速",Range(0.0,1.0))=0.0
        u_small_offset ("小波流速",Range(0.0,33.333333))=0.0



        u_refractionFactor ("折射率",Range(0.0,1.0))=0.258
        u_offsetFactor ("折射偏移",Range(0.0,1.0))=0.055


        u_light_x ("u_light_x",Range(-1.0,1.0))=1.0
        u_light_y ("u_light_y",Range(-1.0,1.0))=1.0
        u_light_z ("u_light_z",Range(-1.0,1.0))=1.0
        u_eye_x ("u_eye_x",Range(-1.0,1.0))=0.0
        u_eye_y ("u_eye_y",Range(-1.0,1.0))=1.0
        u_eye_z ("u_eye_z",Range(-1.0,1.0))=0.5


    }
    SubShader
    {
        Tags {             
            "Queue" = "Transparent"
            "RenderType"="Transparent" 
        }
        LOD 100

        Pass
        {
            GLSLPROGRAM
            #ifdef VERTEX
            varying vec2 v_texCoord;
            varying vec4 v_tangent;

            attribute vec4 Tangent;

            void main()
            {
                gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
                v_texCoord=gl_MultiTexCoord0.xy;
                v_tangent=Tangent;
            }
            #endif


            #ifdef FRAGMENT 
            varying vec2 v_texCoord;
            uniform float u_width;
            uniform float u_height;
 
            uniform sampler2D u_wave;
            uniform sampler2D u_depth;


            uniform sampler2D u_far_wave;

            uniform float  u_offset;
            uniform float  u_small_offset;

            uniform sampler2D u_sea;
            uniform sampler2D u_noise;
            uniform sampler2D u_noise2;
            uniform sampler2D u_under_water;

            uniform sampler2D u_freq;
            uniform sampler2D u_env;

            uniform float u_spec;
            uniform float u_spec_power;


            uniform float u_fract_x;
            uniform float u_fract_y;


            uniform float u_foam_x;
            uniform float u_foam_y;
            uniform float u_foam_speed_x;
            uniform float u_foam_speed_y;



            uniform float u_refractionFactor;
            uniform float u_offsetFactor;



            uniform float u_light_x;
            uniform float u_light_y;
            uniform float u_light_z;
            uniform float u_eye_x;
            uniform float u_eye_y;
            uniform float u_eye_z;


            const float  PI=3.141592653;

            float DTerm(float NdotH, float i_roughness) {
                //DGGX =  a^2 / π((a^2 – 1) (n · h)^2 + 1)^2
                float a2 = i_roughness * i_roughness;
                float val = ((a2 - 1.0) * (NdotH * NdotH) + 1.0);
                return a2 / (PI * (val * val));
            }
            float GTerm(float NdotL, float NdotV, float i_roughness) {
                //G(l,v,h)=1/(((n·l)(1-k)+k)*((n·v)(1-k)+k))
                float k = i_roughness * i_roughness / 2.0;
                return 0.5 / ((NdotL * (1.0 - k) + k) + (NdotV * (1.0 - k) + k));
            }

            vec3 FTerm(vec3 F0, float LdotH) {
                //F(l,h) = F0+(1-F0)(1-l·h)^5
                return F0 + (1.0 - F0) * pow(1.0 - LdotH, 5.0);
            }

            void main()
            {

                float noise=texture2D(u_noise,v_texCoord).r;
               // float spray= pow(texture2D(u_freq,v_texCoord).r,1.8)*clamp(pow(cos(-10000.0*(u_offset+0.0003*noise)+200.0*(1.0-1.0/3.0)),50.0),0.0,1.0);
                float weight=texture2D(u_freq,v_texCoord).r;
                float spray=cos(-(80.0+25.0*noise)*(weight)+10000.0*u_offset);
                spray*=pow(weight,4.0);


                float spray_substract=cos(-(-50.0)*(weight)+1000.0*u_offset);
                spray_substract=pow(spray_substract,0.2);
                spray*=spray_substract;

                spray=clamp(spray,0.0,1.0);


                vec3 normal1=texture2D(u_wave,vec2((0.3+2.0*weight)*v_texCoord.y-0.3*u_small_offset,(0.3+2.0*weight)*v_texCoord.x+0.3*u_small_offset)).rgb;
                vec3 normal2=texture2D(u_wave,vec2((0.3+2.0*weight)*v_texCoord.y+0.3*u_small_offset,(0.3+2.0*weight)*v_texCoord.x+0.3*u_small_offset)).rgb;
                vec3 normal=normalize(normal1+normal2);
                vec3 inVec = vec3(-1.0,0.5,1.0); 
                vec3 refractVec = refract(inVec, normal, u_refractionFactor);
                vec2 fract_coord=v_texCoord;
                fract_coord += (refractVec.xy-vec2(u_fract_x,u_fract_y)) * u_offsetFactor;




                vec3 normal1_far=texture2D(u_far_wave,vec2(u_foam_x*v_texCoord.x-u_foam_speed_x*u_small_offset,u_foam_y*v_texCoord.y+u_foam_speed_y*u_small_offset)).rgb;
                vec3 normal2_far=texture2D(u_far_wave,vec2(u_foam_x*v_texCoord.x+u_foam_speed_x*u_small_offset,u_foam_y*v_texCoord.y+u_foam_speed_y*u_small_offset)).rgb;
                vec3 normal_far=normalize(normal1_far+normal2_far);
                vec3 light=normalize(vec3(u_light_x,u_light_y,u_light_z));
                vec3 eye=normalize(vec3(u_eye_x,u_eye_y,u_eye_z));


                vec3 specColor=vec3(1.0,1.0,1.0);
                float NdotL = clamp(dot(normal_far, light),0.0,1.0);
                float NdotV = abs(clamp(dot(normal_far, eye),0.0,1.0));
                vec3 halfDirection = normalize(eye + light);
                float NdotH = clamp(dot(normal_far, halfDirection),0.0,1.0);
                float LdotH = clamp(dot(light, halfDirection),0.0,1.0);

                float roughness=0.9;                                                                                                            
                float roughness2=roughness*roughness;

                float D=DTerm(NdotH,roughness2);
                float G=GTerm(NdotL,NdotV,roughness2);
                vec3 F=FTerm(specColor,LdotH);

                float spec=NdotL*G*D*PI*F.r;






                float specular=max(0.0,dot(reflect(light,normal_far),eye));
                vec4 under_water=1.0*texture2D(u_under_water,fract_coord);






                gl_FragColor=texture2D(u_sea,v_texCoord)*(0.6+0.4*texture2D(u_depth,v_texCoord).r);
                gl_FragColor=mix(gl_FragColor,under_water,under_water.a);

                gl_FragColor.rgb+=vec3(30.0)*spray;


                //gl_FragColor.rgb=normal;


                //gl_FragColor.rgb+=vec3(u_spec)*pow(specular,u_spec_power);
                gl_FragColor.rgb+=vec3(3.0).rgb*spec;



            }
            #endif

            ENDGLSL
        }
    }
}
