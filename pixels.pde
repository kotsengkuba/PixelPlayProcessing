/*
  from left to right, send midi based on RGB values except when brightness is low
*/


import processing.video.*;
import themidibus.*;
import java.util.*;

// Size of each cell in the grid
int videoScale = 7;
// Number of columns and rows in the system
int cols, rows;
// Variable for capture device
Capture video;
String[] cameras = Capture.list();

// midi bus
MidiBus myBus; // The MidiBus 

// beat count reference
int beatCtr = 0;
int delay = 200; // delay in millis
int columnIndex = 0;
int columnIndex_g = 0;
int columnIndex_b = 0;

// experimental value for testing

float columnRed = 0;
float columnGreen = 0;
float columnBlue = 0;

int[] noteValues = {60, 67, 72};
int[] noteStates = {0, 0, 0};
int noteLimit = 10;

void setup() {
  size(1280, 720);
  fullScreen();
  
  cols = width / videoScale;
  rows = height / videoScale;
    
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    video = new Capture(this, cols, rows, cameras[0]);
    video.start(); 
    
    System.out.println("video started");
  }
  
  MidiBus.list();
  myBus = new MidiBus(new java.lang.Object(), -1, "loopMIDI Port");
}

void captureEvent(Capture video) {
  video.read();
}

void draw() {
  //background(0);
  video.loadPixels();
  
  int m = millis(); // gets the time
  
  for (int i = 0; i < cols; i++) {
  // Begin loop for rows
    for (int j = 0; j < rows; j++) {
      // Where are you, pixel-wise?
      int x = i*videoScale;
      int y = j*videoScale;

      int loc = i + j * video.width;

      color c = video.pixels[loc];
      // A rectangle's size is calculated as a function of the pixel’s brightness.
      // A bright pixel is a large rectangle, and a dark pixel is a small one.
      float sz = (brightness(c)/255) * videoScale;

      rectMode(CENTER);
      fill(255);
      noStroke();
      rect(x + videoScale/2, y + videoScale/2, sz, sz);
    }
  }
  
  if((m / delay) > beatCtr) {  
    columnRed = getColumnRed(columnIndex);
    columnGreen = getColumnGreen(columnIndex_g);
    columnBlue = getColumnBlue(columnIndex_b);

    
    int channel = 0;
    int velocity = 127;
    if(columnGreen > 100 && columnGreen > columnRed + 10) {
      if(noteStates[0] == 0) {
        myBus.sendNoteOn(channel, noteValues[0], velocity); // Send a Midi noteOn
        noteStates[0] = 1;
        System.out.println("note 0");
      } else if (noteStates[1] == 0) {
        myBus.sendNoteOn(channel, noteValues[1], velocity); // Send a Midi noteOn
        noteStates[1] = 1;
        System.out.println("note 1");
      } else if (noteStates[2] == 0) {
        myBus.sendNoteOn(channel, noteValues[2], velocity); // Send a Midi noteOn
        noteStates[2] = 1;
        System.out.println("note 2");
      }
    }
    for(int i = 0; i<3; i++){
      if(noteStates[i] > 0) noteStates[i]++;
      if(noteStates[i] > noteLimit) {
        myBus.sendNoteOff(channel, noteValues[i], velocity); // Send a Midi noteOff
        noteStates[i] = 0;
        System.out.println("note " + i + " off");
      }
    }
    
    color paintRed = color(columnRed, 0, 0);    
    rectMode(CENTER);
    fill(paintRed);
    noStroke();
    rect(columnIndex*videoScale, height/2, 50, height);
    
    color paintGreen = color(0, columnGreen, 0);    
    rectMode(CENTER);
    fill(paintGreen);
    noStroke();
    rect(columnIndex_g*videoScale, height/2, 50, height);
    
    color paintBlue = color(0, 0, columnBlue);    
    rectMode(CENTER);
    fill(paintBlue);
    noStroke();
    rect(columnIndex_b*videoScale, height/2, 50, height);
    
    beatCtr++;
    columnIndex+=random(50);
    if(columnIndex >= cols) {
      columnIndex = 0;
    }
    
    columnIndex_g+=random(50);
    if(columnIndex_g >= cols) {
      columnIndex_g = 0;
    }
    
    columnIndex_b+=random(50);
    if(columnIndex_b >= cols) {
      columnIndex_b = 0;
    }
  } 
  
  
  
  /*rectMode(CENTER);
  fill(255);
  noStroke();
  rect((width/2)-(255*2), height/2-(255*2), testVal, testVal);
  
  rectMode(CENTER);
  fill(255, 0, 0);
  noStroke();
  rect((width/2)-(255), height/2-(255), frameR, frameR);
  
  rectMode(CENTER);
  fill(0, 255, 0);
  noStroke();
  rect((width/2)+(255), height/2+(255), frameG, frameG);
  
  rectMode(CENTER);
  fill(0, 0, 255);
  noStroke();
  rect((width/2)+(255*2), height/2+(255*2), frameB, frameB);*/
  
}

