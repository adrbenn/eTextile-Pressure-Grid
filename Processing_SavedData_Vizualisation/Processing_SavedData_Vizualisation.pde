/**************************************************************
eTextile Pressure Grid

Saved data visualization

Last update: 25 June 2024
**************************************************************/

import peasy.*;
PeasyCam cam;

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

 
// display setting
boolean showNumbers = true;

// saved data buffer
Table savedDataBuffer;

boolean isDataLoaded = false;
boolean readyToDraw = false;
int loadStartTime = 0;


/* -------------------------- SETUP -------------------------- */
void setup() { 
  // initiate grid
  size(800,600,P3D);
  cam = new PeasyCam(this, 500);
  cam.setMinimumDistance(100);
  cam.setMaximumDistance(1000);
  
  
  // initiate displayed values (only the pressValues, not the raw and baseline)
  for (int i = 0; i < gridSize; i++) {
    LpressValues[i] = 0;
    RpressValues[i] = 0;
  }
  
  println("Hello"); delay(1000);
  println("Press O to open a saved file.");
  println("The file has to be in /data/ folder of this Processing file.");

}

/* -------------------------- DRAW -------------------------- */
void draw() {

  background(255);
  coordinateDraw(); // draw the base grid
  
  if(!readyToDraw){
    drawBlank();
  } else {  
    dataDraw(); // draw the data bars
  
  }
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
       
        if(LpressValues[readIndex]<2){
          // if the value is zero, just make it grey
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
        
        if(RpressValues[readIndex]<2){
          // if the value is zero, just make it grey
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

/* --------------------- Draw empty screen ---------------------- */

void drawBlank(){
  
  pushMatrix();
  fill(0);  // text color
  textSize(20);
  text("Press O to open a saved file.", -200, -60, 0);
  text("The file has to be in /data/ folder of this Processing file.", -200, -40, 0);
  popMatrix();
}

/* --------------------- Keyboard shortcuts ---------------------- */
// o -> open a file

void keyPressed() {
 
  if (key == 'o' || key == 'O'){      // Press O to open a saved file
    selectInput("Select a file to process:", "fileSelected");
  }
  
}


/* -------------------------- OPEN FILE -------------------------- */
// Open selected file and load the table to savedDataBuffer
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("You selected " + selection.getName());
    
    savedDataBuffer = loadTable(selection.getName(), "header");
    loadStartTime = millis();
    isDataLoaded = true;
    
    println(savedDataBuffer.getRowCount() + " total rows in table");    
    
    // parsing saved data on a separate thread
    thread("dataParser");   
    
  }
}


/* --------------------- Parse through savefile --------------------- */

void dataParser(){
  if(!isDataLoaded){
    drawBlank();
    // println("Something must have been wrong because this error message is not supposed to be shown.");
    
  } else {
    
    //check if table is empty
    if(savedDataBuffer.getRowCount() == 0){
      println("Save file error. Please choose another file.");
      isDataLoaded = false;
    } else {
      
      println("Data visualization starts in ...");
      println("3..."); delay(1000);
      println("2..."); delay(1000);
      println("1..."); delay(1000);    
      println("Start.");
      
      readyToDraw = true;
      
      // parse through data table
      for(TableRow row : savedDataBuffer.rows()){
        int rowTime = row.getInt("time");
        int currTime = millis();
        
        // hold until the correct time
        while(currTime - loadStartTime < rowTime){
          currTime = millis();
        }
        
        println("Processing row " + row.getInt("id"));
        
        // ok, it's time to update the buffer data
        for (int i = 0; i < gridSize; i++) {
          LpressValues[i] = row.getInt("LpressValues"+i);
          RpressValues[i] = row.getInt("RpressValues"+i);
        }
        
      } // end parse
      
      println("Data visualization finished in ...");
      println("3..."); delay(1000);
      println("2..."); delay(1000);
      println("1..."); delay(1000);    
      println("Finished. Please choose another file.");
      
      isDataLoaded = false;
      readyToDraw = false;
      
    }
    
  }
}
