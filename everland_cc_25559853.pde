// ---- libraries ----

// this pulls in the sound library i installed (sketch > import library)
// without it processing has no idea what SoundFile is and the songs won't work
import processing.sound.*;


// ---- images + where the player is ----

// PImage is just processing's word for a picture
// mapImg is the background and player is my character
PImage mapImg;
PImage player;

// where she is on screen in pixels, starts in the middle since the window is 800 x 800
float playerX = 400;
float playerY = 400;


// ---- score ----

// tokens is your score, starts at 0
// max is 13 because 3 songs = 3 tokens and heeseung gives 10
int tokens = 0;
int maxTokens = 13;


// ---- game states ----

// the game can only be doing one thing at a time (walking, quiz, start screen etc)
// so each thing gets a number and gameState remembers which one we're in
final int WALKING = 0;            // walking around normally
final int LISTENING = 1;          // song is playing
final int QUESTION = 2;           // song quiz pop up
final int RESULT = 3;             // right or wrong message after the quiz
final int HEESEUNG_QUESTION = 4;  // heeseung's yes or no pop up
final int HEESEUNG_RESULT = 5;    // what heeseung says back
final int START = 6;              // start screen
final int FINAL = 7;              // final score screen

// the game starts on the start screen
int gameState = START;


// ---- sanrio characters ----

// this is what each character says when you walk up to them in a string list
String[] animalText = {
  "cinnamoroll: hi! want to fly through the clouds with me?",
  "my melody: hello! i'm baking almond pound cake today!",
  "kuromi: hmph. what are you looking at?",
  "pompompurin: i'm so sleepy... is it pudding time yet?",
  "hello kitty: hi friend! welcome to our town!"
};

// where each character is on the map
float[] animalX = {40, 140, 285, 35, 247};
float[] animalY = {28, 58, 152, 280, 273};


// ---- heeseung ----

// where heeseung is on the 320 map
float heeseungX = 132;
float heeseungY = 287;

// his zone is smaller than everyone else's because his house is right next to him
// and i don't want the two zones overlapping
float heeseungDistance = 40;

// counts how many times in a row you've visited him
// goes back to 0 if you go see anyone or anything else in between
int heeseungVisits = 0;

// this remembers if you were next to him last frame, so a visit only counts
// when you first walk up and not every single frame you're standing there
boolean wasNearHeeseung = false;

// turns true once you've answered his question so it only happens once
boolean heeseungDone = false;

// remembers if you said yes ofc so he can reply properly
boolean heeseungSaidYes = false;

// his house in the bottom left, just shows a message, there's no quiz here
float heeseungHouseX = 105;
float heeseungHouseY = 266;

// where the yes ofc and no ty buttons go
// i use the same numbers to draw them and to check if they got clicked
float hsBtnY = 430;
float hsBtnW = 180;
float yesBtnX = 200;
float noBtnX = 420;


// ---- restart button ----

// where the restart button sits on the final screen
float restartX = 300;
float restartY = 500;
float restartW = 200;


// ---- music houses ----

// where the 3 music houses are on the 320 map
// house 1 = top left, house 2 = top right, house 3 = middle right
float[] houseX = {90, 253, 228};
float[] houseY = {90, 60, 228};

// welcome message for each house, same order as above
String[] houseWelcome = {
  "welcome to evan's house!",   // house 1
  "welcome to bnd's house!",    // house 2
  "welcome to txt's house!"     // house 3
};

// the song files in my data folder, names have to match exactly or it breaks
String[] songFiles = {"song1.mp3", "song2.mp3", "song3.mp3"};

// the second each song starts at so it skips the intro
float[] songStart = {45, 108, 46};

// A list of lists so that each row is one house
// and each row has the 4 options for that house's quiz
String[][] songOptions = {
  {"noise - evan", "going home - evan", "twilight - evan", "not enough - evan"},                                   // house 1
  {"serenade - bnd", "if i say i love you - bnd", "so lets go see the stars - bnd", "but i like you - bnd"},       // house 2
  {"miracle - txt", "wishlist - txt", "song of the stars - txt", "love language - txt"}                           // house 3
};

