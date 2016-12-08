/*
Particles text effects

Thanks to Daniel Shiffman for explanation on arrival behavior (shiffman.net)
Author: Jason Labbe
Site: jasonlabbe3d.com
Modified by: Alex Korzh
*/


// Global variables
ArrayList<Particle> particles = new ArrayList<Particle>();
int pixelSteps = 6; // Amount of pixels to skip
ArrayList<String> words = new ArrayList<String>();
int wordIndex = 0;
color bgColor = color(0, 40);
String fontName = "Brandon Grotesque Medium";


class Particle {
  PVector pos = new PVector(0, 0);
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  PVector target = new PVector(0, 0);

  float closeEnoughTarget = 50;
  float maxSpeed = 4.5;
  float maxForce = 0.2;
  float particleSize = 2.5;
  boolean isKilled = false;
  boolean flashIsUp = false;

  color startColor = color(0);
  color targetColor = color(0);
  float targetSaturation = 100;
  float targetBrightness = 70;
  float targetHue = 0;
  float currentSaturation = 100;
  float currentBrightness = 70;
  float currentHue;
  float colorWeight = 0;
  float shininessColorWeight;
  float colorBlendRate = 0.025;

  void move() {
    // Check if particle is close enough to its target to slow down
    float proximityMult = 1.0;
    float distance = dist(this.pos.x, this.pos.y, this.target.x, this.target.y);
    if (distance < this.closeEnoughTarget) {
      proximityMult = distance/this.closeEnoughTarget;
    }

    // Add force towards target
    PVector towardsTarget = new PVector(this.target.x, this.target.y);
    towardsTarget.sub(this.pos);
    towardsTarget.normalize();
    towardsTarget.mult(this.maxSpeed*proximityMult);

    PVector steer = new PVector(towardsTarget.x, towardsTarget.y);
    steer.sub(this.vel);
    steer.normalize();
    steer.mult(this.maxForce);
    this.acc.add(steer);

    // Move particle
    this.vel.add(this.acc);
    this.pos.add(this.vel);
    this.acc.mult(0);
  }

  void draw() {
    // Draw particle
    this.currentHue = lerp (hue(this.startColor),hue(this.targetColor), this.colorWeight);
    if(this.currentSaturation >= 90 && random(0, 235) < 2){
      this.flashIsUp = true;
      this.targetSaturation = 0;
      this.targetBrightness = 95;
    } else if (this.currentSaturation <= 10) {
      this.flashIsUp = false;
      this.targetSaturation = 100;
      this.targetBrightness = 70;
    }
    if(!this.flashIsUp && !this.isKilled){
       this.currentSaturation = lerp (this.currentSaturation,this.targetSaturation, 0.2);
       this.currentBrightness = lerp (this.currentBrightness,this.targetBrightness, 0.2);
    }else if (this.flashIsUp && !this.isKilled){
       this.currentSaturation = lerp (this.currentSaturation,this.targetSaturation, 0.8);
       this.currentBrightness = lerp (this.currentBrightness,this.targetBrightness, 0.8);
    } else {
      this.currentBrightness = lerp (brightness(this.startColor),brightness(this.targetColor), this.colorWeight);
      this.currentSaturation = lerp (saturation(this.startColor),saturation(this.targetColor), this.colorWeight);
    }
    colorMode(HSB, 360, 100, 100);
    color currentColor = color(this.currentHue, this.currentSaturation, this.currentBrightness);
    noStroke();
    fill(currentColor);
    ellipse(this.pos.x, this.pos.y, this.particleSize, this.particleSize);

    // Blend towards its target color
    if (this.colorWeight < 1.0) {
      this.colorWeight = min(this.colorWeight+this.colorBlendRate, 1.0);
    }
  }

  void kill() {
    if (!this.isKilled) {
      // Set its target outside the scene
      PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
      this.target.x = randomPos.x;
      this.target.y = randomPos.y;

      // Begin blending its color to black
      colorMode(HSB,360, 100, 100);
      this.startColor = color(this.currentHue,this.currentSaturation, this.currentBrightness);
      colorMode(HSB,360, 100, 100);
      this.targetColor = color(this.currentHue, 100, 0);
      this.colorWeight = 0;

      this.isKilled = true;
    }
  }
}


// Picks a random position from a point's radius
PVector generateRandomPos(int x, int y, float mag) {
  PVector sourcePos = new PVector(x, y);
  PVector randomPos = new PVector(random(0, width), random(0, height));

  PVector direction = PVector.sub(randomPos, sourcePos);
  direction.normalize();
  direction.mult(mag);
  sourcePos.add(direction);

  return sourcePos;
}


