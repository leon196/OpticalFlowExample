
// uniforms are sent from cpu
// this is built-in values from Processing
uniform mat4 transform;
uniform mat4 texMatrix;

// attributes are value attached to vertex
attribute vec4 vertex;
attribute vec4 color;
attribute vec2 texCoord;

// varyings are interpolated values send to fragment shader
varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() 
{
	// vertex color
  vertColor = color;

  // textures coordinates
  vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);

	// get position from projection matrix
  gl_Position = transform * vertex;
}