// which option is right for each house
// lists in code start counting at 0 not 1, so 0 = first button, 1 = second, 2 = third
// so this is noise, so lets go see the stars, wishlist
int[] correctAnswer = {0, 2, 1};

// holds the actual songs once they're loaded, new SoundFile[3] makes space for 3
SoundFile[] songs = new SoundFile[3];
// one place to change how loud the songs are, 0 = silent and 1 = full
float songVolume = 0.3;

// controls the volume of the whole game at once
Sound masterSound;

// keeps track of which houses are done so you can't keep redoing them for tokens
// they all start as false automatically
boolean[] houseDone = new boolean[3];

// how long the clip plays, it's in milliseconds so 10000 = 10 seconds
int listenTime = 10000;

// which house's quiz is happening right now
// -1 is just my way of saying "none" since 0 would mean house 1
int currentHouse = -1;

// which house you're standing next to, -1 means none
int nearHouse = -1;

// saves the time something started (like a song or a message)
// so i can check how long it's been and move on when it's time
int timerStart = 0;

// remembers if the last answer was right so the right message shows
boolean lastAnswerCorrect = false;


// ---- quiz button sizes ----

// all 4 answer buttons share these
// btnH also gets used for heeseung's buttons and restart so they're all the same height
float btnX = 150;
float btnW = 500;
float btnH = 60;


// ---- zones ----

// how close you have to be for a character or house to do something
float talkDistance = 80;

// ---- setup (runs once at the very start) ----

void setup() {
  // window size
  size(800, 800);

  // stops the high density warning and keeps things running smooth
  pixelDensity(1);

  // loading my pictures from the data folder
  mapImg = loadImage("map1.png");
  player = loadImage("sprite1.png");

  // loading all 3 songs here so they're ready to go
  // if i did this in draw it would freeze because draw runs 60 times a second
   for (int i = 0; i < songs.length; i++) {
    songs[i] = new SoundFile(this, songFiles[i]);
  }

  // turns the whole game down, not just one song
  masterSound = new Sound(this);
  masterSound.volume(songVolume);
}


// ---- draw (runs about 60 times a second, this is the game loop) ----

