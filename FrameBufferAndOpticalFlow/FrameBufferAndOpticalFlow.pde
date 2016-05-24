import gab.opencv.*;
import processing.video.*;

OpenCV opencv;
Movie video;

// resolution
int videoWidth = 256;
int videoHeight = 256;
int levelOfDetails = 2;

// shader
PImage motionTexture;
PShader shaderBuffer;

// frame buffer
PGraphics[] renderArray;
int currentRender;

// ux
boolean shouldUpdateBufferWithVideo = true;
boolean shouldDrawLines = true;
boolean shouldDrawMotionTexture = false;

void setup ()
{
  // setup 3D context
  size(512, 512, P3D);
  colorMode(RGB, 1, 1, 1);
  stroke(255, 255, 255);
  strokeWeight(1);
  textSize(16);

  // video
  video = new Movie(this, "videos/sample.avi");
  video.loop();
  video.play();

  // set frame rate to half video fps (dirty fix for smoothing fast cpu calculations)
  frameRate(15);

  // openCV
  opencv = new OpenCV(this, videoWidth, videoHeight);

  // texture used to send vector to shader
  motionTexture = createImage(videoWidth / levelOfDetails, videoHeight / levelOfDetails, RGB);

  // load shader
  shaderBuffer = loadShader("shaders/Buffer.frag", "shaders/Simple.vert");

  // setup frame buffer
  renderArray = new PGraphics[2];
  currentRender = 0;
  for (int i = 0; i < renderArray.length; ++i)
  {
    // PGraphics is like a render texture
    renderArray[i] = createGraphics(width, height, P3D);

    // initialize pixels
    renderArray[i].beginDraw();
    renderArray[i].background(0);
    renderArray[i].endDraw();

    // nearest filter mode
    ((PGraphicsOpenGL)renderArray[i]).textureSampling(2);
  }
}

void keyTyped ()
{
  // press space to stop filling the buffer with video
  if (key == ' ')   {
    shouldUpdateBufferWithVideo = !shouldUpdateBufferWithVideo;
  } else if (key == 'l')   {
    shouldDrawLines = !shouldDrawLines;
  } else if (key == 'm')   {
    shouldDrawMotionTexture = !shouldDrawMotionTexture;
  }
}

void draw()
{
  // clear
  background(0);

  // this is where the openCV magic happen
  opencv.loadImage(video);
  opencv.calculateOpticalFlow();

  /////////////////////////

  // init texture
  motionTexture.loadPixels();

  // iterate through all pixels
  for (int x = 0; x < motionTexture.width; ++x )
  {
    for (int y = 0; y < motionTexture.height; ++y)
    {
      // get the vector motion from openCV
      PVector motion = opencv.getFlowAt(x * levelOfDetails, y * levelOfDetails);

      // normalize vector
      PVector direction = getNormal(motion.x, motion.y);

      // get index array from 2d position
      int index = x + y * motionTexture.width;

      // encode vector into a color
      colorMode(RGB, 1, 1, 1);
      motionTexture.pixels[index] = color(direction.x * 0.5 + 0.5, direction.y * 0.5 + 0.5, min(1, motion.mag()));

      if (shouldDrawLines)
      {
        // origin point
        float ax = x * width / float(motionTexture.width);
        float ay = y * height / float(motionTexture.height);

        // head vector point
        float bx = ax + motion.x;
        float by = ay + motion.y;

        // color from angle
        colorMode(HSB, 1, 1, 1);
        stroke(atan2(direction.y, direction.x) / PI * 0.5 + 0.5, 1, 1);

        // draw line
        line(ax, ay, bx, by);
      }
    }
  }

  // apply change
  motionTexture.updatePixels();

  /////////////////////////

  // the frame buffer magic happen here
  PGraphics bufferWrite = getCurrentRender();
  nextRender();
  PGraphics bufferRead = getCurrentRender();

  // start recording render texture
  bufferWrite.beginDraw();

  // set uniforms to shaders
  shaderBuffer.set("frame", bufferRead);
  shaderBuffer.set("motion", motionTexture);

  if (shouldDrawMotionTexture)
  {
    // display motion map
    bufferWrite.resetShader();
    bufferWrite.image(motionTexture, 0, 0, width, height);
  }
  else if (shouldUpdateBufferWithVideo)
  {
    // refill buffer with video
    bufferWrite.resetShader();
    bufferWrite.image(video, 0, 0, width, height);
  }
  else
  {
    // apply pixel displacement with shader
    bufferWrite.shader(shaderBuffer);
    bufferWrite.rect(0, 0, width, height);
  }

  // end of recording render texture
  bufferWrite.endDraw();

  /////////////////////////

  // draw final render
  image(bufferWrite, 0, 0, width, height);

  // draw info texts
  colorMode(RGB, 1, 1, 1);
  stroke(255, 255, 255);
  text("press Space to toggle video update", 8, height - 40);
  text("press L to toggle line display", 8, height - 24);
  text("press M to toggle motion texture display", 8, height - 8);
}

// the current frame buffer
PGraphics getCurrentRender () {
  return renderArray[currentRender];
}

// swap between writing frame and reading frame
void nextRender () {
  currentRender = (currentRender + 1) % renderArray.length;
}

// return normalized vector
PVector getNormal (float x, float y) {
  float dist = sqrt(x*x+y*y);
  return new PVector(x / dist, y / dist);
}

// Processing event to play video
void movieEvent(Movie m)
{
  m.read();
}