import oscP5.*;
import netP5.*;

import java.util.*;
import java.lang.Math;
import controlP5.*;
ControlP5 cp5;

float grainsustain = 0.04;
float panning = 0.0;
float freqA = 880.0;
float freqB = 3520.0;


import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

int diam = 5; // point size
int boxwidth = 100;  // width of grid
int boxheight = 100; // height of grid
Integer[] xidx = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}; // map grid (left-right) to dim
Integer[] yidx = {0, 1, 2, 3, 4, 5, 6, 7}; // map grid (top-down) to dim
//Integer[] yidx = {8, 7, 6, 5, 4, 3, 2}; // map grid (top-down) to dim

boolean record = false;
boolean clear = false;
int play = -1; // play stopped
boolean pause = false;
ArrayList<Integer> mouseXs = new ArrayList<Integer>();
ArrayList<Integer> mouseYs = new ArrayList<Integer>();

float mxd = diam;
float myd = diam;

BufferedReader reader;
String line;
ArrayList<ArrayList<Float>> pts = new ArrayList<ArrayList<Float>>();
ArrayList<Float> mins = new ArrayList<Float>();
ArrayList<Float> maxs = new ArrayList<Float>();

TreeSet<Integer> brush = new TreeSet<Integer>();
Boolean drag = false;
ArrayList<Integer> ptidx = new ArrayList<Integer>();
ArrayList<Integer> ptsel = new ArrayList<Integer>();
ArrayList<Integer> ptprev = new ArrayList<Integer>();
ArrayList<Integer> ptorder = new ArrayList<Integer>();
ArrayList<Integer> ptcol = new ArrayList<Integer>();

color[] cols = new color [] {
  color(0, 0, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 0, 255), color(0, 255, 255), color(255, 255, 0)
};
int colx = cols.length-2;

int mx = 0;
int my = 0;

