import processing.sound.*;
import processing.video.*;

SoundFile soundFile;
Amplitude amp;
Movie effectMov;
PImage img, blurredImg;
float scale;

float prevBrightness; //전 프레임의 밝기값
float brightnessUpdateTime; // 밝기값 업데이트된 시간
float brightnessUpdateDelay = 250; // 밝기값 업데이트 간격
float brightnessHoldTime = 250; // 밝기 유지 시간

int waveformHeight = 500; // 파형의 세로 길이

void setup() {
  //fullScreen();
  size(1280,720);
  background(10,10,50,50);
  
  img = loadImage("RUAMANOAWOMEN.png");

  //배경 이미지를 흐릿하게 그리기
  blurredImg = img.copy();
  blurredImg.filter(BLUR, 10); //블러
  
  soundFile = new SoundFile(this, "Hallowed - lil drive.mp3");
  amp = new Amplitude(this);
  amp.input(soundFile);
  
  effectMov = new Movie(this, "effect.mov");
  effectMov.loop();
  effectMov.speed(1.5);
}

void movieEvent(Movie m) {
  m.read(); //영상 프레임 업데이트
  if (soundFile.isPlaying() == false) {
    soundFile.play();
  }
}

void drawEffectMovie() {
  //색상 지정
  color[] colors = {color(255, 255, 0), color(0, 127, 255), color(255, 255, 255)};
  
  //각도, 위치 랜덤 지정
  float angle = random(45);
  float posX = random(width);
  float posY = random(height);
  int randomColor = int(random(colors.length));
  
  pushMatrix();
  translate(posX, posY);
  rotate(radians(angle));  
  tint(colors[randomColor]);

  //소리 크기에 따라 크기 조절
  float videoScale = map(amp.analyze(), 0.25, 0.5, 0.75, 1);
  if (amp.analyze() < 0.6) {
    // 소리가 작을 때 생겨난 이펙트 영상 크기 줄이기
    videoScale = max(0, videoScale - 0.5);
  } else {
    // 소리가 클 때 생겨난 이펙트 영상 크기 늘리기
    videoScale = min(1.12, videoScale + 0.12);
  }
  float videoWidth = effectMov.width * videoScale;
  float videoHeight = effectMov.height * videoScale;
  
  imageMode(CENTER);
  blendMode(ADD);
  image(effectMov, 0, 0, videoWidth, videoHeight);
  blendMode(BLEND);
  popMatrix();
}

