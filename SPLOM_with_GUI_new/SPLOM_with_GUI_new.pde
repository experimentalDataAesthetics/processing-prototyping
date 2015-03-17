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

int soundx = 0;
int soundy = 1;

import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

float scalexy = 1;
float transx = 0;
float transy = 0;

int diam = 5; // point size
int boxwidth = 100;  // width of grid
int boxheight = 100; // height of grid
Integer[] xidx = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
}; // map grid (left-right) to dim
Integer[] yidx = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
}; // map grid (top-down) to dim
//Integer[] yidx = {8, 7, 6, 5, 4, 3, 2}; // map grid (top-down) to dim

boolean record = false;
boolean loop = false;
boolean clear = false;
float play = -1; // play stopped
float playspeed = 1.0; // play speed <1 :: slowmo  >1 :: timelapse
boolean pause = false;
ArrayList<Float> mouseXs = new ArrayList<Float>();
ArrayList<Float> mouseYs = new ArrayList<Float>();

float mxd = diam;
float myd = diam;

BufferedReader reader;
String line;
ArrayList<ArrayList<Float>> pts = new ArrayList<ArrayList<Float>>();
ArrayList<Integer> ptsound = new ArrayList<Integer>();
int lastsound = 0;
int delaysound = 0; // delay before new sounds are played in ms
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
  color(0, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 0, 255), color(0, 255, 255), color(255, 255, 0)
  //  color(0, 0, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 0, 255), color(0, 255, 255), color(255, 255, 0)
};
color colline = color(0, 0, 0);
color colhighlbox = color(255, 0, 0);
color colhighlbox2 = color(255, 255, 0);
color colhighlsoundsel = color(0, 255, 0);
color colhighlpt = color(255, 0, 0);
color colnohighlpt = color(0, 0, 0);
int colx = cols.length-1;

float mx = 0;
float my = 0;

void setup() {
  size(1050, 640);
  oscP5 = new OscP5(this, 57110);
  myRemoteLocation = new NetAddress("127.0.0.1", 57110);  
  
  startController(this);
  dial1 = 0.5;
  dial2 = 0.5;
  dial3 = 0.5;
  dial4 = 0.5;

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

void redraw() {
      int pm = min(mouseX / boxwidth, xidx.length-1);
      int pn = min(mouseY / boxheight, yidx.length-1);
      background(255);
      drawscat(boxwidth, boxheight);
      drawbox(colhighlbox2, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      drawbox(colhighlbox, pm, pn, boxwidth, boxheight);
      drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);
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
//  println(frameRate);
  int dt = millis();

  if (scalexy != exp(2*dial1)/exp(1) || transx != width * 2*(dial2-0.5) || transy != height * 2*(dial3-0.5) || diam != int(5 * exp(2*dial4)/exp(1))) {
    scalexy = exp(2*dial1)/exp(1);
    transx = width * 2*(dial2-0.5);
    transy = height * 2*(dial3-0.5);
    diam = int(5 * exp(2*dial4)/exp(1));
    translate(width/2 + scalexy*(transx-width/2), height/2 + scalexy*(transy-height/2));  
    scale(scalexy);
    redraw();
    println("redraw!");
  } else {
    translate(width/2 + scalexy*(transx-width/2), height/2 + scalexy*(transy-height/2));  
    scale(scalexy);
  }

  if (play >= 0.0) {
// block needs to move to a function
    {
      int playi = int(play);
      float playf = play % 1;
//      float mx, my;
        if (playi < mouseXs.size()-1) {
          mx = (1.-playf)*mouseXs.get(playi) + (playf)*mouseXs.get(playi+1);
          my = (1.-playf)*mouseYs.get(playi) + (playf)*mouseYs.get(playi+1);
        } else {
          mx = mouseXs.get(playi);
          my = mouseYs.get(playi);
        }
    }
    if (!pause) {
      play += playspeed;
      if (play > mouseXs.size()-1) {
        if (loop) {
          play = 0; // loop 
        } else {
          play = -1; // play stopped
        }
      }
    }
  } else {
    mx = mouseX;
    my = mouseY;
    mx /= scalexy;
    mx -= width/2/scalexy + (transx-width/2);
    my /= scalexy;
    my -= height/2/scalexy + (transy-height/2);
    if (record) {
      if (clear) {
        mouseXs.clear();
        mouseYs.clear();
        clear = false;
      }
      mouseXs.add(mx);
      mouseYs.add(my);
    }
  }

  if (mx/boxwidth >= 0 && mx/boxwidth < xidx.length && my/boxheight >= 0 && my/boxheight < yidx.length) {
    if (pm != my / boxwidth || pn != my / boxheight) {
      drawbox(colline, pm, pn, boxwidth, boxheight);
      drawbox(colline, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      pm = int(mx) / boxwidth;
      pn = int(my) / boxheight;
      // highlight
      drawbox(colhighlbox2, Arrays.asList(xidx).indexOf(yidx[pn]), Arrays.asList(yidx).indexOf(xidx[pm]), boxwidth, boxheight);
      drawbox(colhighlbox, pm, pn, boxwidth, boxheight);
      drawonebox(colhighlsoundsel, soundx, soundy, boxwidth, boxheight);
    }
  }

  if (mx/boxwidth >= 0 && mx/boxwidth < xidx.length && my/boxheight >= 0 && my/boxheight < yidx.length) {
    ptsel = closept(xidx[int(mx) / boxwidth], yidx[int(my) / boxheight], mx % boxwidth, my % boxheight, boxwidth, boxheight, mxd, myd);
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
    sendosctograin((sz < 4 ? 0.1 : 0.1/sz), freqA*pow(2., xx), grainsustain, panning/100);
    sendosctograin((sz < 4 ? 0.1 : 0.1/sz), freqB*pow(2., yy), grainsustain, -1.0*(panning/100));
  } 
  ptsound.clear();
  }

  ptprev = ptsel;
} 

void mouseClicked() {  

  if (mouseButton == RIGHT) {
    if (mx/boxwidth >= 0 && mx/boxwidth < xidx.length && my/boxwidth >= 0 && my/boxwidth < yidx.length){
      soundx = int(mx) / boxwidth;
      soundy = int(my) / boxwidth;
    }
    redraw();
  } else {    
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
      brush.clear();
      colx = 1;
      for (int idx : ptorder) { // set all points to clear
        ptcol.set(idx, 0);
      }
      redraw();
    }
  }
}

void mouseMoved() {
  play = -1;
  loop = false;
}

void mouseDragged() {  
  play = -1;
  loop = false;

  if (!drag) { // start new drag
    drag = true;
    if (ptsel.isEmpty()) {
//      redraw();
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
/*  case 'f':
    freqA = 1760.0;
    break; */
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
    loop = false;
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
    if (!pause) {
      if (loop == false && !mouseXs.isEmpty()) {
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
    if (loop) {
      loop = false;       
      println("stop");
    }    
    break;   

  case 'f':
    if (record) {
      record = false;       
      println("stop");
    }
    if (loop) {
      loop = false;       
//      play = -1;
      println("stop");
    } else {
      loop = true;
    }
//    if (play == -1) {
    if (!pause) {
      if (play == -1 && !mouseXs.isEmpty()) {
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

