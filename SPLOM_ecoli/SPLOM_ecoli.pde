import oscP5.*;
import netP5.*;
import java.util.*;
import java.lang.Math;
import controlP5.*;
ControlP5 cp5;
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

// Sound settings
float grainsustain = 0.01;
float panning = 0.0;
float freqA = 880.0; // q und d
float freqB = 220.0;


int soundx = 0;
int soundy = 1; 

// Settings of SPLOM
float diam = 5.0; // point size
int boxwidth = 140;  // width of grid
int boxheight = 140; // height of grid
Integer[] xidx = {
  1, 2, 5, 6, 7, 
}; // map grid (left-right) to dim
Integer[] yidx = {
  1, 2, 5, 6, 7, 
}; // map grid (top-down) to dim
//Integer[] yidx = {8, 7, 6, 5, 4, 3, 2}; // map grid (top-down) to dim

// Playback settings
boolean record = false;
boolean clear = false;
float play = -1; // play stopped
float playspeed = 1.0; // play speed <1 :: slowmo  >1 :: timelapse


boolean pause = false;
ArrayList<Integer> mouseXs = new ArrayList<Integer>();
ArrayList<Integer> mouseYs = new ArrayList<Integer>();

float mxd = diam;
float myd = diam;

BufferedReader reader;
String line;
ArrayList<ArrayList<Float>> pts = new ArrayList<ArrayList<Float>>();
ArrayList<Integer> ptsound = new ArrayList<Integer>();
int lastsound = 0;

// delay before new sounds are played in ms. This is for playing several points at once.
int delaysound = 0; 
ArrayList<Float> mins = new ArrayList<Float>();
ArrayList<Float> maxs = new ArrayList<Float>();

TreeSet<Integer> brush = new TreeSet<Integer>();
Boolean drag = false;
ArrayList<Integer> ptidx = new ArrayList<Integer>();
ArrayList<Integer> ptsel = new ArrayList<Integer>();
ArrayList<Integer> ptprev = new ArrayList<Integer>();
ArrayList<Integer> ptorder = new ArrayList<Integer>();
ArrayList<Integer> ptcol = new ArrayList<Integer>();

// Color settings
color[] cols = new color [] {
  color(0, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 0, 255), color(0, 255, 255), color(255, 255, 0)
  //  color(0, 0, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 0, 255), color(0, 255, 255), color(255, 255, 0)
};
color colline = color(0, 0, 0);
color colhighlbox = color(255, 0, 0);
color colhighlbox2 = color(255, 255, 0);
color colhighlsoundsel = color(0, 255, 0);
color colhighlpt = color(255,0,0);
color colnohighlpt = color(0, 0, 0);
int colx = cols.length; // what is this?

int mx = 0;
int my = 0;


