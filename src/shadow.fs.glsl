#version 330 core
out vec4 FragColor;

// VS data structure
in VS_OUT {
    vec3 FragPos;
    vec3 Normal;
    vec2 TexCoords;
    vec4 FragPosLightSpace;
} fs_in;

// testure
uniform sampler2D diffuseTexture;
uniform sampler2D shadowMap;

// light
uniform vec3 lightPos;
uniform vec3 viewPos;

uniform float flag;//实现正交投影

uniform float near_plane;
uniform float far_plane;

float LinearizeDepth(float depth)
{
    float z = depth * 2.0 - 1.0; // Back to NDC 
    return (2.0 * near_plane * far_plane) / (far_plane + near_plane - z * (far_plane - near_plane));
}


float ShadowCalculation(vec4 fragPosLightSpace)
{
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    //归一化
    projCoords = projCoords * 0.5 + 0.5;
    //获得光照坐标系下的最近的深度值
    float closestDepth = texture(shadowMap, projCoords.xy).r; 
    //获得当前片段在光照下的深度值 
    float currentDepth = projCoords.z;
	
	closestDepth=flag>0? closestDepth:LinearizeDepth(closestDepth)/far_plane;
	currentDepth=flag>0? currentDepth:LinearizeDepth(currentDepth)/far_plane;
	//注意此时对应的大概是正交投影??

	vec3 normal = normalize(fs_in.Normal);//得到当前片元的法向量
    vec3 lightDir = normalize(lightPos - fs_in.FragPos);//得到入射方向
	float bias = max(0.05 * (1.0 - dot(normal, lightDir)), 0.005);//平移
	bias=flag>0? bias:LinearizeDepth(bias)/far_plane;
	float shadow = 0.0;//PCF
    vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    for(int x = -1; x <= 1; ++x)//中值滤波卷积
    {
        for(int y = -1; y <= 1; ++y)
        {
            float pcfDepth = texture(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r; 
			pcfDepth=flag>0? pcfDepth:LinearizeDepth(pcfDepth)/far_plane;
            shadow += currentDepth - bias > pcfDepth  ? 1.0 : 0.0;//比较两个深度值谁大，大的是阴影
        }    
    }
    shadow /= 9.0;//去中值
	
	if(projCoords.z > 1.0)
        shadow = 0.0;
    return shadow;
}

void main()
{
    vec3 color = texture(diffuseTexture, fs_in.TexCoords).rgb;
    vec3 normal = normalize(fs_in.Normal);
    vec3 lightColor = vec3(0.3);

    vec3 ambient = 0.3 * color;//环境光
    vec3 lightDir = normalize(lightPos - fs_in.FragPos);//漫反射
    float diff = max(dot(lightDir, normal), 0.0);
    vec3 diffuse = diff * lightColor;//
	
    vec3 viewDir = normalize(viewPos - fs_in.FragPos);
    vec3 reflectDir = reflect(-lightDir, normal);//镜面反射
    float spec = 0.0;
    vec3 halfwayDir = normalize(lightDir + viewDir);
    spec = pow(max(dot(normal, halfwayDir), 0.0), 64.0);
    vec3 specular = spec * lightColor;

    float shadow = ShadowCalculation(fs_in.FragPosLightSpace);//获得阴影值

    vec3 lighting = (ambient + (1.0 - shadow) * (diffuse + specular)) * color;//光照模型 注意是（1-阴影），因为阴影等效于对光照的削弱，而且不影响环境光
    FragColor = vec4(lighting, 1.0);
}