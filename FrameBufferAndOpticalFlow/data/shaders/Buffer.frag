
// for embded OpenGL
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// textures send from Processing main script
uniform sampler2D motion;
uniform sampler2D frame;

// interpolated values from vertex shader
varying vec4 vertColor;
varying vec4 vertTexCoord;

void main()
{
	// get motion and video colors
	vec4 motionColor = texture2D(motion, vertTexCoord.st);

	// fix uv inversion
	vec2 uv = vertTexCoord.st;
	uv.y = 1.0 - uv.y;

	// extract angle from color
	float angle = atan(motionColor.g * 2.0 - 1.0, motionColor.r * 2.0 - 1.0);

	// create offset with angle and vector magnitude
	vec2 offset = vec2(cos(angle), sin(angle)) * motionColor.b * 0.01;

	// apply uv displacement
	vec4 framebufferColor = texture2D(frame, uv - offset);

	// assign color
  gl_FragColor = framebufferColor;
}
