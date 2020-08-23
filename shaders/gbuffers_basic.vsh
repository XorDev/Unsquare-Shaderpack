#version 120

#define Uncube .2 //"Uncube" distortion level [0. .2 .4 .6 .8 1.]

attribute vec2 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

varying vec4 color;

vec3 hash3(vec3 p)
{
  return fract(cos(p*mat3(-31.14,15.92,65.35,-89.79,-32.38,46.26,43.38,32.79,-02.88))*41.97);
}
vec3 value3(vec3 p)
{
    vec3 f = floor(p);
    vec3 s = p-f; s*= s*s*(3.-s-s);
    const vec2 o = vec2(0,1);
    return mix(mix(mix(hash3(f+o.xxx),hash3(f+o.yxx),s.x),
                   mix(hash3(f+o.xyx),hash3(f+o.yyx),s.x),s.y),
               mix(mix(hash3(f+o.xxy),hash3(f+o.yxy),s.x),
                   mix(hash3(f+o.xyy),hash3(f+o.yyy),s.x),s.y),s.z);
}
vec3 off(vec3 p)
{
    return (value3(p)*.4+value3(p/2.)*.6+value3(p/8.)-1.)*Uncube;
}

void main()
{
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = mat3(gbufferModelViewInverse) * pos  + gbufferModelViewInverse[3].xyz;

    pos += off(pos+cameraPosition);
    vec3 h = pos+cameraPosition;
    pos.y -= off(cameraPosition-vec3(0,1,0)).y;

    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos,1);
    gl_FogFragCoord = length(pos);

    color = gl_Color;
}
