#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer CubeConstants
{
    int cube_edges[24];
    int edge_table[256];
}
CUBE_CONSTANTS;

// Return values

layout(set = 1, binding = 1, std430) restrict buffer VertexData
{
    float data[];
}
vertex_data;

layout(set = 2, binding = 2, std430) restrict buffer FaceData
{
    float data[];
}
face_data;

// The code we want to execute in each invocation
void main()
{
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    vertex_data.data[gl_GlobalInvocationID.x] *= 2.0;
}
