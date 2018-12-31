import java.util.ArrayList;

StartScene startScene;
GameScene gameScene;
GameOverScene gameOverScene;

int[][] field;
final int squareSize = 30;

void setup() {
  size(760, 660);
  textAlign(CENTER);
  startScene = new StartScene();
}

void draw() {
  background(255);

  if (startScene.isActive) {
    startScene.update();
  } else if (gameScene.isActive) {
    gameScene.update();
  } else if (gameOverScene.isActive) {
    gameOverScene.update();
  }
}

void keyPressed() {
  if (startScene.isActive) {
    startScene.keyPressed();
  } else if (gameScene.isActive) {
    gameScene.keyPressed();
  } else if (gameOverScene.isActive) {
    gameOverScene.keyPressed();
  }
}

abstract class Scene {
  boolean isActive;

  Scene() {
    this.isActive = true;
  }

  abstract void update();
  abstract void keyPressed(); 

  void willDisappear() {
    this.isActive = false;
  }
}

class StartScene extends Scene {
  @Override
  void update() {
    fill(0);
    textSize(70);
    text("T E T R I S", 0, 200, 760, 100);
    textSize(50);
    text("Press S to start", 0, 400, 760, 100);
  }

  @Override
  void keyPressed() {
    if (key == 's') {
      this.willDisappear();
    }
  }

  @Override
  void willDisappear() {
    super.willDisappear();
    gameScene = new GameScene();
  }
}

class GameScene extends Scene {
  FieldController fc;
  Tetromino fallingTetromino;
  int score;
  int lines;
  int nextTetrominoType;
  int updateCount;
  int tetrominoCount;

  GameScene() {
    super();

    field = new int[20][10];
    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 10; j++) {
        field[i][j] = 0;
      }
    }

    this.fc = new FieldController();
    this.score = 0;
    this.lines = 0;
    this.nextTetrominoType = 0;
    this.updateCount = 0;
    this.tetrominoCount = 0;
  }

  @Override
  void update() {
    this.updateCount++;

    fill(0);
    textSize(30);
    text("SCORE", 0, 150, 200, 50);
    text(String.valueOf(this.score), 0, 200, 200, 50);
    text("LINES", 0, 300, 200, 50);
    text(String.valueOf(this.lines), 0, 350, 200, 50);

    if (this.fc.shouldProduceTetromino) {
      if (this.nextTetrominoType == 0) { // when producing first tetromino
        this.nextTetrominoType = this.nextTetrominoType();
      }

      this.fallingTetromino = new Tetromino(this.nextTetrominoType, false);
      this.tetrominoCount++;
      this.nextTetrominoType = this.nextTetrominoType();
      this.fc.shouldProduceTetromino = false;
    }

    this.fc.draw();

    fill(0);
    textSize(30);
    text("NEXT", 560, 150, 200, 50);
    this.drawNextTetromino();

    if (this.fc.isHighlightingLines) {
      if (this.updateCount > 30) {
        this.fc.eraseLines();
        this.fc.shouldProduceTetromino = true;
        this.updateCount = 0;
      }

      return;
    }

    if (this.updateCount > 60 / pow(1.01, this.tetrominoCount)) {
      this.updateCount = 0;

      if (this.fallingTetromino.canMove(DOWN)) {
        this.fallingTetromino.move(DOWN);
      } else {
        this.score++;
        
        ArrayList<Integer> compLines = this.fc.completedLines();
        if (compLines.size() > 0) {
          this.fc.highlightLines(compLines);
          this.score += compLines.size() * compLines.size() * 10;
          this.lines += compLines.size();
        } else {
          if (this.fc.isGameOver()) {
            this.willDisappear();
          }

          this.fc.shouldProduceTetromino = true;
        }
      }
    }
  }

  @Override
  void keyPressed() {
    if (keyCode == RIGHT) {
      if (this.fallingTetromino.canMove(RIGHT)) {
        this.fallingTetromino.move(RIGHT);
      }
    }
    if (keyCode == LEFT) {
      if (this.fallingTetromino.canMove(LEFT)) {
        this.fallingTetromino.move(LEFT);
      }
    }
    if (keyCode == DOWN) {
      if (this.fallingTetromino.canMove(DOWN)) {
        this.fallingTetromino.move(DOWN);
      }
    }
    if (key == 'a') {
      int[][] rotatedPosition = this.fallingTetromino.rotatedPosition(LEFT);
      if (rotatedPosition.length > 0) { // the tetromino can rotate
        this.fallingTetromino.rotate(rotatedPosition);
      }
    }
    if (key == 'd') {
      int[][] rotatedPosition = this.fallingTetromino.rotatedPosition(RIGHT);
      if (rotatedPosition.length > 0) { // the tetromino can rotate
        this.fallingTetromino.rotate(rotatedPosition);
      }
    }
  }

  void drawNextTetromino() {
    fill(this.fc.fillValue(this.nextTetrominoType));
    Tetromino nextTetromino = new Tetromino(this.nextTetrominoType, true);

    int marginFix = 0;
    if (this.nextTetrominoType == 1 || this.nextTetrominoType == 2) {
      marginFix = -15;
    }
    for (int i = 0; i < 4; i++) {
      int[] partPosition = nextTetromino.position[i];
      rect((partPosition[0] - 3) * squareSize + 615 + marginFix, partPosition[1] * squareSize + 220, squareSize, squareSize);
    }
  }

  int nextTetrominoType() {
    int type = 0;
    int fallingTetrominoType = 0;
    if (this.fallingTetromino != null) {
      fallingTetrominoType = this.fallingTetromino.type;
    }
    
    do {
      type = round(random(0.5, 7.5));
    } while (type == fallingTetrominoType || type > 7);

    return type;
  }

  @Override
  void willDisappear() {
    super.willDisappear();
    gameOverScene = new GameOverScene(this.score, this.lines);
  }
}

