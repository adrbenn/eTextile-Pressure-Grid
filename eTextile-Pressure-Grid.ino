/*********************************************************************
eTextile Pressure Grid
For Teensy 4.1

Last update: 25 June 2024
*********************************************************************/

const int NUM_VERT = 9;
const int NUM_HORI = 10;

int vertPinsL[NUM_VERT] = {A0, A1, A2, A3, A4, A5, A6, A7, A8};
int horiPinsL[NUM_HORI] = {33, 34, 35, 36, 37, 32, 31, 30, 29, 28};

int gridValsL[NUM_HORI][NUM_VERT]={0};

int vertPinsR[NUM_VERT] = {A9, A10, A11, A12, A13, A14, A15, A16, A17};
int horiPinsR[NUM_HORI] = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

int gridValsR[NUM_HORI][NUM_VERT]={0};


int delayTime = 1;

void setup() {
  Serial.begin(9600);
  
  // horizontal pins (digital) are the output. we will send voltage to them ...
  for(int i=0; i<NUM_HORI; i++){
    pinMode(horiPinsL[i], OUTPUT);
    digitalWrite(horiPinsL[i], LOW);

    pinMode(horiPinsR[i], OUTPUT);
    digitalWrite(horiPinsR[i], LOW);
  }

  // ... to be picked up by the vertical pins (analog) as inputs.
  for(int i=0; i<NUM_VERT; i++){
    pinMode(vertPinsL[i], OUTPUT);
    pinMode(vertPinsR[i], OUTPUT);
  }

}


void loop() {
  for(int i=0; i<NUM_HORI; i++) {
    
    // for each horizontal line, send HIGH ...
    digitalWrite(horiPinsL[i], HIGH);
    digitalWrite(horiPinsR[i], HIGH);
    
    // ... then read the values of each vertical connection
    // the values are stored in the gridVals matrix
    readVertValues(i);
    
    // reset the horizontal line back to LOW
    digitalWrite(horiPinsL[i], LOW);
    digitalWrite(horiPinsR[i], LOW);
  }

  // stream the values to Processing
  streamToProcessing();

  // printout the grid in Serial Monitor
  //outputTheGrid();

  delay(delayTime);
}

void readVertValues(int h) {
  for(int v = 0; v < NUM_VERT; v++) {

    gridValsL[h][v] = analogRead(vertPinsL[v]);
    gridValsR[h][v] = analogRead(vertPinsR[v]);
  }
}

// Stream the data out to Processing with serial message
// One message is a long string of numbers separated by symbol x
// Left grid first, then right grid. Separated by symbol z
void streamToProcessing(){
  String msg = "";

  // Left grid
  for(int h = 0; h < NUM_HORI; h++) {
    for(int v = 0; v < NUM_VERT; v++) { 
      msg = msg + String(gridValsL[h][v]) + "x";  
    }
  }
  msg = msg + "z";

  // Right grid
  for(int h = 0; h < NUM_HORI; h++) {
    for(int v = 0; v < NUM_VERT; v++) { 
      msg = msg + String(gridValsR[h][v]) + "x";  
    }
  }

  Serial.println(msg); 
}


// Output the grid to Serial Monitor
void outputTheGrid(){
  
  // gridValsL    |||  gridValsR
  
  for(int h = 0; h < NUM_HORI; h++) {
    Serial.print("|\t");
    
    // print horizontal line by line
    for(int v = 0; v < (NUM_VERT * 2); v++) {
      if(v < NUM_VERT){
        // left grid
        Serial.printf("%03d", gridValsL[h][v]);
      
      } else {
        // right grid
        Serial.printf("%03d", gridValsR[h][v - NUM_VERT]);
        
      }

      // separator
      if (v == NUM_VERT - 1){
        Serial.print("\t ||| \t");
      } else {
        Serial.print("-");
      }
    }
    Serial.println(" \t|");
  }

  Serial.println();
  Serial.println();  // Separate grids with an empty line
  
}