void setup() {
  size(displayWidth, displayHeight);
  initKNC2(); 
  oscP5 = new OscP5(this, 57110);
  myRemoteLocation = new NetAddress("127.0.0.1", 57110);  

  cp5 = new ControlP5(this); 
   
    // change the default font to Verdana
  PFont p = createFont("Verdana",15);
  cp5.setControlFont(p);
  
  Group g1 = cp5.addGroup("g1").setPosition(displayWidth-330, 10).setWidth(330).activateEvent(true)  
  .setBackgroundColor(color(180)).setBackgroundHeight(displayHeight).setLabel("GUI for SPLOM Sonificator");

  cp5.addSlider("slider1").setPosition(10, 30).setColorForeground(color(255, 0, 0)).setRange(0.01, 0.5).setSize(100, 14).setValue(grainsustain).setGroup(g1).setLabel("Grain Sustain");
 // cp5.addSlider("slider2").setPosition(10, 30).setRange(0.0, 100.0).setSize(90, 14).setValue(100.0).setGroup(g1).setLabel("FreqA");
  cp5.addSlider("slider5").setPosition(10, 60).setColorForeground(color(255, 0, 0)).setRange(0, 1000).setSize(100, 14).setValue(delaysound).setGroup(g1).setLabel("Trigger Delay (ms)");

  cp5.addSlider("slider3").setPosition(10, 80).setColorForeground(color(255, 0, 0)).setRange(0.0, boxwidth/2).setSize(100, 14).setValue(diam).setGroup(g1).setLabel("Brushwidth");
  cp5.addSlider("slider4").setPosition(10, 100).setColorForeground(color(255, 0, 0)).setRange(0.0, boxheight/2).setSize(100, 14).setValue(diam).setGroup(g1).setLabel("Brushheight");
  cp5.addSlider("slider6").setPosition(10, 140).setColorForeground(color(255, 0, 0)).setRange(1.0, 25.0).setSize(100, 14).setValue(playspeed).setGroup(g1).setLabel("Playbackspeed faster");
  cp5.addSlider("slider7").setPosition(10, 160).setColorForeground(color(255, 0, 0)).setRange(0.1, 1.0).setSize(100, 14).setValue(1.0).setGroup(g1).setLabel("Playbackspeed slower");

  

  // Open the file from the createWriter() example
  reader = createReader("ecoli.csv"); 
  do {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      line = null;
    }
    if (line != null) {
      ArrayList<Float> pt = new ArrayList<Float>();
      String[] pieces = split(line, ',');
      // bug: this assumes that all records have equal length
      for (String pp : pieces) {
        pt.add(float(pp));
      }
      pts.add(pt);
    }
  } 
  while (line != null); 
  ArrayList<Float> ppt = pts.get(0);
  for (float val : ppt) {
    mins.add(val);
    maxs.add(val);
  }
  for (ArrayList<Float> pt : pts) {
    ptorder.add(pts.indexOf(pt)); // not efficient
    ptcol.add(0); 
    for (int i = 0; i < mins.size (); i++) {
      if (pt.get(i) < mins.get(i)) {
        mins.set(i, pt.get(i));
      } else if (pt.get(i) > maxs.get(i)) {
        maxs.set(i, pt.get(i));
      }
    }
  }
  
  background(255);
  drawscat(boxwidth, boxheight);
}

ArrayList<Integer> closept(int m, int n, float x, float y, int xsz, int ysz, float mxd, float myd) {
  ArrayList<Integer> tmp = new ArrayList<Integer>();
  xsz-=diam;
  ysz-=diam;

  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  for (ArrayList<Float> pt : pts) {
    float xx = xxsc * (pt.get(m)-xmin);
    float yy = ysz - yysc * (pt.get(n)-ymin); // flip y coord
    float xd = abs(x - (xx+diam/2));
    float yd = abs(y - (yy+diam/2));
    if (xd < mxd && yd < myd) {
      tmp.add(pts.indexOf(pt));
    }
  }
  return tmp;
}

ArrayList<Integer> closept(int m, int n, int x, int y, int xsz, int ysz) {
  ArrayList<Integer> tmp = new ArrayList<Integer>();
  float mind = 4* diam*diam/4.;
  xsz-=diam;
  ysz-=diam;

  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  for (ArrayList<Float> pt : pts) {
    float xx = xxsc * (pt.get(m)-xmin);
    float yy = ysz - yysc * (pt.get(n)-ymin); // flip y coord
    float xd = x - (xx+diam/2);
    float yd = y - (yy+diam/2);
    float tmpd = xd*xd+yd*yd;
    if (tmpd < mind) {
      tmp.add(pts.indexOf(pt));
    }
  }
  return tmp;
}

void drawscat(int xsz, int ysz) {
  for (int i = 0; i < xidx.length; i++) {
    for (int k = 0; k < yidx.length; k++) {
      drawscat(xidx[i], yidx[k], i*xsz, k*ysz, xsz, ysz);
    }
  }
}

void drawscat(int m, int n, int x, int y, int xsz, int ysz) {
  stroke(128);
  noFill();
  rect(x, y, xsz, ysz);
  xsz-=diam;
  ysz-=diam;

  noStroke();
  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  for (Integer pt : ptorder) {
    fill(cols[ptcol.get(pt)]);
    int xx = int(xxsc * (pts.get(pt).get(m)-xmin));
    int yy = ysz - int(yysc * (pts.get(pt).get(n)-ymin)); // flip y coord
    ellipse(x+xx+diam/2, y+yy+diam/2, diam, diam);
  }
}

void drawsel(color c, int idx, int xsz, int ysz) {
  for (int i = 0; i < xidx.length; i++) {
    for (int k = 0; k < yidx.length; k++) {
      drawsel(c, idx, xidx[i], yidx[k], i*xsz, k*ysz, xsz, ysz);
    }
  }
}

