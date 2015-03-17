//Basic Midi-Controller Code

import promidi.*;

MidiIO midiIO;

float slider1, slider2, slider3, slider4, slider5, slider6, slider7, slider8;
float dial1, dial2, dial3, dial4, dial5, dial6, dial7, dial8;

void startController(PApplet main) {
  // get an instance of MidiIO
  midiIO = MidiIO.getInstance(main);
  
  //print a list with all available devices
  int ndev = midiIO.numberOfInputDevices();
  for (int i = 0; i < ndev; i++) { 
    println(midiIO.getInputDeviceName(i));
    midiIO.openInput(i, 0);
  }
}

void noteOn(
  Note note,
  int deviceNumber,
  int midiChannel
){
  int vel = note.getVelocity();
  int pit = note.getPitch();
  int len = note.getNoteLength();

println("noteOn "+vel+" "+pit+" "+len);

switch (pit) {
  case 0: slider1 = 0;
  break; 
  case 1: slider2 = 0;
  break; 
  case 2: slider3 = 0;
  break; 
  case 3: slider4 = 0;
  break; 
  case 4: slider5 = 0;
  break; 
  case 5: slider6 = 0;
  break; 
  case 6: slider7 = 0;
  break; 
  case 7: slider8 = 0;
  break; 
  case 16: dial1 = 0;
  break; 
  case 17: dial2 = 0;
  break; 
  case 18: dial3 = 0;
  break; 
  case 19: dial4 = 0;
  break; 
  case 20: dial5 = 0;
  break; 
  case 21: dial6 = 0;
  break; 
  case 22: dial7 = 0;
  break; 
  case 23: dial8 = 0;
  break; 
}}

void controllerIn(
  promidi.Controller controller,
  int deviceNumber,
  int midiChannel
){
  int num = controller.getNumber();
  
  int rawVal = controller.getValue();
  float val = norm(rawVal,0,127);
  
//  println("controllerIn "+(num+1)+" "+val);

switch (num) {
  case 0: slider1 = val;
  break; 
  case 1: slider2 = val;
  break; 
  case 2: slider3 = val;
  break; 
  case 3: slider4 = val;
  break; 
  case 4: slider5 = val;
  break; 
  case 5: slider6 = val;
  break; 
  case 6: slider7 = val;
  break; 
  case 7: slider8 = val;
  break; 
  case 16: dial1 = val;
  break; 
  case 17: dial2 = val;
  break; 
  case 18: dial3 = val;
  break; 
  case 19: dial4 = val;
  break; 
  case 20: dial5 = val;
  break; 
  case 21: dial6 = val;
  break; 
  case 22: dial7 = val;
  break; 
  case 23: dial8 = val;
  break; 
}}




