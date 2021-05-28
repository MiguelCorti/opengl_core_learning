#version 330 core
struct Material
{
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

uniform sampler2D sampler; // Textura de Cor
uniform sampler2D shadowMap; // Mapa de Sombras
uniform vec3 lightPosition; // Posicao da luz no espaco da camera
uniform Material material;
uniform vec3 viewPos; // Posicao da camera

in vec3 fragPos; // Posicao do fragmento na camera
in vec3 fragNormal; // Normal do fragmento
in vec2 fragUV; // Coord de textura do fragmento
in vec4 fragPosLightSpace; // Posicao do fragmento no espaco da luz

out vec3 finalColor;

void main()
{
    // CALCULO DA COR
    vec3 textureRGB = texture(sampler, fragUV).rgb;
    vec3 ambient = material.ambient * textureRGB;

    vec3 N = normalize(fragNormal);
    vec3 L = normalize(lightPosition - fragPos);

    float iDif = max(dot(L,N), 0.0);
    vec3 diffuse = iDif * material.diffuse * textureRGB;

    vec3 V = normalize(viewPos-fragPos);
    vec3 H = normalize(L + V);

    float iSpec = pow(max(dot(N,H),0.0), material.shininess);
    vec3 specular = iSpec * material.specular * textureRGB;

    // CALCULO DAS SOMBRAS
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    projCoords = projCoords * 0.5 + 0.5; // Transforma de [-1,1]->[0,1]
    float shadow = 0.0;
    // Se estiver alem do far da luz deixa sem sombra
    if(projCoords.z <= 1.0) {
        float closestDepth = texture(shadowMap, projCoords.xy).r; // Pega a profundidade do mapa de sombras
        float currentDepth = float(projCoords.z); // Pega a profundidade atual

        // CALCULO DO PCF
        vec2 texelSize = 1.0/textureSize(shadowMap, 0);
        float pcfSamples = 25.0; // Apenas quadrados perfeitos de numeros impares (3^2, 5^2, 7^2, ...)
        int limit = int((sqrt(pcfSamples)-1)/2);
        for(int x=-limit; x<=limit; x++)
        {
            for(int y=-limit;y<=limit;y++)
            {
                float depthPCF = texture(shadowMap, projCoords.xy + vec2(x, y)*texelSize).r;
                shadow += currentDepth > depthPCF ? 1.0 : 0.0; // OBS: Não há necessidade de bias pois é feito um glPolygonOffset ao criar o depth map
            }
        }
        shadow /= pcfSamples;
    }

    // MONTANDO A COR FINAL
    finalColor = (ambient + (1.0-shadow) * (diffuse + specular));
}