void drawsel(color c, int idx, int m, int n, int x, int y, int xsz, int ysz) {
  xsz-=diam;
  ysz-=diam;

  noStroke();
  fill(c);
  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  ArrayList<Float> pt = pts.get(idx);
  int xx = int(xxsc * (pt.get(m)-xmin));
  int yy = ysz - int(yysc * (pt.get(n)-ymin)); // flip y coord
  ellipse(x+xx+diam/2, y+yy+diam/2, diam, diam);
}

void drawbox(color c, int m, int n, int xsz, int ysz) {
  stroke(c);
  noFill();

  for (int i = 0; i < xidx.length; i++) {
    rect(i*xsz, n*ysz, xsz, ysz);
  }
  for (int i = 0; i < yidx.length; i++) {
    rect(m*xsz, i*ysz, xsz, ysz);
  }
}

void drawonebox(color c, int m, int n, int xsz, int ysz) {
  stroke(c);
  noFill();

  rect(m*xsz, n*ysz, xsz, ysz);
}

int pm = 0; 
int pn = 0;

void draw() {
  updateKNC2(); 
  int dt = millis();  
 
  //  background(255);

  if (mouseX / boxwidth < xidx.length && mouseY / boxheight < yidx.length) {
    if (pm != mouseX / boxwidth || pn != mouseY / boxheight) {
      drawbox(colline, pm, pn, boxwidth, boxheight);
      drawbox(colline, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);

      pm = mouseX / boxwidth;
      pn = mouseY / boxheight;
      // highlight
      drawbox(colhighlbox2, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      drawbox(colhighlbox, pm, pn, boxwidth, boxheight);
      drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);
    }
  }

  if (play >= 0.0) {
// block needs to move to a function
  {
    int playi = int(play);
    float playf = play % 1;
    float mx, my;
    if (playi < mouseXs.size()-1) {
      mx = (1.-playf)*mouseXs.get(playi) + (playf)*mouseXs.get(playi+1);
      my = (1.-playf)*mouseYs.get(playi) + (playf)*mouseYs.get(playi+1);
    } else {
      mx = mouseXs.get(playi);
      my = mouseYs.get(playi);
    }
    ptsel = closept(xidx[int(mx) / boxwidth], yidx[int(my) / boxheight], mx % boxwidth, my % boxheight, boxwidth, boxheight, mxd, myd);
  }
    if (!pause) {
      play += playspeed;
      if (play > mouseXs.size()-1) {
        play = -1; // play stopped
      }
    }
  } else {
    if (record) {
      if (clear) {
        mouseXs.clear();
        mouseYs.clear();
        clear = false;
      }
      mouseXs.add(mouseX);
      mouseYs.add(mouseY);
    }
    if (mouseX / boxwidth < xidx.length && mouseY / boxheight < yidx.length) {
      ptsel = closept(xidx[mouseX / boxwidth], yidx[mouseY / boxheight], mouseX % boxwidth, mouseY % boxheight, boxwidth, boxheight, mxd, myd);
    }
  }
  ArrayList<Integer> ptold = new ArrayList<Integer>(ptprev);
  ptold.removeAll(ptsel);
  ArrayList<Integer> ptnew = new ArrayList<Integer>(ptsel);
  ptnew.removeAll(ptprev);

  for (int idx : ptold) {
    if (!brush.contains(idx)) {
      drawsel(cols[ptcol.get(idx)], idx, boxwidth, boxheight);
    }
  }
  for (int idx : ptold) {
    if (brush.contains(idx)) {
      drawsel(cols[ptcol.get(idx)], idx, boxwidth, boxheight);
    }
  }

  for (int idx : ptnew) {
    drawsel(colhighlpt, idx, boxwidth, boxheight);
  }

  if (drag) {
    brush.addAll(ptnew);
    for (int idx : ptnew) {
      ptcol.set(idx, colx);
    }
  }

  ptsound.addAll(ptnew);
  
  if (millis() - lastsound > delaysound) {
    lastsound = millis();
  for (int idx : ptsound) {
    int x1 = xidx[soundx];
    int x2 = yidx[soundy];
    float xx = (pts.get(idx).get(x1)-mins.get(x1)) / (maxs.get(x1)-mins.get(x1)); // normalize value
    float yy = (pts.get(idx).get(x2)-mins.get(x2)) / (maxs.get(x2)-mins.get(x2)); // normalize value
    int sz = ptsound.size();
    println(sz);
    
    // Sonification! <<<<<<<<<--------------------<<<<<<<<<--------------------
    
 sendosctograin((sz < 4 ? 0.1 : 0.1/sz), freqA*pow(2., xx), grainsustain, 1.0);
  sendosctograin((sz < 4 ? 0.1 : 0.1/sz), freqB*pow(2., yy), grainsustain, -1.0);
    
 //  sendosc((sz < 4 ? 0.1 : 0.1/sz), freqA*pow(2., xx), grainsustain, 1.0);
 //  sendosc((sz < 4 ? 0.1 : 0.1/sz), freqB*pow(2., yy), grainsustain, -1.0);
 
 //  sendgrainFM((sz < 4 ? 0.1 : 0.1/sz), freqA*pow(2., xx), freqB*pow(2., yy),  grainsustain, -1.0);

    
    
  } 
  ptsound.clear();
  }

  ptprev = ptsel;
  
  
  //Control sliders with MIDI (wrapper by Ludwig Zeller)
  cp5.getController("slider1").setValue(midi.value(0, 0.5, 0.01)); //mapping reversed (big number at 0, small number at 127, due to some "initial value bug")
  cp5.getController("slider3").setValue(midi.value(16, boxwidth/2, 4)); //mapping reversed
  cp5.getController("slider4").setValue(midi.value(17, boxheight/2, 4)); //mapping reversed
  cp5.getController("slider5").setValue(midi.value(1, 1000, 0)); //mapping reversed
  cp5.getController("slider6").setValue(midi.value(7, 25.0, 1.0)); //mapping reversed
//  cp5.getController("slider7").setValue(midi.value(7, 0.1, 1.0)); //mapping reversed  
  
} 

