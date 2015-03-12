//Basic Midi-Controller Code
//Version 2.0 (05.10.2014)

import promidi.*;

MidiIO midiIO;

float slider1, slider2, slider3, slider4, slider5, slider6, slider7, slider8;
float dial1, dial2, dial3, dial4, dial5, dial6, dial7, dial8;
boolean button1, button2, button3, button4, button5;

void startController(PApplet main) {
  // get an instance of MidiIO
  midiIO = MidiIO.getInstance(main);
  
  //print a list with all available devices
  int ndev = midiIO.numberOfInputDevices();
  for (int i = 0; i < ndev; i++) { 
    println(midiIO.getInputDeviceName(i));
    midiIO.openInput(i, 0);
  }
  
  String values[] = loadStrings("values.txt");
  if(values != null)  {
    slider1 = float(values[0]);
    slider2 = float(values[1]);
    slider3 = float(values[2]);
    slider4 = float(values[3]);
    slider5 = float(values[4]);
    slider6 = float(values[5]);
    slider7 = float(values[6]);
    slider8 = float(values[7]);
    dial1 = float(values[8]);
    dial2 = float(values[9]);
    dial3 = float(values[10]);
    dial4 = float(values[11]);
    dial5 = float(values[12]);
    dial6 = float(values[13]);
    dial7 = float(values[14]);
    dial8 = float(values[15]);
  }
  
  prepareExitHandler();
  
  
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
  case 43: button1 = false;
  break;
  case 44: button2 = false;
  break;
  case 42: button3 = false;
  break;
  case 41: button4 = false;
  break;
  case 45: button5 = false;
  break;
}}

void controllerIn(
  Controller controller,
  int deviceNumber,
  int midiChannel
){
  int num = controller.getNumber();
  
  int rawVal = controller.getValue();
  float val = norm(rawVal,0,127);
  
  println("controllerIn "+(num+1)+" "+val);

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
  case 43: button1 = true;
  break;
  case 44: button2 = true;
  break;
  case 42: button3 = true;
  break;
  case 41: button4 = true;
  break;
  case 45: button5 = true;
  break;
}
}

private void prepareExitHandler () {

  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
  
  public void run () {
  
    //save values
    String values = "";
    values += str(slider1) + " ";
    values += str(slider2) + " ";
    values += str(slider3) + " ";
    values += str(slider4) + " ";
    values += str(slider5) + " ";
    values += str(slider6) + " ";
    values += str(slider7) + " ";
    values += str(slider8) + " ";
    values += str(dial1) + " ";
    values += str(dial2) + " ";
    values += str(dial3) + " ";
    values += str(dial4) + " ";
    values += str(dial5) + " ";
    values += str(dial6) + " ";
    values += str(dial7) + " ";
    values += str(dial8);
    String[] valueList = split(values, ' ');
    saveStrings("data/values.txt", valueList);
  }

}));

}