void draw() {
  // the map picture is 320 wide but the window is 800
  // so i times every map position by this (2.5) to make it fit
  float mapScale = width / 320.0;

  // -- drawing the map and player --
  // map goes first so it's underneath everything
  // drawing it every frame also wipes the last frame so the player doesn't leave a trail
  imageMode(CORNER);
  image(mapImg, 0, 0, width, height);

  // player goes on top, CENTER means her x and y is the middle of the picture
  // then i switch back to CORNER for everything else
  imageMode(CENTER);
  image(player, playerX, playerY, 135, 170);
  imageMode(CORNER);

  // -- start screen --
  // if we're on the start screen just show that and stop
  // return means skip the rest of draw for this frame
  if (gameState == START) {
    drawStartScreen();
    return;
  }

  // this holds whatever message needs to show this frame
  String message = "";

  // -- heeseung --
  // checking him first so he wins over his house since they're so close together

  // turning his map position into a screen position
  float hsx = heeseungX * mapScale;
  float hsy = heeseungY * mapScale;

  // dist() measures how far apart two points are
  // so this is true if you're close enough to him
  boolean nearHeeseung = dist(playerX, playerY, hsx, hsy) < heeseungDistance;

  // so this reads as: walking AND near him AND wasn't near last frame AND question not done yet
  // 3rd visit in a row and his question pops up
  if (gameState == WALKING && nearHeeseung && !wasNearHeeseung && !heeseungDone) {
    heeseungVisits++;
    if (heeseungVisits >= 3) {
      gameState = HEESEUNG_QUESTION;
    }
  }

  // saving if you're near him now so i can compare next frame
  wasNearHeeseung = nearHeeseung;

  // what he says depends on which visit you're on
  // once the question's answered he just tells you to go to the music houses
  if (nearHeeseung) {
    if (heeseungDone) {
      message = "heeseung: go visit the other music houses!";
    } else if (heeseungVisits == 1) {
      message = "heeseung: oh, hi!";
    } else if (heeseungVisits == 2) {
      message = "heeseung: omg you came back";
    }
  }

  // -- heeseung's house --
  // just shows a message, skipped if you're right next to heeseung himself
  // going here doesn't reset his streak because it's basically in the same spot
  float hhx = heeseungHouseX * mapScale;
  float hhy = heeseungHouseY * mapScale;
  
  if (!nearHeeseung && dist(playerX, playerY, hhx, hhy) < talkDistance) {
    message = "this is heeseung's house, say hi to heeseung!";
  }

  // -- sanrio characters --
  // goes through each character one at a time
  // if you're close enough their line becomes the message
  for (int i = 0; i < animalX.length; i++) {
    float ax = animalX[i] * mapScale;
    float ay = animalY[i] * mapScale;

    if (dist(playerX, playerY, ax, ay) < talkDistance) {
      message = animalText[i];
      heeseungVisits = 0;   // visiting someone else breaks the heeseung streak
    }
  }

  // -- music houses --
  // works out which house you're next to, resets to -1 first in case you're at none
  nearHouse = -1;
  for (int i = 0; i < houseX.length; i++) {
    float hx = houseX[i] * mapScale;
    float hy = houseY[i] * mapScale;

    if (dist(playerX, playerY, hx, hy) < talkDistance) {
      nearHouse = i;
      heeseungVisits = 0;   // going to a music house breaks the streak too
    }
  }

  // token counter in the top right
  drawTokens();

  // -- what actually shows on screen --
  // this part changes depending on what state the game is in

  // walking, show a character's message or a house message
  if (gameState == WALKING) {
    if (message.length() > 0) {
      showTextBox(message);
    } else if (nearHouse != -1) {
      if (houseDone[nearHouse]) {
        // already done this house
        showTextBox("try a new music house!");
      } else {
        // haven't done it yet
        showTextBox(houseWelcome[nearHouse] + "\npress space to play the song quiz!");
      }
    }
  }

  // listening, shows a countdown while the song plays
  // when time's up the song stops and the quiz comes up
  else if (gameState == LISTENING) {
    int secondsLeft = (listenTime - (millis() - timerStart)) / 1000 + 1;
    showTextBox("listen carefully... " + secondsLeft);
    if (millis() - timerStart > listenTime) {
      songs[currentHouse].stop();
      gameState = QUESTION;
    }
  }

  // the song quiz pop up
  else if (gameState == QUESTION) {
    drawQuestion();
  }

  // right or wrong message, shows the real answer if you got it wrong
  // after 2.5 seconds it goes back to walking, or the final screen if all 3 houses are done
  else if (gameState == RESULT) {
    if (lastAnswerCorrect) {
      showTextBox("correct! +1 token");
    } else {
      int c = correctAnswer[currentHouse];
      showTextBox("not quite! it was \"" + songOptions[currentHouse][c] + "\"");
    }
    if (millis() - timerStart > 2500) {
      if (allHousesDone()) {
        gameState = FINAL;
      } else {
        gameState = WALKING;
      }
    }
  }

  // heeseung's yes or no pop up
  else if (gameState == HEESEUNG_QUESTION) {
    drawHeeseungQuestion();
  }

  // what heeseung says back, shows for 2.5 seconds then back to walking
  else if (gameState == HEESEUNG_RESULT) {
    if (heeseungSaidYes) {
      showTextBox("heeseung: yay! welcome to everland! here are 10 tokens!");
    } else {
      showTextBox("heeseung: aw, okay... maybe next time!");
    }
    if (millis() - timerStart > 2500) {
      gameState = WALKING;
    }
  }

  // final score screen
  else if (gameState == FINAL) {
    drawFinalScreen();
  }
}


// ---- little helper functions ----

// checks if every music house is done
// if it finds any house not done it says false straight away, otherwise true
// that's how the game knows when to show the final screen
boolean allHousesDone() {
  for (int i = 0; i < houseDone.length; i++) {
    if (!houseDone[i]) {
      return false;
    }
  }
  return true;
}

