import java.util.*;
import java.lang.Math;

import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

int diam = 5;

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
color [] cols = new color [] {
  color(0, 0, 0), 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 0, 255), 
  color(0, 255, 255), 
  color(255, 255, 0)
};
int colx = cols.length-2;

color c1 = color(255, 0, 0);
color c2 = color(0, 0, 255);
int mx = 0;
int my = 0;

void setup() {
  
  oscP5 = new OscP5(this, 57110);
  myRemoteLocation = new NetAddress("127.0.0.1", 57110);

  size(768, 640);
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
    for (int i = 0; i < mins.size(); i++) {
      if (pt.get(i) < mins.get(i)) {
        mins.set(i, pt.get(i));
      } 
      else if (pt.get(i) > maxs.get(i)) {
        maxs.set(i, pt.get(i));
      }
    }
  }
  background(255);
  for (int i = 0; i < 6; i++) {
    for (int k = 0; k < 6; k++) {
      drawscat(i+1, k+2, i*128, k*106, 128, 106);
    }
  }
}

ArrayList<Integer> closept(int m, int n, int x, int y, int xsz, int ysz) {
  if (mouseX < x || mouseX > x+xsz || mouseY < y || mouseY > y+ysz) { 
    // outside box
    return null;
  } 
  else { 
    // inside box
    ArrayList<Integer> tmp = new ArrayList<Integer>();

    x+=3;
    y+=3;
    xsz-=diam;
    ysz-=diam;

    float mind = 4* diam*diam/4.;
    int minidx = -1;

    float xmin = mins.get(m);
    float ymin = mins.get(n);
    float xxsc = xsz / (maxs.get(m)-xmin);
    float yysc = ysz / (maxs.get(n)-ymin);
    for (ArrayList<Float> pt : pts) {
      float xx = xxsc * (pt.get(m)-xmin);
      float yy = yysc * (pt.get(n)-ymin);
      float xd = mouseX - (x+xx);
      float yd = mouseY - (y+yy);
      float tmpd = xd*xd+yd*yd;
      if (tmpd < mind) {
        tmp.add(pts.indexOf(pt));
      }
    }
    return tmp;
  }
}

void drawscat(int m, int n, int x, int y, int xsz, int ysz) {
  stroke(128);
  noFill();
  rect(x, y, xsz, ysz);

  x+=3;
  y+=3;
  xsz-=diam;
  ysz-=diam;

  noStroke();
  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  //  for (ArrayList<Float> pt : pts) {
  //    int xx = int(xxsc * (pt.get(m)-xmin));
  //    int yy = int(yysc * (pt.get(n)-ymin));
  for (Integer pt : ptorder) {
    fill(cols[ptcol.get(pt)]);
    int xx = int(xxsc * (pts.get(pt).get(m)-xmin));
    int yy = int(yysc * (pts.get(pt).get(n)-ymin));
    ellipse(x+xx, y+yy, diam, diam);
  }
}

void drawsel(int c, int idx, int m, int n, int x, int y, int xsz, int ysz) {
  x+=3;
  y+=3;
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
  int yy = int(yysc * (pt.get(n)-ymin));
  ellipse(x+xx, y+yy, diam, diam);
  
  // sendosctograin(0.2, 600.0, 0.04, 0.0);
  
}

void draw() {
  println(frameRate);
  int dt = millis();
  //  background(255);
  for (int i = 0; i < 6; i++) {
    for (int k = 0; k < 6; k++) {
      //      drawscat(i+1, k+2, i*128, k*106, 128, 106);
      ArrayList<Integer> tmp = closept(i+1, k+2, i*128, k*106, 128, 106);
      if (tmp != null) {
        ptsel = tmp;
      }
    }
  }
  ArrayList<Integer> ptold = new ArrayList<Integer>(ptprev);
  ptold.removeAll(ptsel);
  ArrayList<Integer> ptnew = new ArrayList<Integer>(ptsel);
  ptnew.removeAll(ptprev);
  for (int i = 0; i < 6; i++) {
    for (int k = 0; k < 6; k++) {
      for (int idx : ptold) {
        if (!brush.contains(idx)) {
          drawsel(ptcol.get(idx), idx, i+1, k+2, i*128, k*106, 128, 106);
        }
      }
      for (int idx : ptold) {
        if (brush.contains(idx)) {
          drawsel(ptcol.get(idx), idx, i+1, k+2, i*128, k*106, 128, 106);
        }
      }
    }
  }
  if (drag && ptnew != null) {
    brush.addAll(ptnew);
    for (int idx : ptnew) {
      ptcol.set(idx, colx);
    }
  }
  for (int i = 0; i < 6; i++) {
    for (int k = 0; k < 6; k++) {
      if (ptsel != null) {
        for (int idx : ptnew) {
          drawsel(cols.length-1, idx, i+1, k+2, i*128, k*106, 128, 106);
        }
      }
    }
    //    println (ptidx);
  }
  ptprev = ptsel;
  //  drawscat(2, 4, 0, 256, 256, 256);
} 

void mouseClicked() {  
  int base = millis();
  mx = mouseX;
  my = mouseY;
  if (ptsel != null && !ptsel.isEmpty()) {
    if (! brush.removeAll(ptsel)) { // toggle selection
      brush.addAll(ptsel);
      for (int idx : ptsel) { // set all selected points to current color
        ptcol.set(idx, colx);
      }
    } 
    else {
      for (int idx : ptsel) { // set all selected points to clear
        ptcol.set(idx, 0);
      }
    }
  } 
  else {
    background(255);
    brush.clear();
    colx = 1;
    for (int idx : ptorder) { // set all points to clear
      ptcol.set(idx, 0);
    }
    for (int i = 0; i < 6; i++) {
      for (int k = 0; k < 6; k++) {
        drawscat(i+1, k+2, i*128, k*106, 128, 106);
      }
    }
  }
}

void mouseDragged() {  
  if (!drag) { // start new drag
    drag = true;
    if (ptsel == null || ptsel.isEmpty()) {
      background(255);
      for (int i = 0; i < 6; i++) {
        for (int k = 0; k < 6; k++) {
          drawscat(i+1, k+2, i*128, k*106, 128, 106);
        }
      }
      colx = colx+1 > cols.length-2 ? 1 : colx+1; // next color without brush
    } else {
      // max color under selection
      int[] ccols = new int [cols.length-1]; // initialized to zero?!
      int max = 0;
      int maxidx = 0;
      for (int idx : ptsel) {
        ccols[ptcol.get(idx)] += 1;
        if (ccols[ptcol.get(idx)] > max) {
          maxidx = ptcol.get(idx);
          max = ccols[maxidx];
        }
      }
      if (maxidx == 0) {
        colx = colx+1 > cols.length-2 ? 1 : colx+1; // next color without brush
      } else {
        colx = maxidx;
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
  myMessage.add("grain");   // works with the Grain-Synthdef loaded by SC
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