void setup() {
  size(1050, 640);
  oscP5 = new OscP5(this, 57110);
  myRemoteLocation = new NetAddress("127.0.0.1", 57110);  

  cp5 = new ControlP5(this); 
  Group g1 = cp5.addGroup("g1").setPosition(780, 10).setWidth(250).activateEvent(true)
    .setBackgroundColor(color(180)).setBackgroundHeight(100).setLabel("GUI");

  cp5.addSlider("slider1").setPosition(10, 10).setRange(10.0, 500.0).setSize(90, 14).setValue(40.0).setGroup(g1).setLabel("Sustain");

  cp5.addSlider("slider2").setPosition(10, 30).setRange(0.0, 100.0).setSize(90, 14).setValue(100.0).setGroup(g1).setLabel("Panning");

  cp5.addSlider("slider3").setPosition(10, 60).setRange(0.0, 1.0).setSize(90, 14).setValue(0.1).setGroup(g1).setLabel("Brushwidth");
  cp5.addSlider("slider4").setPosition(10, 80).setRange(0.0, 1.0).setSize(90, 14).setValue(0.1).setGroup(g1).setLabel("Brushheight");

  // Open the file from the createWriter() example
  reader = createReader("wine.data"); 
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

ArrayList<Integer> closept(int m, int n, int x, int y, int xsz, int ysz, float mxd, float myd) {
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

void drawsel(int c, int idx, int xsz, int ysz) {
  for (int i = 0; i < xidx.length; i++) {
    for (int k = 0; k < yidx.length; k++) {
      drawsel(c, idx, xidx[i], yidx[k], i*xsz, k*ysz, xsz, ysz);
    }
  }
}

void drawsel(int c, int idx, int m, int n, int x, int y, int xsz, int ysz) {
  xsz-=diam;
  ysz-=diam;

  noStroke();
  fill(cols[c]);
  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  ArrayList<Float> pt = pts.get(idx);
  int xx = int(xxsc * (pt.get(m)-xmin));
  int yy = ysz - int(yysc * (pt.get(n)-ymin)); // flip y coord
  ellipse(x+xx+diam/2, y+yy+diam/2, diam, diam);
}

void drawbox(int c, int m, int n, int xsz, int ysz) {
  stroke(cols[c]);
  noFill();

  for (int i = 0; i < xidx.length; i++) {
    rect(i*xsz, n*ysz, xsz, ysz);
  }
  for (int i = 0; i < yidx.length; i++) {
    rect(m*xsz, i*ysz, xsz, ysz);
  }
}

int pm = 0; 
int pn = 0;

void draw() {
  int dt = millis();
  //  background(255);

  if (mouseX / boxwidth < xidx.length && mouseY / boxheight < yidx.length) {
    if (pm != mouseX / boxwidth || pn != mouseY / boxheight) {
      drawbox(0, pm, pn, boxwidth, boxheight);
//      drawbox(0, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      pm = mouseX / boxwidth;
      pn = mouseY / boxheight;
      drawbox(cols.length-1, pm, pn, boxwidth, boxheight);
//      drawbox(cols.length-1, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
    }
  }

  if (play > -1) {
    ptsel = closept(xidx[mouseXs.get(play) / boxwidth], yidx[mouseYs.get(play) / boxheight], mouseXs.get(play) % boxwidth, mouseYs.get(play) % boxheight, boxwidth, boxheight, mxd, myd);
    if (!pause) {
      play++;
      if (play >= mouseXs.size()) {
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
      drawsel(ptcol.get(idx), idx, boxwidth, boxheight);
    }
  }
  for (int idx : ptold) {
    if (brush.contains(idx)) {
      drawsel(ptcol.get(idx), idx, boxwidth, boxheight);
    }
  }

  for (int idx : ptnew) {
    drawsel(cols.length-1, idx, boxwidth, boxheight);
  }

  if (drag) {
    brush.addAll(ptnew);
    for (int idx : ptnew) {
      ptcol.set(idx, colx);
    }
  }

  for (int idx : ptnew) {
    int x1 = 5;
    int x2 = 6;
    float xx = (pts.get(idx).get(x1)-mins.get(x1)) / (maxs.get(x1)-mins.get(x1)); // normalize value
    float yy = (pts.get(idx).get(x2)-mins.get(x2)) / (maxs.get(x2)-mins.get(x2)); // normalize value
    sendosctograin((ptnew.size() < 4 ? 0.1 : 0.1/ptnew.size()), freqA*pow(2., xx), grainsustain, panning/100);
    sendosctograin((ptnew.size() < 4 ? 0.1 : 0.1/ptnew.size()), freqB*pow(2., yy), grainsustain, -1.0*(panning/100));
  } 

  ptprev = ptsel;
} 

void mouseClicked() {  
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
    drawbox(cols.length-1, pm, pn, boxwidth, boxheight);
//    drawbox(cols.length-1, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
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
      drawbox(cols.length-1, pm, pn, boxwidth, boxheight);
//      drawbox(cols.length-1, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);

      colx = colx+1 > cols.length-2 ? 1 : colx+1; // next color without brush
    } else {
      // max color under selection
      int[] ccols = new int [cols.length-1]; // initialized to zero?!
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
        colx = colx+1 > cols.length-2 ? 1 : colx+1; // next color without brush
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

void sendosctograin(float amp, float freq, float sstn, float pan) {
  OscBundle myBundle = new OscBundle();
  myBundle.setTimetag(myBundle.now());  // and time tag          
  OscMessage myMessage = new OscMessage("/s_new");         
  //myMessage.add("grain");   // works with the Grain-Synthdef loaded by SC
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

void slider1(float slidervalue1) {
  grainsustain = slidervalue1/1000.0;
  //println("a numberbox event. setting grain sustain to "+slidervalue1);
}

void slider2(float slidervalue2) {
  panning = slidervalue2;
  //println("a numberbox event. setting grain sustain to "+slidervalue2);
}

void slider3(float slidervalue3) {
  mxd = slidervalue3 * boxwidth/2;
}
void slider4(float slidervalue4) {
  myd = slidervalue4 * boxwidth/2;
}

void keyPressed()
{
  switch (key) {
  case 'a':
    freqA = 220.0;
    break;
    /*  case 's':
     freqA = 440.0;
     break; 
     
     case 'd':
     freqA = 880.0;
     break;
     */
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
  case ' ':
    freqA = 880.0;
    freqB = 3520.0;
    break;   

  case 's':
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

  case 'd':
    if (record) {
      record = false;       
      println("stop");
    }
    if (play == -1) {
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