class FieldController {
  boolean shouldProduceTetromino;
  boolean isHighlightingLines;

  FieldController() {
    this.shouldProduceTetromino = true;
    this.isHighlightingLines = false;
  }

  void draw() {
    strokeWeight(1);

    for (int i = 0; i < 22; i++) {
      for (int j = 0; j < 12; j++) {

        // draw wall
        if (i == 0 || i == 21 || j == 0 || j == 11) {
          fill(100);
          rect(j * squareSize + 200, i * squareSize, squareSize, squareSize);
          continue;
        } 

        fill(fillValue(field[i - 1][j - 1]));
        rect(j * squareSize + 200, i * squareSize, squareSize, squareSize);
      }
    }
  }

  int fillValue(int tetrominoType) {
    switch(tetrominoType) {
    case 0: // empty area
      return 210;
    case 1: // I-Tetromino
      return #00FFFF; // light blue
    case 2: // O-Tetromino
      return #FFFF00; // yellow
    case 3: // T-Tetromino
      return #FF69B4; // pink
    case 4: // J-Tetromino
      return #0000FF; // blue
    case 5: // L-Tetromino
      return #FF8C00; // orange
    case 6: // S-Tetromino
      return #00FF00; // green
    case 7: // Z-Tetromino
      return #FF0000; // red
    case 9: // highlight
      return 255;
    default:
      println("The number in the field is unexpected.");
      return 0;
    }
  }

