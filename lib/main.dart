import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

enum TileState { covered, blown, open, flagged, revealed }

void main() => runApp(MineSweeper());

class MineSweeper extends StatelessWidget {
  const MineSweeper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mine Sweeper",
      home: Board(),
    );
  }
}

class Board extends StatefulWidget {
  @override
  BoardState createState() => BoardState();
}

class BoardState extends State<Board> {
  final int rows = 9;
  final int cols = 9;
  final int numOfMines = 11;

  late List<List<TileState>> uiState;
  late List<List<bool>> tiles;

  bool alive = false;
  bool wonGame = false;
  int minesFound = 0;
  Timer? timer;
  Stopwatch stopwatch = Stopwatch();

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void resetBoard() {
    alive = true;
    wonGame = false;
    minesFound = 0;
    stopwatch.reset();

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });

    uiState = List<List<TileState>>.generate(rows, (row) {
      return List<TileState>.filled(cols, TileState.covered);
    });

    tiles = List<List<bool>>.generate(rows, (row) {
      return List<bool>.filled(cols, false);
    });

    Random random = Random();
    int remainingMines = numOfMines;
    while (remainingMines > 0) {
      int pos = random.nextInt(rows * cols);
      int row = pos ~/ rows;
      int col = pos % cols;
      if (!tiles[row][col]) {
        tiles[row][col] = true;
        remainingMines--;
      }
    }
  }

  @override
  void initState() {
    resetBoard();
    super.initState();
  }

  Widget buildBoard() {
    bool hasCoveredCell = false;
    List<Row> boardRow = <Row>[];
    for (int y = 0; y < rows; y++) {
      List<Widget> rowChildren = <Widget>[];
      for (int x = 0; x < cols; x++) {
        TileState state = uiState[y][x];
        int count = mineCount(x, y);

        if (!alive) {
          if (state != TileState.blown)
            state = tiles[y][x] ? TileState.revealed : state;
        }

        if (state == TileState.covered || state == TileState.flagged) {
          rowChildren.add(GestureDetector(
            onLongPress: () {
              flag(x, y);
            },
            onTap: () {
              if (state == TileState.covered) probe(x, y);
            },
            child: Listener(
              child: CoveredMineTile(
                flagged: state == TileState.flagged,
                posX: x,
                posY: y,
              ),
            ),
          ));
          if (state == TileState.covered) {
            hasCoveredCell = true;
          }
        } else {
          rowChildren.add(OpenMineTile(
            state: state,
            count: count,
          ));
        }
      }
      boardRow.add(Row(children: rowChildren));
    }

    if (!hasCoveredCell) {
      timer?.cancel();
      stopwatch.stop();
      if (minesFound == numOfMines) {
        wonGame = true;
      }
    }

    return Column(children: boardRow);
  }

  void probe(int x, int y) {
    if (!alive) return;

    if (tiles[y][x]) {
      setState(() {
        uiState[y][x] = TileState.blown;
        alive = false;
        timer?.cancel();
        stopwatch.stop();
      });
      return;
    }

    setState(() {
      discover(x, y);
    });
  }

  void discover(int x, int y) {
    if (!inBoard(x, y)) return;

    if (uiState[y][x] != TileState.covered) return;

    uiState[y][x] = TileState.open;

    if (mineCount(x, y) == 0) {
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          if (i != 0 || j != 0) {
            discover(x + i, y + j);
          }
        }
      }
    }
  }

  void flag(int x, int y) {
    if (!alive) return;

    setState(() {
      if (uiState[y][x] == TileState.flagged) {
        uiState[y][x] = TileState.covered;
        minesFound--;
      } else {
        uiState[y][x] = TileState.flagged;
        minesFound++;
      }
    });
  }

  int mineCount(int x, int y) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (inBoard(x + i, y + j) && bombs(x + i, y + j)) count++;
      }
    }
    return count;
  }

  bool inBoard(int x, int y) {
    return x >= 0 && x < cols && y >= 0 && y < rows;
  }

  bool bombs(int x, int y) {
    if (inBoard(x, y)) {
      return tiles[y][x];
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mine Sweeper"),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              child: Text(
                "Mines Found: $minesFound",
                style: TextStyle(fontSize: 24),
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Text(
                "Time Elapsed: ${stopwatch.elapsed.inSeconds}",
                style: TextStyle(fontSize: 24),
              ),
            ),
            buildBoard(),
            if (!alive || wonGame)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    resetBoard();
                  });
                },
                child: Text("Restart"),
              ),
          ],
        ),
      ),
    );
  }
}

class CoveredMineTile extends StatelessWidget {
  final bool flagged;
  final int posX;
  final int posY;

  const CoveredMineTile({Key? key, required this.flagged, required this.posX, required this.posY}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey,
        border: Border.all(
          color: Colors.black,
        ),
      ),
      child: flagged ? Icon(Icons.flag, color: Colors.red) : null,
    );
  }
}

class OpenMineTile extends StatelessWidget {
  final TileState state;
  final int count;

  const OpenMineTile({Key? key, required this.state, required this.count}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color? color;
    String text = "";

    switch (state) {
      case TileState.open:
        color = Colors.white;
        if (count > 0) {
          text = count.toString();
        }
        break;
      case TileState.blown:
        color = Colors.red;
        break;
      default:
        break;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black,
        ),
      ),
      child: Center(
        child: Text(text),
      ),
    );
  }
}
