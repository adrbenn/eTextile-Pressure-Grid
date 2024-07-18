/**************************************************************
eTextile Pressure Grid

Real time visualization and data collection

Last update: 25 June 2024
**************************************************************/

import peasy.*;
PeasyCam cam;

import processing.serial.*;
Serial arduPort;

// grid setting
int num_hori = 10; // no of horisontal lines (digital pins)
int num_vert = 9; // no of vertical lines (analog pins)
int gridSize = num_hori * num_vert; // total no of cells

int cellHeight = 20; // cell size in pixel
int cellWidth = 20; // cell size in pixel

int gridHeight = cellHeight * num_hori; // grid size in pixels
int gridWidth = cellWidth * num_vert;  // grid size in pixels


// data variables left grid
int[] LrawValues = new int[gridSize]; // raw sensor reading data from Arduino
int[] Lbaseline = new int[gridSize]; // stored baseline values to offset untouched sensor reading
int[] LpressValues = new int[gridSize]; // actual pressure data: raw reading - baseline

// data variables right grid
int[] RrawValues = new int[gridSize]; // raw sensor reading data from Arduino
int[] Rbaseline = new int[gridSize]; // stored baseline values to offset untouched sensor reading
int[] RpressValues = new int[gridSize]; // actual pressure data: raw reading - baseline

// NOTE:
// The Arduino stream message is in one long string
// e.g. {(row1, col1), (row1, col2), (row2, col1), (row2, col2)}
// Left grid then right grid
 
// display setting
boolean showNumbers = true;

// test setting
boolean useDummyData = true;

// write to file
String filename = "norecording.csv";
boolean isRecording = false;
int startRecordingTime = 0;
Table dataBuffer = new Table();
TableRow newRow;

/* -------------------------- SETUP -------------------------- */
void setup() {
  // initiate serial connection 
  
  // use the following line to check the available serial connections
  printArray(Serial.list());
  // if needed, change the number in list()[3] below to the appropriate number 
  // of where the Arduino is connected to your computer
  if(!useDummyData){
    arduPort = new Serial(this, Serial.list()[5], 9600);
  }
  
  // initiate grid
  size(800,600,P3D);
  cam = new PeasyCam(this, 500);
  cam.setMinimumDistance(100);
  cam.setMaximumDistance(1000);
  
  
  // initiate baseline
  for (int i = 0; i < gridSize; i++) {
    Lbaseline[i] = 0;
    Rbaseline[i] = 0;
  }

  // initiate dataBuffer table;
  initDataBuffer();
  
  // some delay just to make sure things got initiated properly
  println("3..."); delay(1000);
  println("2..."); delay(1000);
  println("1..."); delay(1000);
  println("Hello");
}

/* -------------------------- DRAW -------------------------- */
void draw() {
  if(useDummyData){
    dummyValuesForTesting();
  }
  
  background(255);
  coordinateDraw(); // draw the base grid
  dataDraw(); // draw the data bars
 
}

/* ------------------ Draw the 3D grid ------------------ */
void coordinateDraw(){
  rotateX(-.001);
  rotateY(-.001);
  background(255);
  translate(0,0,0);
  
  // X axis Right
  stroke(0,100,0); 
  line(0, 0, 0, gridWidth, 0, 0);
  fill(0,100,0);
  text("X Axis",gridWidth-10,-5,0);  
  
  // X axis Left
  stroke(0,100,0); 
  line(0, 0, 0, gridWidth * -1, 0, 0);
  fill(0,100,0);
  text("X Axis",(gridWidth * -1) + 10,-5,0);  
  
  // Y axis
  stroke(255,0,0);
  line(0, 0, 0, 0, gridHeight, 0);
  pushMatrix();
  rotate(-HALF_PI);
  fill(255,0,0);
  text("Y Axis",-(gridHeight+30),-5,0);
  popMatrix();

  // grid line Z axis (up)
  stroke(200);
  for (int i = 0; i < 4; i++){
    // to the right
    line(0, 0, 20*(i+1), 180, 0, 20*(i+1));
    // to the left
    line(0, 0, 20*(i+1), -180, 0, 20*(i+1));
    // to y
    line(0, 0, 20*(i+1), 0, 200, 20*(i+1));
  }

  // Z axis / pressure strength
  stroke(0,0,255);
  line(0, 0, 0, 0, 0, 140);
  pushMatrix();
  rotateY(-HALF_PI);
  fill(0,0,255);
  text("Pressure",125,-5,0);
  popMatrix();

}