  ArrayList<Integer> completedLines() {
    ArrayList<Integer> compLines = new ArrayList<Integer>();

    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 10; j++) {
        if (field[i][j] == 0) {
          break;
        }
        if (j == 9) {
          compLines.add(i);
        }
      }
    }

    return compLines;
  }

  void highlightLines(ArrayList<Integer> compLines) {
    for (int i = 0; i < compLines.size(); i++) {
      for (int j = 0; j < 10; j++) {
        field[compLines.get(i)][j] = 9;
      }
    }

    this.isHighlightingLines = true;
  }

  void eraseLines() {
    for (int i = 0; i < 20; i++) {
      if (field[i][0] == 9) { // highlighted line
        for (int j = i; j > 0; j--) {
          field[j] = field[j - 1].clone();
        }
        for (int j = 0; j < 10; j++) {
          field[0][j] = 0;
        }
      }
    }

    this.isHighlightingLines = false;
  }

  boolean isGameOver() {
    for (int i = 0; i < 10; i++) {
      if (field[0][i] != 0) {
        return true;
      }
    }

    return false;
  }
}

class Tetromino {
  int[][] position;
  int type;
  int axisIndex;

  Tetromino(int tetrominoType, boolean isNextTetromino) {
    this.position = new int[4][2]; // ((x, y), (x, y) ...)

    switch(tetrominoType) {
    case 1: // I-Tetromino
      int[][] iTetromino = {{3, 0}, {4, 0}, {5, 0}, {6, 0}};
      this.position = iTetromino;
      this.axisIndex = 1;
      break;

    case 2: // O-Tetromino
      int[][] oTetromino = {{4, 0}, {5, 0}, {4, 1}, {5, 1}};
      this.position = oTetromino;
      this.axisIndex = -1;
      break;

    case 3: // T-Tetromino
      int[][] tTetromino = {{4, 0}, {3, 1}, {4, 1}, {5, 1}};
      this.position = tTetromino;
      this.axisIndex = 2;
      break;

    case 4: // J-Tetromino
      int[][] jTetromino = {{3, 0}, {3, 1}, {4, 1}, {5, 1}};
      this.position = jTetromino;
      this.axisIndex = 2;
      break;

    case 5: // L-Tetromino
      int[][] lTetromino = {{5, 0}, {3, 1}, {4, 1}, {5, 1}};
      this.position = lTetromino;
      this.axisIndex = 2;
      break;

    case 6: // S-Tetromino
      int[][] sTetromino = {{4, 0}, {5, 0}, {3, 1}, {4, 1}};
      this.position = sTetromino;
      this.axisIndex = 3;
      break;

    case 7: // Z-Tetromino
      int[][] zTetromino = {{3, 0}, {4, 0}, {4, 1}, {5, 1}};
      this.position = zTetromino;
      this.axisIndex = 2;
      break;

    default:
      println("Error when producing a new tetromino");
    }

    this.type = tetrominoType;

    if (!isNextTetromino) {
      for (int i = 0; i < 4; i++) {
        field[this.position[i][1]][this.position[i][0]] = this.type;
      }
    }
  }

  boolean canMove(int direction) {
    for (int i = 0; i < 4; i++) {
      int[] checkPart = this.position[i];
      int nextSquareX = checkPart[0];
      int nextSquareY = checkPart[1];

      if (direction == DOWN) {
        if (checkPart[1] >= 19) {
          return false;
        }
        nextSquareY++;
      } else if (direction == RIGHT) {
        if (checkPart[0] > 8) {
          return false;
        }
        nextSquareX++;
      } else if (direction == LEFT) {
        if (checkPart[0] < 1) {
          return false;
        }
        nextSquareX--;
      }

      if (field[nextSquareY][nextSquareX] != 0) {
        if (field[nextSquareY][nextSquareX] == this.type) {
          // check if the next square isn't the tetromino's part
          for (int j = 0; j < 4; j++) {
            if (nextSquareX == this.position[j][0] && nextSquareY == this.position[j][1]) {
              break;
            }

            if (j == 3) {
              return false;
            }
          }
        } else {
          return false;
        }
      }
    }

    return true;
  }

  void move(int direction) {
    for (int i = 0; i < 4; i++) {
      field[this.position[i][1]][this.position[i][0]] = 0;

      if (direction == DOWN) {
        this.position[i][1]++;
      } else if (direction == RIGHT) {
        this.position[i][0]++;
      } else if (direction == LEFT) {
        this.position[i][0]--;
      }
    }

    for (int i = 0; i < 4; i++) {
      field[this.position[i][1]][this.position[i][0]] = this.type;
    }
  }