void mouseClicked() {  

  if (mouseButton == RIGHT) {
    if (mouseX / boxwidth < xidx.length && mouseY / boxwidth < yidx.length){
      soundx = mouseX / boxwidth;
      soundy = mouseY / boxwidth;
    }
    drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);
//    println(xidx[soundx] + " " + yidx[soundy]);
  } else {    
    int base = millis();
    mx = mouseX;
    my = mouseY;

    if (!ptsel.isEmpty()) {
      if (! brush.removeAll(ptsel)) { // toggle selection
        brush.addAll(ptsel);
        for (int idx : ptsel) { // set all selected points to current color
          ptcol.set(idx, colx);
        }
      } else {
        for (int idx : ptsel) { // set all selected points to clear
          ptcol.set(idx, 0);
        }
      }
    } else {
      background(255);
      brush.clear();
      colx = 1;
      for (int idx : ptorder) { // set all points to clear
        ptcol.set(idx, 0);
      }
      drawscat(boxwidth, boxheight);
      pm = min(mouseX / boxwidth, xidx.length-1);
      pn = min(mouseY / boxheight, yidx.length-1);
      drawbox(colhighlbox2, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      drawbox(colhighlbox, pm, pn, boxwidth, boxheight);
      drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);
    }
  }
}

void mouseMoved() {
  play = -1;
}

void mouseDragged() {  
  play = -1;

  if (!drag) { // start new drag
    drag = true;
    if (ptsel.isEmpty()) {
      background(255);
      drawscat(boxwidth, boxheight);
      pm = min(mouseX / boxwidth, xidx.length-1);
      pn = min(mouseY / boxheight, yidx.length-1);
      drawbox(colhighlbox2, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      drawbox(colhighlbox, pm, pn, boxwidth, boxheight);
      drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);

      colx = colx+1 > cols.length-1 ? 1 : colx+1; // next color without brush
    } else {
      // max color under selection
      int[] ccols = new int [cols.length]; // initialized to zero?!
      int max = 0;
      int midx = 0;
      for (int idx : ptsel) {
        ccols[ptcol.get(idx)] += 1;
        if (ccols[ptcol.get(idx)] > max) {
          midx = ptcol.get(idx);
          max = ccols[midx];
        }
      }
      if (midx == 0) {
        colx = colx+1 > cols.length-1 ? 1 : colx+1; // next color without brush
      } else {
        colx = midx;
      }
      brush.addAll(ptsel);
      for (int idx : ptsel) { // set selected points to new brush
        ptcol.set(idx, colx);
      }
    }
  }
}

void mouseReleased() {  
  drag = false;
}

// 