int getFrameBrightness() {
  int runningSum = 0;
  
  // Begin loop for columns
  for (int i = 0; i < cols; i++) {
    // Begin loop for rows
    for (int j = 0; j < rows; j++) {
      int loc = i + j * video.width;
      color c = video.pixels[loc];
      runningSum += brightness(c);
    }
  }
  
  return runningSum/(cols*rows);
}

int getFrameRed() {
  int runningSum = 0;
  
  // Begin loop for columns
  for (int i = 0; i < cols; i++) {
    // Begin loop for rows
    for (int j = 0; j < rows; j++) {
      // Reverse the column to mirro the image.
      int loc = (video.width - i - 1) + j * video.width;

      color c = video.pixels[loc];
      runningSum += red(c);
    }
  }
  
  return runningSum/(cols*rows);
}


float getColumnRed(int index) {
  //int runningSum = 0;
  float runningMean = 0;
  
  for (int j = 0; j < rows; j++) {
    // Reverse the column to mirro the image.
    int loc = index + (j * cols);
    color c = video.pixels[loc];
    //runningSum += red(c);
    //runningMean = ((runningMean * (j+1)) + red(c))/(j+1);
  }
  
  return video.pixels[index] >> 16 & 0xFF; // Very fast to calculate ;
}

float getColumnGreen(int index) {
  //int runningSum = 0;
  float runningMean = 0;
  
  for (int j = 0; j < rows; j++) {
    // Reverse the column to mirro the image.
    int loc = index + (j * cols);
    color c = video.pixels[loc];
    //runningSum += red(c);
    //runningMean = ((runningMean * (j+1)) + red(c))/(j+1);
  }
  
  return video.pixels[index] >> 8 & 0xFF; // Very fast to calculate ;
}

float getColumnBlue(int index) {
  //int runningSum = 0;
  float runningMean = 0;
  
  for (int j = 0; j < rows; j++) {
    // Reverse the column to mirro the image.
    int loc = index + (j * cols);
    color c = video.pixels[loc];
    //runningSum += red(c);
    //runningMean = ((runningMean * (j+1)) + red(c))/(j+1);
  }
  
  return video.pixels[index] & 0xFF; // Very fast to calculate ;
}

int getFrameBlue() {
  int runningSum = 0;
  
  // Begin loop for columns
  for (int i = 0; i < cols; i++) {
    // Begin loop for rows
    for (int j = 0; j < rows; j++) {
      // Reverse the column to mirro the image.
      int loc = (video.width - i - 1) + j * video.width;

      color c = video.pixels[loc];
      runningSum += blue(c);
    }
  }
  
  return runningSum/(cols*rows);
}

int getFrameGreen() {
  int runningSum = 0;
  
  // Begin loop for columns
  for (int i = 0; i < cols; i++) {
    // Begin loop for rows
    for (int j = 0; j < rows; j++) {
      // Reverse the column to mirro the image.
      int loc = (video.width - i - 1) + j * video.width;

      color c = video.pixels[loc];
      runningSum += green(c);
    }
  }
  
  return runningSum/(cols*rows);
}

void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);
}

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