/* ------------------ Draw the data bars ------------------ */
void dataDraw(){
  
  int readIndex = 0;
  
  // Begin loop for colums
  for(int h = 0; h < num_hori; h++){
    // Begin loop for rows
    for(int v = 0; v < num_vert; v++){
        
        // LEFT GRID        
        float LdrawHeight=map(LpressValues[readIndex], 0, 1023, 0, 200);
        float LdrawColor=map(LpressValues[readIndex], 0, 1023, 0, 255);
        
        pushMatrix();
       
        if(LpressValues[readIndex]<3){
          // if the value is low, make it grey
          fill(200);
        } else {
          // else have a gradient between green to red
          fill(LdrawColor,255-LdrawColor,0);
        }
        
        stroke(100);
        translate(cellWidth*(v+0.5)-gridWidth, cellHeight*(h+0.5), LdrawHeight/2);
        box(cellWidth, cellHeight, LdrawHeight);
        
        // display the number as text
        if(showNumbers){
          fill(0); // text color
          textSize(8);
          text(int(LpressValues[readIndex]), -5, 5, LdrawHeight/2+1);
        }
        popMatrix();
      
        // RIGHT GRID        
        float RdrawHeight=map(RpressValues[readIndex], 0, 1023, 0, 200);
        float RdrawColor=map(RpressValues[readIndex], 0, 1023, 0, 255);
        
        pushMatrix();
        
        if(RpressValues[readIndex]<3){
          // if the value is low, make it grey
          fill(200);
        } else {
          // else have a gradient between green to red
          fill(RdrawColor,255-RdrawColor,0);
        }
        
        stroke(100);
        translate(cellWidth*(v+0.5), cellHeight*(h+0.5), RdrawHeight/2);
        box(cellWidth, cellHeight, RdrawHeight);
        
        // display the number as text
        if(showNumbers){
          fill(0); // text color
          textSize(8);
          text(int(RpressValues[readIndex]), -5, 5, RdrawHeight/2+1);
        }
        popMatrix();
        
        readIndex++;
    }
  }
  
}


/* ------------------ Dummy data for testing purpose ------------------ */
void dummyValuesForTesting(){
  
  // dummy message
  String receivedMsg = "";
  
  // left grid
  for(int i = 0; i < gridSize; i++){
    receivedMsg = receivedMsg + (second() + i*5) + "x";
  }
  
  receivedMsg = receivedMsg + "z";
  
  // right grid
  for(int i = 0; i < gridSize; i++){
    receivedMsg = receivedMsg + (second() + i*5) + "x";
  }
  //println(receivedMsg);
  
  
  // Split the message L and R
  String[] twoGrids = split(receivedMsg, 'z');
  
  LrawValues = int(split(twoGrids[0], 'x'));
  for (int i = 0; i < (gridSize); i++){ 
    LpressValues[i] = LrawValues[i] - Lbaseline[i]; 
  }
  
  RrawValues = int(split(twoGrids[1], 'x'));
  for (int i = 0; i < (gridSize); i++){ 
    RpressValues[i] = RrawValues[i] - Rbaseline[i]; 
  }
  
  // If recording in progress, add data to buffer
  if(isRecording){
    addBufferRow();
  }
}

/* --------------------- Receive data from Arduino --------------------- */
void serialEvent(Serial p){
  String receivedMsg = arduPort.readStringUntil('\n');
  if(receivedMsg!=null){
    //print("Message received: "); println(receivedMsg);
    
    // Split the message L and R
    String[] twoGrids = split(receivedMsg, 'z');
    
    LrawValues = int(split(twoGrids[0], 'x'));
    for (int i = 0; i < (gridSize); i++){ 
      LpressValues[i] = LrawValues[i] - Lbaseline[i];
      
    }
    
    RrawValues = int(split(twoGrids[1], 'x'));
    for (int i = 0; i < (gridSize); i++){ 
      RpressValues[i] = RrawValues[i] - Rbaseline[i]; 
       
    }

    
    // If recording in progress, add data to buffer
    if(isRecording){
      addBufferRow();
    }
    
  }
}


