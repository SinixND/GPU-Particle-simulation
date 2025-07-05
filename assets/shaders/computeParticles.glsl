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

layout(location = 0) uniform vec2 POSITION_MOUSE;
layout(location = 1) uniform float DT;
layout(location = 2) uniform float VELOCITY_DAMPING;
layout(location = 3) uniform float GRAVITY_FACTOR;
layout(location = 4) uniform float ACCELERATION_CAP;

vec2 wrap(vec2 position);

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
    //* this becomes {-1, 1}
    if ((POSITION_MOUSE.x == -1) && (POSITION_MOUSE.y == 1))
    {
        acceleration = vec2(0, 0);
    }

    //* Velocity = vel_damp * (a * dt) + v_0
    vec2 newVelocity = ((acceleration * DT) + (VELOCITY_DAMPING * velocityParticle.xy));

    //* Position = v * dt + x_0
    vec2 newPosition = (newVelocity * DT) + positionParticle.xy;

    //* Wrap around window edges
    newPosition = wrap(newPosition);

    //* Return new particle data
    particlePositions[idx] = vec4(newPosition, 0, 0);
    particleVelocities[idx] = vec4(newVelocity, 0, 0);
}

vec2 wrap(vec2 position) {
    vec2 wrapped;
    wrapped.x = -1.0 + mod(position.x + 1.0, 2.0);
    wrapped.y = -1.0 + mod(position.y + 1.0, 2.0);
    return wrapped;
};