  int[][] rotatedPosition(int direction) {
    if (this.axisIndex == -1) { // O-Tetromino
      return new int[0][0];
    }

    int[][] rotatedPosition = new int[4][2];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 2; j++) {
        rotatedPosition[i][j] = this.position[i][j];
      }
    }

    int[] axisPart = this.position[this.axisIndex];
    for (int i = 0; i < 4; i++) {
      if (i == this.axisIndex) {
        continue;
      }

      int[] checkPart = this.position[i];

      if (checkPart[0] == axisPart[0]) {
        rotatedPosition[i][0] += (axisPart[1] - checkPart[1]) * (direction - 38); // direction: RIGHT = 39, LEFT = 37
        rotatedPosition[i][1] += axisPart[1] - checkPart[1];
      } else if (checkPart[1] == axisPart[1]) {
        rotatedPosition[i][0] += axisPart[0] - checkPart[0];
        rotatedPosition[i][1] -= (axisPart[0] - checkPart[0]) * (direction - 38);
      } else {
        if (axisPart[0] - checkPart[0] == checkPart[1] - axisPart[1]) { // on the upper right or lower left side of the axis
          if (direction == RIGHT) {
            rotatedPosition[i][1] += (axisPart[1] - checkPart[1]) * 2;
          } else if (direction == LEFT) {
            rotatedPosition[i][0] += (axisPart[0] - checkPart[0]) * 2;
          }
        } else { // on the upper left or lower right side of the axis
          if (direction == RIGHT) {
            rotatedPosition[i][0] += (axisPart[0] - checkPart[0]) * 2;
          } else if (direction == LEFT) {
            rotatedPosition[i][1] += (axisPart[1] - checkPart[1]) * 2;
          }
        }
      }
    }

    for (int i = 0; i < 4; i++) { // check if the tetromino can rotate
      if (rotatedPosition[i][0] < 0 || rotatedPosition[i][0] > 9) {
        return new int[0][0];
      } else if (rotatedPosition[i][1] < 0 || rotatedPosition[i][1] > 19) {
        return new int[0][0];
      } else if (field[rotatedPosition[i][1]][rotatedPosition[i][0]] != 0) {
        for (int j = 0; j < 4; j++) {
          if (rotatedPosition[i][0] == this.position[j][0] && rotatedPosition[i][1] == this.position[j][1]) {
            break;
          }

          if (j == 3) {
            return new int[0][0];
          }
        }
      }
    }

    return rotatedPosition;
  }

  void rotate(int[][] rotatedPosition) {
    for (int i = 0; i < 4; i++) {
      field[this.position[i][1]][this.position[i][0]] = 0;
    }
    for (int i = 0; i < 4; i++) {
      field[rotatedPosition[i][1]][rotatedPosition[i][0]] = this.type;
    }

    this.position = rotatedPosition;
  }
}

class GameOverScene extends Scene {
  int finalScore;
  int finalLines;

  GameOverScene(int finalScore, int finalLines) {
    super();
    this.finalScore = finalScore;
    this.finalLines = finalLines;
  }

  @Override
  void update() {
    fill(0);
    textSize(50);
    text("G A M E O V E R", 0, 150, 760, 100);
    textSize(40);
    text("Score: " + this.finalScore + "   Lines: " + this.finalLines, 0, 250, 760, 100);
    textSize(50);
    text("R: Restart   Q: Quit", 0, 400, 760, 100);
  }

  @Override
  void keyPressed() {
    if (key == 'r') {
      this.willDisappear();
    }
    if (key == 'q') {
      exit();
    }
  }

  @Override
  void willDisappear() {
    super.willDisappear();
    gameScene = new GameScene();
  }
}
