#version 430

//* Workgroup data
layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in;

//* Particle data
layout(std430, binding = 0) buffer ssboParticlePositions {
    vec4 particlePositions[];
};

layout(std430, binding = 1) buffer ssboParticleVelocities {
    vec4 particleVelocities[];
};

// layout(std430, binding = 2) buffer ssboDebug {
//     float debugBuffer[];
// };

layout(location = 0) uniform vec2 POSITION_MOUSE;
layout(location = 1) uniform float DT;
layout(location = 2) uniform float VELOCITY_DAMPING;
layout(location = 3) uniform float GRAVITY_FACTOR;
layout(location = 4) uniform float ACCELERATION_CAP;
layout(location = 5) uniform int WINDOW_WIDTH;
layout(location = 6) uniform int WINDOW_HEIGHT;

vec2 wrap(
    vec2 position,
    float windowWidth,
    float windowHeight
);

void main()
{
    uint idx = gl_GlobalInvocationID.x;

    //* Get SSBO data
    vec4 positionParticle = particlePositions[idx];
    vec4 velocityParticle = particleVelocities[idx];

    vec2 distance = POSITION_MOUSE - positionParticle.xy;
    //* Cap lower bound -> Cap upper acceleration
    float length = length(distance);
    vec2 direction = normalize(distance);

    //* Calculate new position by simulating gravity
    //* x(t) = a * t^2 + v_0 * t + x_0

    //* Acceleration = G * ((m_1 + m_2) / r^2)
    float a = (GRAVITY_FACTOR / (length * length));
    //* Sanity cap
    a = clamp(a, 0.0, ACCELERATION_CAP);
    vec2 acceleration = a * direction;

    //* Do not update velocity if mouse position == {0,0}
    //* This is the default when using raylib. Transformed into GPU space
    if ((POSITION_MOUSE.x == 0) && (POSITION_MOUSE.y == 0))
    {
        acceleration = vec2(0, 0);
    }

    //* Velocity = vel_damp * (a * dt) + v_0
    vec2 newVelocity = VELOCITY_DAMPING * ((acceleration * DT) + velocityParticle.xy);

    //* Position = v * dt + x_0
    vec2 newPosition = (newVelocity * DT) + positionParticle.xy;

    //* Wrap around window edges
    newPosition = wrap(
            newPosition,
            WINDOW_WIDTH,
            WINDOW_HEIGHT
        );

/* DEBUG ((un)comment to toggle)
    if (idx == 0) debugBuffer[0] = POSITION_MOUSE.x;
    if (idx == 0) debugBuffer[1] = POSITION_MOUSE.y;
    if (idx == 0) debugBuffer[2] = DT;
    if (idx == 0) debugBuffer[3] = VELOCITY_DAMPING;
    if (idx == 0) debugBuffer[4] = GRAVITY_FACTOR;
    if (idx == 0) debugBuffer[5] = ACCELERATION_CAP;
    if (idx == 0) debugBuffer[6] = WINDOW_WIDTH;
    if (idx == 0) debugBuffer[7] = WINDOW_HEIGHT;

    if (idx == 0) debugBuffer[9] = positionParticle.x;
    if (idx == 0) debugBuffer[10] = positionParticle.y;
    if (idx == 0) debugBuffer[11] = velocityParticle.x;
    if (idx == 0) debugBuffer[12] = velocityParticle.y;

    if (idx == 0) debugBuffer[14] = distance.x;
    if (idx == 0) debugBuffer[15] = distance.y;
    if (idx == 0) debugBuffer[16] = length;
    if (idx == 0) debugBuffer[17] = direction.x;
    if (idx == 0) debugBuffer[18] = direction.y;

    if (idx == 0) debugBuffer[20] = acceleration.x;
    if (idx == 0) debugBuffer[21] = acceleration.y;
    if (idx == 0) debugBuffer[23] = newVelocity.x;
    if (idx == 0) debugBuffer[24] = newVelocity.y;
    if (idx == 0) debugBuffer[24] = newPosition.x;
    if (idx == 0) debugBuffer[25] = newPosition.y;
//*/

    //* Return new particle data
    particlePositions[idx] = vec4(newPosition, 0, 0);
    particleVelocities[idx] = vec4(newVelocity, 0, 0);
}

vec2 wrap(
    vec2 position,
    float windowWidth,
    float windowHeight
)
{
    vec2 wrapped;
    wrapped.x = mod(position.x, windowWidth);
    wrapped.y = mod(position.y, windowHeight);
    return wrapped;
};