// Makes all particles draw the next word
void nextWord(String word) {
  // Draw word in memory
  PGraphics pg = createGraphics(width, height);
  pg.beginDraw();
  pg.fill(0);
  if(word == "\u2764"){
    pg.textSize(200);
  }else{
    pg.textSize(130);
  }
  pg.textAlign(CENTER);
  PFont font = createFont(fontName, 130);
  if(word == "\u2764"){
    font = createFont(fontName, 200);
  }
  pg.textFont(font);
  pg.text(word, width/2, height/2);
  pg.endDraw();
  pg.loadPixels();

  // Next color for all pixels to change to
  colorMode(HSB, 360, 100, 100);
  color newColor = color(random(170, 285), random(70, 100), random(70, 100));

  int particleCount = particles.size();
  int particleIndex = 0;

  // Collect coordinates as indexes into an array
  // This is so we can randomly pick them to get a more fluid motion
  ArrayList<Integer> coordsIndexes = new ArrayList<Integer>();
  for (int i = 0; i < (width*height)-1; i+= pixelSteps) {
    coordsIndexes.add(i);
  }

  for (int i = 0; i < coordsIndexes.size (); i++) {
    // Pick a random coordinate
    int randomIndex = (int)random(0, coordsIndexes.size());
    int coordIndex = coordsIndexes.get(randomIndex);
    coordsIndexes.remove(randomIndex);
    
    // Only continue if the pixel is not blank
    if (pg.pixels[coordIndex] != 0) {
      // Convert index to its coordinates
      int x = coordIndex % width;
      int y = coordIndex / width;

      Particle newParticle;

      if (particleIndex < particleCount) {
        // Use a particle that's already on the screen 
        newParticle = particles.get(particleIndex);
        newParticle.isKilled = false;
        particleIndex += 1;
      } else {
        // Create a new particle
        newParticle = new Particle();
        
        PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
        newParticle.pos.x = randomPos.x;
        newParticle.pos.y = randomPos.y;
        
        newParticle.maxSpeed = random(2.0, 5.0);
        newParticle.maxForce = newParticle.maxSpeed*0.025;
        newParticle.particleSize = random(3, 6);
        newParticle.colorBlendRate = random(0.0025, 0.03);
        
        particles.add(newParticle);
      }
      
      // Blend it from its current color
      newParticle.startColor = color(random(170, 285), random(50, 100), random(50, 100));
      newParticle.targetColor = newColor;
      newParticle.colorWeight = 0;
      
      // Assign the particle's new target to seek
      newParticle.target.x = x;
      newParticle.target.y = y;
    }
  }

  // Kill off any left over particles
  if (particleIndex < particleCount) {
    for (int i = particleIndex; i < particleCount; i++) {
      Particle particle = particles.get(i);
      particle.kill();
    }
  }
}


void setup() {
  size(950, 400);
  background(0);

  words.add("");
  words.add("ИРИША");
  words.add("С ДНЕМ");
  words.add("РОЖДЕНИЯ");
  words.add("ТЫ");
  words.add("САМАЯ");
  words.add("ЛУЧШАЯ");
  words.add("\u2764");
  words.add("");

  nextWord(words.get(wordIndex));
}


void draw() {
  // Background & motion blur
  fill(bgColor);
  noStroke();
  rect(0, 0, width*2, height*2);

  for (int x = particles.size ()-1; x > -1; x--) {
    // Simulate and draw pixels
    Particle particle = particles.get(x);
    particle.move();
    particle.draw();

    // Remove any dead pixels out of bounds
    if (particle.isKilled) {
      if (particle.pos.x < 0 || particle.pos.x > width || particle.pos.y < 0 || particle.pos.y > height) {
        particles.remove(particle);
      }
    }
  }

  // Display control tips  fill(255-red(bgColor));
  //textSize(9);
  //String tipText = "Left-click for a new word.";
  //tipText += "\nDrag right-click over particles to interact with them.";
  //tipText += "\nPress any key to toggle draw styles.";
  //text(tipText, 10, height-40);
}


// Show next word
void mousePressed() {
  if (mouseButton == LEFT) {
    wordIndex += 1;
    if (wordIndex > words.size()-1) { 
      wordIndex = 0;
    }
    nextWord(words.get(wordIndex));
  }
}


// Kill pixels that are in range
void mouseDragged() {
  if (mouseButton == RIGHT) {
    for (Particle particle : particles) {
      if (dist(particle.pos.x, particle.pos.y, mouseX, mouseY) < 50) {
        particle.kill();
      }
    }
  }
}