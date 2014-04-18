import java.util.*;
import java.lang.Math;
/*
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;
*/


BufferedReader reader;
String line;
ArrayList<ArrayList<Float>> pts = new ArrayList<ArrayList<Float>>();
ArrayList<Float> mins = new ArrayList<Float>();
ArrayList<Float> maxs = new ArrayList<Float>();

TreeSet<Integer> brush = new TreeSet<Integer>();
Boolean drag = false;
int ptidx = -1;


color c1 = color(255, 0, 0);
color c2 = color(0, 0, 255);
int mx = 0;
int my = 0;

void setup() {
  /*
  oscP5 = new OscP5(this, 57110);
  myRemoteLocation = new NetAddress("127.0.0.1", 57110);
*/
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
    for (int i = 0; i < mins.size(); i++) {
      if (pt.get(i) < mins.get(i)) {
        mins.set(i, pt.get(i));
      } 
      else if (pt.get(i) > maxs.get(i)) {
        maxs.set(i, pt.get(i));
      }
    }
  }
  //  print(pts.size()+" "+pts.get(0).size());
}

int closept(int m, int n, int x, int y, int xsz, int ysz) {
  if (mouseX < x || mouseX > x+xsz || mouseY < y || mouseY > y+ysz) { 
    // outside box
    return -1;
  } 
  else { 
    // inside box
    x+=3;
    y+=3;
    xsz-=5;
    ysz-=5;

    float mind = 6.*6./4.;
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
      float tmp = xd*xd+yd*yd;
      if (tmp < mind) {
        mind = tmp;
        minidx = pts.indexOf(pt);
      }
    }
    return minidx;
    //    return mind > 5.*5./4. ? -1 : minidx;
  }
}

void drawscat(int m, int n, int x, int y, int xsz, int ysz) {
  stroke(128);
  noFill();
  rect(x, y, xsz, ysz);

  x+=3;
  y+=3;
  xsz-=5;
  ysz-=5;

  noStroke();
  fill(0);
  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  for (ArrayList<Float> pt : pts) {
    int xx = int(xxsc * (pt.get(m)-xmin));
    int yy = int(yysc * (pt.get(n)-ymin));
    ellipse(x+xx, y+yy, 5, 5);
  }
}

void drawsel(color c, int idx, int m, int n, int x, int y, int xsz, int ysz) {

  x+=3;
  y+=3;
  xsz-=5;
  ysz-=5;

  noStroke();
  fill(c);
  float xmin = mins.get(m);
  float ymin = mins.get(n);
  float xxsc = xsz / (maxs.get(m)-xmin);
  float yysc = ysz / (maxs.get(n)-ymin);
  ArrayList<Float> pt = pts.get(idx);
  int xx = int(xxsc * (pt.get(m)-xmin));
  int yy = int(yysc * (pt.get(n)-ymin));
  ellipse(x+xx, y+yy, 5, 5);
}

void draw() {
  //   println(frameRate);
  int dt = millis();
  background(255);
  ptidx = -1;
  for (int i = 1; i < 9; i++) {
    for (int k = 2; k < 8; k++) {
      if (i < k) {
        drawscat(i, k, (i-1)*128, (k-2)*106, 128, 106);
        int tmp = closept(i, k, (i-1)*128, (k-2)*106, 128, 106);
        if (tmp != -1) {
          ptidx = tmp;
        }
      }
    }
  }
  if (drag && ptidx != -1) {
    brush.add(ptidx);
  }
  for (int i = 1; i < 9; i++) {
    for (int k = 2; k < 8; k++) {
      if (i < k) {
        for (int idx : brush) {
          drawsel(color(255, 0, 0), idx, i, k, (i-1)*128, (k-2)*106, 128, 106);
        }
        if (ptidx != -1) {
          drawsel(color(255, 255, 0), ptidx, i, k, (i-1)*128, (k-2)*106, 128, 106);
        }
      }
    }
    //    println (ptidx);
  }
  //  drawscat(2, 4, 0, 256, 256, 256);
} 

void mouseClicked() {  
  int base = millis();
  mx = mouseX;
  my = mouseY;

  if (ptidx != -1) {
    if (! brush.remove(ptidx)) { // toggle selection
      brush.add(ptidx);
    }
  } 
  else {
    //brush.clear();
  }
}

void mouseDragged() {  
  if (!drag) {
    brush.clear();
    drag = true;
    if (ptidx != -1) {
      brush.add(ptidx);
    }
  }
}

void mouseReleased() {  
  drag = false;
}