/* --------------------- Initiate data buffer table ---------------------- */
void initDataBuffer(){
  // initiate dataBuffer table;
  dataBuffer.addColumn("id");
  dataBuffer.addColumn("time");
  //for (int i = 0; i < gridSize; i++) {
  //  dataBuffer.addColumn("LrawValues"+i);
  //}
  for (int i = 0; i < gridSize; i++) {
    dataBuffer.addColumn("Lbaseline"+i);
  }
  for (int i = 0; i < gridSize; i++) {
    dataBuffer.addColumn("LpressValues"+i);
  }
  
  //for (int i = 0; i < gridSize; i++) {
  //  dataBuffer.addColumn("RrawValues"+i);
  //}
  for (int i = 0; i < gridSize; i++) {
    dataBuffer.addColumn("Rbaseline"+i);
  }
  for (int i = 0; i < gridSize; i++) {
    dataBuffer.addColumn("RpressValues"+i);
  }
}

/* --------------------- Record data to buffer ---------------------- */
void addBufferRow(){
  newRow = dataBuffer.addRow();
  newRow.setInt("id", dataBuffer.lastRowIndex());
  newRow.setInt("time", millis()-startRecordingTime);
  
  //for (int i = 0; i < gridSize; i++) {
  //  newRow.setInt("LrawValues"+i, LrawValues[i]);
  //}
  for (int i = 0; i < gridSize; i++) {
    newRow.setInt("Lbaseline"+i, Lbaseline[i]);
  }
  for (int i = 0; i < gridSize; i++) {
    newRow.setInt("LpressValues"+i, LpressValues[i]);
  }
  //for (int i = 0; i < gridSize; i++) {
  //  newRow.setInt("RrawValues"+i, RrawValues[i]);
  //}
  for (int i = 0; i < gridSize; i++) {
    newRow.setInt("Rbaseline"+i, Rbaseline[i]);
  }
  for (int i = 0; i < gridSize; i++) {
    newRow.setInt("RpressValues"+i, RpressValues[i]);
  }
}


/* --------------------- Keyboard shortcuts ---------------------- */

// b -> calibrate sensor reading baseline
// p -> start recording data
// o -> stop recording data and save the file

void keyPressed() {
  
  if (key == 'b' || key == 'B'){              // Press B to calibrate the sensor baseline
                                                    
    println("Calibrating baseline...");
    for (int i = 0; i < gridSize; i++) {
      Lbaseline[i] = LrawValues[i];
      Rbaseline[i] = RrawValues[i];
    }
    delay(1000);
    println("Sensor baseline calibrated");
  
  } else if (key == 'o' || key == 'O'){      // Press O to stop recording data and save to file
  
    if(!isRecording){
      println("No recording in progress. Press P to start recording data.");
    } else {
      String savePath = "data/" + filename;
      println("Stop recording. Saving to " + savePath + " ... ");
      
      // save table to file
      saveTable(dataBuffer, savePath);
      
      // clear databuffer
      dataBuffer.clearRows(); // just in case
      
      isRecording = false;
      
      delay(2000); // just in case
      println("File saved.");
      
    }
  
  } else if (key == 'p' || key == 'P'){      // Press P to start recording data
  
    if(isRecording){
      println("Recording in progress!");
    } else {
      
      println("Start recording in ... ");
      println("3..."); delay(1000);
      
      int s = second();  // Values from 0 - 59
      int mi = minute();  // Values from 0 - 59
      int h = hour();    // Values from 0 - 23
      int d = day();    // Values from 1 - 31
      int mo = month();  // Values from 1 - 12
      int y = year();   // 2003, 2004, 2005, etc.
      
      filename = "PressureData-" + str(y) + str(mo) + str(d)+ "-" + str(h)+ "-" + str(mi)+ "-" + str(s) + ".csv";
      
      println("2..."); delay(1000);
      println("1..."); delay(1000);
      
      dataBuffer.clearRows(); // clear databuffer, just in case
      startRecordingTime = millis();
      isRecording = true;
      
      println("Recording started! Press O to stop and save to file.");
      
    }
    
    
  } 

} // end keyPressed()