// puts everything back to how it was at the start so you can play again
// the restart button calls this
void resetGame() {
  tokens = 0;
  playerX = 400;
  playerY = 400;
  for (int i = 0; i < houseDone.length; i++) {
    houseDone[i] = false;
    songs[i].stop();
  }
  heeseungVisits = 0;
  wasNearHeeseung = false;
  heeseungDone = false;
  heeseungSaidYes = false;
  currentHouse = -1;
  nearHouse = -1;
  gameState = START;
}

// checks if the mouse is inside a button  
// it's true only if the mouse is past the left edge AND before the right edge
// AND below the top AND above the bottom
// used for the pink hover and for working out what got clicked
boolean overButton(float x, float y, float w, float h) {
  return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
}

// spaces the 4 quiz buttons out evenly
// button 0 is at 300, then each one is 80 pixels lower than the last
float btnY(int i) {
  return 300 + i * 80;
}


// ---- drawing the pop ups and boxes ----

// draws one button with words on it, goes pink when the mouse is over it
// the quiz, heeseung and restart all use this so they look the same
void drawButton(String label, float x, float y, float w, float h) {
  stroke(120, 60, 80);
  strokeWeight(3);
  if (overButton(x, y, w, h)) {
    fill(255, 200, 220);   // pink when hovering
  } else {
    fill(255);             // white normally
  }
  rect(x, y, w, h, 15);

  fill(80, 40, 60);
  noStroke();
  textAlign(CENTER, CENTER);
  text(label, x + w / 2, y + h / 2);
}

// dark see through layer over the whole screen
// it goes behind pop ups so they stand out from the map
void dimBackground() {
  rectMode(CORNER);
  noStroke();
  fill(0, 120);
  rect(0, 0, width, height);
}

// start screen with the instructions, the game waits here until you press space
void drawStartScreen() {
  dimBackground();

  stroke(120, 60, 80);
  strokeWeight(4);
  fill(255, 240, 245);
  rect(120, 260, 560, 280, 25);

  fill(80, 40, 60);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(26);
  text("visit the music houses and characters and answer questions to collect tokens!",
       150, 290, 500, 160);

  textSize(20);
  text("press space to start", width / 2, 500);
  strokeWeight(1);
}

// final screen with your score out of 13 and the restart button
// shows up once all 3 houses are done
void drawFinalScreen() {
  dimBackground();

  stroke(120, 60, 80);
  strokeWeight(4);
  fill(255, 240, 245);
  rect(150, 220, 500, 380, 25);

  fill(80, 40, 60);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(34);
  text("you finished!", width / 2, 290);

  textSize(28);
  text("final score: " + tokens + " / " + maxTokens, width / 2, 370);

  // extra little message, perfect score or a hint if they missed heeseung's trick
  textSize(20);
  if (tokens == maxTokens) {
    text("perfect score!", width / 2, 425);
  } else if (!heeseungDone) {
    text("psst... did you find the special trick?", width / 2, 425);
  }

  textSize(24);
  drawButton("restart", restartX, restartY, restartW, btnH);
  strokeWeight(1);
}

// the song quiz pop up with the question and the 4 options for whichever house you're at
void drawQuestion() {
  dimBackground();

  stroke(120, 60, 80);
  strokeWeight(4);
  fill(255, 240, 245);
  rect(100, 180, 600, 460, 25);

  fill(80, 40, 60);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(30);
  text("what's the name of this song?", width / 2, 240);

  textSize(22);
  for (int i = 0; i < 4; i++) {
    drawButton(songOptions[currentHouse][i], btnX, btnY(i), btnW, btnH);
  }
  strokeWeight(1);
}

// heeseung's question pop up with the yes ofc and no ty buttons
void drawHeeseungQuestion() {
  dimBackground();

  stroke(120, 60, 80);
  strokeWeight(4);
  fill(255, 240, 245);
  rect(150, 280, 500, 240, 25);

  fill(80, 40, 60);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(26);
  text("heeseung: would you like to be an ever?", 180, 310, 440, 90);

  textSize(24);
  drawButton("yes ofc", yesBtnX, hsBtnY, hsBtnW, btnH);
  drawButton("no ty", noBtnX, hsBtnY, hsBtnW, btnH);
  strokeWeight(1);
}

