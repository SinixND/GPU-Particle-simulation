#include "RNG.h"
#include <glad.h>
#include <raylib.h>
#include <raymath.h>
#include <rlgl.h>

int const WINDOW_WIDTH{ 800 };
int const WINDOW_HEIGHT{ 800 };
int constexpr FPS_TARGET{ 300 };

int constexpr PARTICLES{ 1024 * 1000 };

//* This equals `G * (m_1 + m_2)` in Newtons law of universal gravitation
float constexpr GRAVITY_FACTOR{ 10E07f };
float constexpr ACCELERATION_CAP{ 10E2f };
float constexpr VELOCITY_DAMPING{ 0.995 };

char const* const vertexShaderPath{ "assets/shaders/particles.vert" };
char const* const fragmentShaderPath{ "assets/shaders/base.frag" };
char const* const computeShaderPath{ "assets/shaders/computeParticles.glsl" };

[[nodiscard]]
Vector2 transformToNormalized(
    Vector2 const positionScreenSpace,
    int windowWidth,
    int windowHeight
);
[[nodiscard]]
Vector2 transformFromNormalized(
    Vector2 const positionNormalizedSpace,
    int windowWidth,
    int windowHeight
);

int main()
{
    //* Particle data (normalized)
    // static Vector4 positions[PARTICLES]{
    //     {-0.4f, -0.3f, 0, 0},
    //     {+0.4f, -0.3f, 0, 0},
    //     {+0.0f, +0.5f, 0, 0}
    // };

    //* Particle data (not normalized)
    static Vector4 positions[PARTICLES]{
        {( 0.5f + ( -0.4f * 0.5f ) ) * WINDOW_WIDTH, ( 0.5f - ( -0.3f * 0.5f ) ) * WINDOW_HEIGHT, 0, 0},
        {( 0.5f + ( +0.4f * 0.5f ) ) * WINDOW_WIDTH, ( 0.5f - ( -0.3f * 0.5f ) ) * WINDOW_HEIGHT, 0, 0},
        {( 0.5f + ( +0.0f * 0.5f ) ) * WINDOW_WIDTH, ( 0.5f - ( +0.5f * 0.5f ) ) * WINDOW_HEIGHT, 0, 0}
    };
    static Vector4 velocities[PARTICLES]{
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    };

    static Vector4 colors[PARTICLES]{
        {1, 0, 0, 1},
        {0, 1, 0, 1},
        {0, 0, 1, 1}
    };

    for ( int idx{ 0 }; idx < PARTICLES; ++idx )
    {
        positions[idx] =
            Vector4{
                ( WINDOW_WIDTH * snx::RNG::random( 0, PARTICLES ) / ( 1.0f * PARTICLES ) ),
                ( WINDOW_HEIGHT * snx::RNG::random( 0, PARTICLES ) / ( 1.0f * PARTICLES ) ),
                0,
                1
            };

        velocities[idx] =
            Vector4{ 0, 0, 0, 0 };

        colors[idx] =
            Vector4{
                snx::RNG::random( 0, 255 ) / 255.0f,
                snx::RNG::random( 0, 255 ) / 255.0f,
                snx::RNG::random( 0, 255 ) / 255.0f,
                .2f
            };
    }

    //* Vertex data
    // clang-format off
    Vector2 vertices[]{
        {+0.0f, +0.0f}
    };
    // clang-format on

    /* Debug data
    [[maybe_unused]]
    float bufferDebug[32]{ 0 };
    //*/

    InitWindow( WINDOW_WIDTH, WINDOW_HEIGHT, "raylib window" );
    SetTargetFPS( FPS_TARGET );

    //* Compute shader program
    char* shaderCode{ LoadFileText( computeShaderPath ) };
    unsigned int shaderData{ rlCompileShader(
        shaderCode,
        RL_COMPUTE_SHADER
    ) };
    unsigned int computeShader{ rlLoadComputeShaderProgram( shaderData ) };
    UnloadFileText( shaderCode );

    //* Pixel shader
    Shader pixelShader{ LoadShader(
        vertexShaderPath,
        fragmentShaderPath
    ) };

    //* SSBOs
    unsigned int ssboParticlePositions{
        rlLoadShaderBuffer(
            PARTICLES * sizeof( Vector4 ),
            positions,
            RL_DYNAMIC_COPY
        )
    };

    unsigned int ssboParticleVelocities{
        rlLoadShaderBuffer(
            PARTICLES * sizeof( Vector4 ),
            velocities,
            RL_DYNAMIC_COPY
        )
    };

    unsigned int ssboParticleColors{
        rlLoadShaderBuffer(
            PARTICLES * sizeof( Vector4 ),
            colors,
            RL_DYNAMIC_COPY
        )
    };

    /* DEBUG
    unsigned int ssboDebug{
        rlLoadShaderBuffer(
            32 * sizeof( Vector4 ),
            bufferDebug,
            RL_DYNAMIC_COPY
        )
    };
    //*/

    //* VAO
    unsigned int vao{ rlLoadVertexArray() };
    rlEnableVertexArray( vao ); // Start editing

    //* VBO
    rlLoadVertexBuffer(
        vertices,
        sizeof( vertices ),
        false
    ); // Returned VBO reference not needed: function generates, binds and fills

    //* Vertex attribute: position
    rlSetVertexAttribute(
        0,
        2,
        RL_FLOAT,
        true,
        2 * sizeof( float ),
        0
    ); // Configure VBO
    rlEnableVertexAttribute( 0 );

    rlDisableVertexArray(); // Stop editing

    //* Render loop
    while ( !WindowShouldClose() )
    {
        float dt{ GetFrameTime() };

        Vector2 mousePosition{ 0, 0 };
        if ( IsMouseButtonDown( MOUSE_BUTTON_LEFT ) )
        {
            mousePosition = GetMousePosition();
        }

        //* Compute shader
        //* -------------
        rlEnableShader( computeShader );

        //* Pass uniforms
        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "POSITION_MOUSE"
            ),
            &mousePosition,
            RL_SHADER_UNIFORM_VEC2,
            1
        );

        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "DT"
            ),
            &dt,
            SHADER_UNIFORM_FLOAT,
            1
        );

        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "VELOCITY_DAMPING"
            ),
            &VELOCITY_DAMPING,
            SHADER_UNIFORM_FLOAT,
            1
        );

        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "GRAVITY_FACTOR"
            ),
            &GRAVITY_FACTOR,
            SHADER_UNIFORM_FLOAT,
            1
        );

        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "ACCELERATION_CAP"
            ),
            &ACCELERATION_CAP,
            SHADER_UNIFORM_FLOAT,
            1
        );

        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "WINDOW_WIDTH"
            ),
            &WINDOW_WIDTH,
            SHADER_UNIFORM_INT,
            1
        );

        rlSetUniform(
            rlGetLocationUniform(
                computeShader,
                "WINDOW_HEIGHT"
            ),
            &WINDOW_HEIGHT,
            SHADER_UNIFORM_INT,
            1
        );

        //* Pass buffers
        rlBindShaderBuffer( ssboParticlePositions, 0 );
        rlBindShaderBuffer( ssboParticleVelocities, 1 );
        /* DEBUG
        rlBindShaderBuffer( ssboDebug, 2 );
        //*/

        //* Execute compute shader
        rlComputeShaderDispatch( PARTICLES / 1024, 1, 1 );

        rlDisableShader();

        /* Debug
        rlReadShaderBuffer( ssboDebug, bufferDebug, 32 * sizeof( float ), 0 );
        //*/

        //* Render
        //* ------
        BeginDrawing();
        ClearBackground( BLACK );
        //* Pixel shader
        //* ------------
        rlEnableShader( pixelShader.id );

        rlSetUniform(
            rlGetLocationUniform(
                pixelShader.id,
                "WINDOW_WIDTH"
            ),
            &WINDOW_WIDTH,
            SHADER_UNIFORM_INT,
            1
        );
        rlSetUniform(
            rlGetLocationUniform(
                pixelShader.id,
                "WINDOW_HEIGHT"
            ),
            &WINDOW_HEIGHT,
            SHADER_UNIFORM_INT,
            1
        );

        rlEnableVertexArray( vao );

        rlBindShaderBuffer( ssboParticlePositions, 0 );
        rlBindShaderBuffer( ssboParticleColors, 1 );
        rlBindShaderBuffer( ssboParticleColors, 2 );

        //* Draw triangle as points
        //* Enable vertex scaling in vertex shader
        rlEnablePointMode();

        //* raylib does not support glDrawArraysInstanced with GL_POINTS mode
        glDrawArraysInstanced(
            GL_POINTS,
            0,
            sizeof( vertices ) / sizeof( vertices[0] ),
            PARTICLES
        );

        rlDisablePointMode();

        rlDisableVertexArray();
        rlDisableShader();

        DrawFPS( 10, 10 );
        DrawText( TextFormat( "N=%d", PARTICLES ), 10, 30, 20, DARKGRAY );

        EndDrawing();
    }

    //* Close: free all resources
    rlUnloadVertexArray( vao );
    UnloadShader( pixelShader );
    rlUnloadShaderProgram( computeShader );

    CloseWindow();

    return 0;
}

Vector2 transformToNormalized(
    Vector2 const positionScreenSpace,
    int windowWidth,
    int windowHeight
)
{
    return Vector2{
        ( positionScreenSpace.x - windowWidth / 2.0f ) / ( windowWidth / 2.0f ),
        ( positionScreenSpace.y - windowHeight / 2.0f ) / ( -1 * windowHeight / 2.0f )
    };
}

Vector2 transformFromNormalized(
    Vector2 const positionNormalizedSpace,
    int windowWidth,
    int windowHeight
)
{
    return Vector2{
        ( positionNormalizedSpace.x * ( windowWidth / 2.0f ) + windowWidth / 2.0f ),
        ( positionNormalizedSpace.y * ( -1 * windowHeight / 2.0f ) + windowHeight / 2.0f )
    };
}
