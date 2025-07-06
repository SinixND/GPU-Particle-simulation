#version 430

//* Vertex data
layout(location = 0) in vec2 inputPosition;

layout(location = 0) uniform int WINDOW_WIDTH;
layout(location = 1) uniform int WINDOW_HEIGHT;

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
    gl_PointSize = 1.0f;

    vec4 vertexPosition = vec4(inputPosition, 0.0, 1.0) + particlePositions[gl_InstanceID];

    vertexColor = particleColors[gl_InstanceID];

    gl_Position = vec4(
            ((vertexPosition.x - (WINDOW_WIDTH / 2)) / (WINDOW_WIDTH / 2)),
            ((vertexPosition.y - (WINDOW_HEIGHT / 2)) / (WINDOW_HEIGHT / -2)),
            0,
            1);
}