// the little token counter in the top right so you can always see your score
void drawTokens() {
  float boxW = 130;
  float boxH = 36;
  float boxX = width - boxW - 15;   // 15 pixels in from the right
  float boxY = 15;                  // 15 pixels down from the top

  rectMode(CORNER);
  stroke(120, 60, 80);
  strokeWeight(2);
  fill(255, 240, 245);
  rect(boxX, boxY, boxW, boxH, 12);

  noStroke();
  fill(80, 40, 60);
  textSize(18);
  textAlign(CENTER, CENTER);
  text("tokens: " + tokens, boxX + boxW / 2, boxY + boxH / 2);
  strokeWeight(1);
}

// text box in the middle of the screen
// used for pretty much every message, characters, houses, countdown, results
// msg is whatever message gets passed in when i call showTextBox(...)
void showTextBox(String msg) {
  float boxW = width - 80;
  float boxH = 120;
  float boxX = 40;
  float boxY = height / 2 - boxH / 2;   // puts it in the middle going down

  rectMode(CORNER);
  stroke(120, 60, 80);
  strokeWeight(4);
  fill(255, 240, 245);
  rect(boxX, boxY, boxW, boxH, 20);

  noStroke();
  fill(80, 40, 60);
  textSize(24);
  textAlign(LEFT, TOP);
  text(msg, boxX + 30, boxY + 25, boxW - 60, boxH - 30);
  strokeWeight(1);
}


// ---- mouse clicks (runs once every time you click) ----

void mousePressed() {
  // -- song quiz answers --
  // checks which of the 4 buttons got clicked
  // then marks the house as done and goes to the result message
  if (gameState == QUESTION) {
    for (int i = 0; i < 4; i++) {
      if (overButton(btnX, btnY(i), btnW, btnH)) {
        lastAnswerCorrect = (i == correctAnswer[currentHouse]);
        if (lastAnswerCorrect) {
          tokens++;
        }
        houseDone[currentHouse] = true;
        timerStart = millis();
        gameState = RESULT;
      }
    }
  }

  // -- heeseung's question --
  // yes ofc = 10 tokens no ty = nothing
  // either way it's marked done so it won't come up again
  else if (gameState == HEESEUNG_QUESTION) {
    if (overButton(yesBtnX, hsBtnY, hsBtnW, btnH)) {
      heeseungSaidYes = true;
      tokens += 10;
      heeseungDone = true;
      timerStart = millis();
      gameState = HEESEUNG_RESULT;
    } else if (overButton(noBtnX, hsBtnY, hsBtnW, btnH)) {
      heeseungSaidYes = false;
      heeseungDone = true;
      timerStart = millis();
      gameState = HEESEUNG_RESULT;
    }
  }

  // -- restart --
  // on the final screen, clicking restart resets everything
  else if (gameState == FINAL) {
    if (overButton(restartX, restartY, restartW, btnH)) {
      resetGame();
    }
  }
}


// ---- key presses (runs once every time a key is pressed) ----

void keyPressed() {
  // -- starting the game --
  // on the start screen only space does anything
  if (gameState == START) {
    if (key == ' ') {
      gameState = WALKING;
    }
    return;
  }

  // ignores every key while a pop up or song is going
  // so you can't walk off in the middle of a quiz
  if (gameState != WALKING) {
    return;
  }

  // -- starting a song quiz --
  // if you're at a house you haven't done yet and press space
  if (key == ' ' && nearHouse != -1 && !houseDone[nearHouse]) {
    currentHouse = nearHouse;
    songs[currentHouse].jump(songStart[currentHouse]);
    songs[currentHouse].amp(songVolume);   // jump resets the volume so i set it again here
    timerStart = millis();
    gameState = LISTENING;
    return;
  }

  // -- moving --
  // arrow keys move her 10 pixels each press
  // each direction has a limit so she can't walk off the edge of the map
  if (keyCode == LEFT) {
    if (playerX > 40) {
      playerX -= 10;
    }
  }
  if (keyCode == RIGHT) {
    if (playerX < 760) {
      playerX += 10;
    }
  }
  if (keyCode == UP) {
    if (playerY > 67) {
      playerY -= 10;
    }
  }
  if (keyCode == DOWN) {
    if (playerY < 723) {
      playerY += 10;
    }
  }
}  