void draw() {
  //이전 프레임에서 그렸던 이미지 지우기
  clear();
  
  //배경 이미지 크기를 창에 맞게 조절하기
  float bgScale = 1 + 0.5 * max(0, amp.analyze() - 1);
  float bgImageWidth = width * bgScale;
  float bgImageHeight = width * (float)img.height/img.width * bgScale;
  
  //배경 이미지 그리기
  float brightnessValue = 100 - 60 * (1 - amp.analyze());
  tint(255, brightnessValue);
  imageMode(CENTER);
  
  //배경 이미지 움직임 범위
  float xRange = 5000;
  float yRange = 5000;

  //소리 크기에 따라 배경 이미지 상하좌우 이동
  float xOff = map(amp.analyze(), 0, 1, -xRange, xRange);
  float yOff = map(amp.analyze(), 0, 1, -yRange, yRange);

  //이동 범위 지정
  float noiseTime = millis() * 0.0001;
  float xNoise = map(noise(floor(noiseTime) + xOff), 0, 1, -10, 10);
  float yNoise = map(noise(floor(noiseTime) + yOff), 0, 1, -10, 10);

  //배경 이미지 그리기
  image(blurredImg, width/2 + xNoise, height/2 + yNoise, bgImageWidth, bgImageHeight);
  
  //하늘색 파형
  pushMatrix();
  translate(width/2, height/2);
  stroke(0, 127, 255);
  beginShape();
  for (int i = 0; i < width; i++) {
    float x = map(i, 0, width, -width / 2, width / 2);
    float phase = TWO_PI / width;
    float y = map(amp.analyze(), 0, 1, -waveformHeight / 2, waveformHeight / 2) * cos(phase * i * 20);
    y *= sin(TWO_PI * i * 20 / width);
    
    // 중앙으로부터 떨어진 거리에 따라 y값 조정
    float distanceFromCenter = abs(x);
    float heightScale = map(distanceFromCenter, 0, width/2, 0.05, 2.5);
    y *= heightScale;
    
    if (amp.analyze() < 0.1) {
      y = + 10;
    } else {
      y *= cos(20 * PI * (i + millis() * 1) / width);
    }
    vertex(x + 10, y - 10); //오른쪽 아래에 위치
  }
  endShape();
  popMatrix();

  //분홍색 파형
  pushMatrix();
  translate(width/2, height/2);
  stroke(255, 0, 127);
  beginShape();
  for (int i = 0; i < width; i++) {
    float x = map(i, 0, width, -width / 2, width / 2);
    float phase = TWO_PI / width;
    float y = map(amp.analyze(), 0, 1, -waveformHeight / 2, waveformHeight / 2) * cos(phase * i * 20);
    y *= sin(TWO_PI * i * 20 / width);
    
    // 중앙으로부터 떨어진 거리에 따라 y값 조정
    float distanceFromCenter = abs(x);
    float heightScale = map(distanceFromCenter, 0, width/2, 0.05, 2.5);
    y *= heightScale;
    
    if (amp.analyze() < 0.1) {
      y = - 10;
    } else {
      y *= cos(20 * PI * (i + millis() * 1) / width);
    }
    vertex(x - 10, y + 10); //왼쪽 위에 위치
  }
  endShape();
  popMatrix();
  
  //중앙 흰색 파형
  pushMatrix(); //좌표계 저장
  translate(width/2, height/2); //회전 중심점
  stroke(255);
  strokeWeight(3);
  noFill();
  curveTightness(0.3); //곡선이 휘는 정도
  beginShape(); //그리기 시작
  for (int i = 0; i < width; i++) {
    float x = map(i, 0, width, -width / 2, width / 2);
    float phase = TWO_PI / width;
    float y = map(amp.analyze(), 0, 1, -waveformHeight / 2, waveformHeight / 2) * cos(phase * i * 20);
    y *= sin(TWO_PI * i * 20 / width);
    
    //중앙으로부터 떨어진 거리에 따라 y값 조정
    float distanceFromCenter = abs(x);
    float heightScale = map(distanceFromCenter, 0, width/2, 0.05, 2.5);
    y *= heightScale;
    
    if (amp.analyze() < 0.1) {
      y = 0;
    } else {
      y *= cos(20 * PI * (i + millis() * 1) / width);
      float glitchValue = random(-3, 3); //글리치 효과
      y += glitchValue;
    }
    curveVertex(x, y); //파형 꼭짓점
  }  
  endShape(); //그리기 종료
  popMatrix(); //좌표계 복구

  //이미지 그리기
  scale = (float(height) / img.height) * (1 + 0.15 * amp.analyze());
  tint(255, 255);
  imageMode(CENTER);
  float imgWidth = img.width * scale;
  float imgHeight = img.height * scale;
  image(img, width/2, height/2, imgWidth/1.5, imgHeight/1.5);
  
  //영상 그리기
  if (amp.analyze() > 0.6) {
    drawEffectMovie(); // 영상 그리기 함수 호출

    // 영상이 끝나면 초기 위치로 되돌리기 및 배속 조절
    if (effectMov.time() >= effectMov.duration() - 0.1) {
      effectMov.jump(0);
      effectMov.speed(1.5);
    }
  }
  
  //밝기값 업데이트 안되면, 전 밝기값 사용
  if (millis() - brightnessUpdateTime > brightnessUpdateDelay) {
    brightnessUpdateTime = millis();
    prevBrightness = brightnessValue;
  } else {
    if (millis() - brightnessUpdateTime > brightnessHoldTime) {
      brightnessValue = prevBrightness;
    }
  }
}
