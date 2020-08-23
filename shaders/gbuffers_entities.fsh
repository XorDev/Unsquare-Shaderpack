#version 130

#define Shininess 1. //Water shine intensity [.0 .5 1.]

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform mat4 gbufferModelViewInverse;
uniform vec4 entityColor;
uniform vec3 shadowLightPosition;
uniform vec3 skyColor;
uniform ivec2 atlasSize;
uniform float blindness;
uniform int isEyeInWater;

varying vec4 color;
varying vec3 world;
varying vec3 vert;
varying vec2 coord0;
varying vec2 coord1;
varying float id;

vec2 hash2(vec2 p)
{
    return fract(cos(p*mat2(85.6,-69.3,74.8,-81.2))*475.);
}
/*vec2 value2(vec2 p)
{
    vec2 f = floor(p);
    vec2 s = p-f;

    vec2 o = vec2(0,1);
    return mix(mix(hash2(f+o.xx),hash2(f+o.yx),s.x),
               mix(hash2(f+o.xy),hash2(f+o.yy),s.x),s.y);
}*/
vec2 voronoi(vec2 p,vec2 s)
{
    float d = 2.;
    vec2 off = vec2(.5);
    vec2 f = floor(p);

    for(float i = -1.;i<=1.;i++)
    for(float j = -1.;j<=1.;j++)
    {
        vec2 o = (hash2(f+s+vec2(i,j))-.5)+f+.5+vec2(i,j)-p;
        float t = length(o);
        if (d>t)
        {
            d = t;
            off = f+.5+vec2(i,j);
        }
    }
    return off;
}
vec2 off(vec2 p,vec3 s)
{
    return voronoi(p,s.xy+s.yz);
}

void main()
{
    vec3 dir = normalize((gbufferModelViewInverse * vec4(shadowLightPosition,0)).xyz);
    float flip = clamp(dir.y/.1,-1.,1.); dir *= flip;
    vec3 norm = normalize(cross(dFdx(world),dFdy(world)));
    float lambert = dot(norm,dir)*.5+.5;//(id>1.5)?dir.y*.5+.5:dot(norm,dir)*.5+.5;

    //float sun = exp((dot(reflect(normalize(world),norm),dir)-1.)*15.*(1.5-.5*flip));
    //vec4 shine = vec4(vec3(sun)*flip*flip,0)*Shininess*step(.9,id)*step(id,1.1);

    float fog = (isEyeInWater>0) ? 1.-exp(-gl_FogFragCoord * gl_Fog.density):
    clamp((gl_FogFragCoord-gl_Fog.start) * gl_Fog.scale, 0., 1.);
    vec3 shad = mix(skyColor*.5+.2,vec3(1),lambert) * texture2D(lightmap,coord1).rgb;

    vec2 res = vec2(textureSize(texture,0));
    vec2 cell = coord0*res;
    vec2 floo = floor(cell);
    vec2 mi = floor(floo/16.)*16.;
    vec2 ma = mi+15.;
    vec3 dif = floor(vert);
    vec2 shift = off(cell,dif);
    vec2 off1 = clamp(shift,mi,ma)/res;
    //vec2 off2 = clamp(cell*2.-shift,mi,ma)/res;

    vec2 gx = dFdx(coord0);
    vec2 gy = dFdy(coord0);
    vec4 col = textureGrad(texture,off1,gx,gy);
    //if (id<1.5) col = mix(textureGrad(texture,coord0,gx,gy),col,col.a);
    col.a = min(textureGrad(texture,coord0,gx,gy).a,col.a);
    col *= color * vec4(shad*(1.-blindness),1);// + shine;
    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);
    col.rgb = mix(col.rgb,entityColor.rgb,entityColor.a);
    gl_FragData[0] = col;
}
