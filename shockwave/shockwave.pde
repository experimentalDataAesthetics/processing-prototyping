import java.util.*;
import java.lang.Math;

import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;
 
BufferedReader reader;
String line;
ArrayList<ArrayList<Float>> pts = new ArrayList<ArrayList<Float>>();
// distance
//public TreeMap<Float, Integer> dds;
ArrayList<Float> dds;
ArrayList<Integer> mpts = new ArrayList<Integer>();

// White (inivisible datapoints)
color c1 = color(255);
color c2 = color(255);

// color c1 = color(190);
// color c2 = color(0);

int dim1 = 2;
int dim2 = 4;
int dim3col = 10;
float speed = 20;
float volume = 0.1;

//

int baset = 0;
int mx = 0;
int my = 0;

int idx = 0;



void setup() {
  size(700, 400);
  
  
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,57110);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress("127.0.0.1",57110);
  
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
      pts.add(pt);
      String[] pieces = split(line, ',');
      // bug: this assumes that all records have equal length
      for (String pp : pieces) {
        pt.add(float(pp));
      }
    }
  } 
  while (line != null); 

  mpts = new ArrayList<Integer>();
  for (int i = 0; i < pts.size(); i++) {
    mpts.add(i);
  }

  smooth();
  noStroke();
  print(mpts.size()+" "+pts.size()+" "+pts.get(0).size());
}

void draw() {
  //   println(frameRate);
  background(255);
  noStroke();
  for (ArrayList<Float> pt : pts) {
    //    print(10* pt.get(4)+" ");
    /*
    int x = int(100 * pt.get(2));
    int y = int(10 * pt.get(4));
    */
    int x = int(100 * pt.get(dim1));
    int y = int(10 * pt.get(dim2));
    fill(lerpColor(c1, c2, .1 * pt.get(dim3col)));
    ellipse(x, y, 5, 5);
  }
if (true) {
  float dt = speed*(millis() - baset);
  // last point in intex
  if (dds != null && dt <= 10 * dds.get(mpts.get(mpts.size()-1))+100) {
    // show shockwave
    noFill();
    stroke(0);
    // ellipse takes diam == 2* distance
    ellipse(mx, my, .2*dt, .2*dt);    
    // get trigger
    for ( ; (idx < mpts.size()-1) && (dt >= 10 * dds.get(mpts.get(idx))) ; idx++) {
          int x = int(100 * pts.get(mpts.get(idx)).get(dim1));
          int y = int(10 * pts.get(mpts.get(idx)).get(dim2));
          fill(lerpColor(c1, c2, .1 * pts.get(mpts.get(idx)).get(dim3col)));
          
          //explosion
          ellipse(x, y, 10, 10);
          
      
          // send osc
          OscMessage myMessage = new OscMessage("/s_new");
          myMessage.add("spring");
          myMessage.add(-1); 
          myMessage.add(0); 
          myMessage.add(1);
          myMessage.add("springfac"); 
          
         // myMessage.add(15000); 
          myMessage.add(1100); 
          myMessage.add("damp"); 
          myMessage.add(0.0007);
          myMessage.add("amp"); 
          myMessage.add(volume);  
          oscP5.send(myMessage, myRemoteLocation);          
         
    }
  } 
} else {
  if(dds != null) {
    noFill();
    stroke(0);
//    ellipse(mx, my, 2*dds.get(0), 2*dds.get(0));    
    ellipse(mx, my, 2*dds.get(mpts.get(mpts.size()-1)), 2*dds.get(mpts.get(mpts.size()-1)));    
  }
}
} 

void mouseClicked() {
  baset = millis();
  mx = mouseX;
  my = mouseY;
  dds = new ArrayList<Float>();
  //index into points
  for (ArrayList<Float> pt : pts) {
    float dx = 100 * pt.get(dim1) - mx;
    float dy = 10 * pt.get(dim2) - my;
    dds.add(sqrt(dx*dx+dy*dy));
  }

  Collections.sort(mpts, 
                   new Comparator<Integer>() {
                     public int compare(Integer a, Integer b) {
                       return dds.get(a).compareTo(dds.get(b));
                     }
                   });
    // reset index to start
    idx = 0;
/* 
   for (Integer m : mpts) {
     print(dds.get(m)+" ");
   }
  println(mpts.size()+" "+dds.size());
  */
}