void sendosctograin(float amp, float freq, float sstn, float pan) {
  OscBundle myBundle = new OscBundle();
  myBundle.setTimetag(myBundle.now());  // and time tag          
  OscMessage myMessage = new OscMessage("/s_new");         
  myMessage.add("grain2"); 
  myMessage.add(-1); 
  myMessage.add(0); 
  myMessage.add(1);
  myMessage.add("amp"); 
  myMessage.add(amp);   
  myMessage.add("freq"); 
  myMessage.add(freq); 
  myMessage.add("sustain"); 
  myMessage.add(sstn); 
  myMessage.add("pan"); 
  myMessage.add(pan);  
  myBundle.add(myMessage); 
  oscP5.send(myBundle, myRemoteLocation);
}

void sendosc(float amp, float freq, float sstn, float pan) {
  OscBundle myBundle = new OscBundle();
  myBundle.setTimetag(myBundle.now());  // and time tag          
  OscMessage myMessage = new OscMessage("/s_new");         
  myMessage.add("testsynth"); 
  myMessage.add(-1); 
  myMessage.add(0); 
  myMessage.add(1);
  myMessage.add("amp"); 
  myMessage.add(amp);   
  myMessage.add("freq"); 
  myMessage.add(freq); 
  myMessage.add("sustain"); 
  myMessage.add(sstn); 
  myMessage.add("pan"); 
  myMessage.add(pan);  
  myBundle.add(myMessage); 
  oscP5.send(myBundle, myRemoteLocation);
}

void sendgrainFM(float amp, float carfreq, float modfreq, float sstn, float pan) {
  OscBundle myBundle = new OscBundle();
  myBundle.setTimetag(myBundle.now());  // and time tag          
  OscMessage myMessage = new OscMessage("/s_new");         
  myMessage.add("grainFM"); 
  myMessage.add(-1); 
  myMessage.add(0); 
  myMessage.add(1);
  myMessage.add("amp"); 
  myMessage.add(amp);   
  myMessage.add("carfreq"); 
  myMessage.add(carfreq); 
  myMessage.add("modfreq"); 
  myMessage.add(modfreq); 
  myMessage.add("sustain"); 
  myMessage.add(sstn); 
  myMessage.add("pan"); 
  myMessage.add(pan);  
  myBundle.add(myMessage); 
  oscP5.send(myBundle, myRemoteLocation);
}

void keyPressed()
{
  switch (key) {
  case 'a':
    freqA = 220.0;
    break;
  case 's':
     freqA = 440.0;
     break; 
  case 'd':
     freqA = 880.0;
     break;
  case 'f':
    freqA = 1760.0;
    break; 
  case 'g':
    freqA = 3520.0;
    break;   
  case 'q':
    freqB = 220.0;
    break;
  case 'w':
    freqB = 440.0;
    break; 
  case 'e':
    freqB = 880.0;
    break;
  case 'r':
    freqB = 1760.0;
    break; 
  case 't':
    freqB = 3520.0;
    break;    
  case 'l':
    freqA = 880.0;
    freqB = 220.0;
    break;  
  case 'o':
    freqA = 220.0;
    freqB = 880.0;
    break;  

  case 'x': //record
    play = -1;
    if (record) {
      record = false;
      println("stop");
    } else {
      record = true;
      clear = true;
      println("record");
    }
    break;

  case ' ': //play
    if (record) {
      record = false;       
      println("stop");
    }
//    if (play == -1) {
    if (!pause) {
      if (!mouseXs.isEmpty()) {
        play = 0;
        pause = false;
        println("play");
      }
    } else if (pause) {
      pause = false;
      println("play");
    } else {
      pause = true;
      println("pause");
    } 
    break;   

  default: 
    break;
  }
}

void slider1(float slidervalue1) {
  grainsustain = slidervalue1;
    //println("a numberbox event. setting grain sustain to "+slidervalue1);
}

//void slider2(float slidervalue2) {
//  panning = slidervalue2;
//  //println("a numberbox event. setting grain sustain to "+slidervalue2);
//}

void slider3(int slidervalue3) {
  mxd = slidervalue3;
}

void slider4(int slidervalue4) {
  myd = slidervalue4;
}

void slider5(int slidervalue5) {
  delaysound = slidervalue5;
}

void slider6(float slidervalue6) {
  playspeed = slidervalue6;
}

void slider7(float slidervalue7) {
  playspeed = slidervalue7;
}

