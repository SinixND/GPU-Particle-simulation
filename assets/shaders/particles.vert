#version 430

//* Vertex data
layout(location = 0) in vec2 inputPosition;

//* Particle data
layout(std430, binding = 0) buffer ssboParticlePositions {
    vec4 particlePositions[];
};

layout(std430, binding = 1) buffer ssboParticleColors {
    vec4 particleColors[];
};

out vec4 vertexColor;

void main()
{
    gl_PointSize = 2.0f;

    vec4 vertexPosition = vec4(inputPosition, 0.0, 1.0) + particlePositions[gl_InstanceID];

    vertexColor = particleColors[gl_InstanceID];

    gl_Position = vertexPosition;
}
