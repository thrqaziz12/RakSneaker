// =============================================================================
// sneaker_maze_game_screen.dart
// Mini Game: Sneaker Tilt Maze
//
// Fitur:
//   - Labirin dikontrol dengan memiringkan HP (Accelerometer)
//   - Bola berbentuk sneaker mini navigasi lewat labirin
//   - Gyroscope: putar HP 90° → rotasi orientasi maze
//   - Rintangan: genangan air (biru) dan kotoran (coklat)
//   - Level semakin sulit (maze lebih besar, lebih banyak rintangan)
//   - HUD: level, nyawa, kebersihan sneaker, timer
//   - Partikel animasi saat menabrak rintangan
// =============================================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ---------------------------------------------------------------------------
// Warna (selaras dengan tema RakSneaker)
// ---------------------------------------------------------------------------
const kMazeAccent = Color(0xFFFF6B35);
const kMazeAccentDark = Color(0xFFD94F1A);
const kMazeBg = Color(0xFFFFF8F5);
const kMazeSurface = Color(0xFFFFFFFF);
const kMazeSurfaceAccent = Color(0xFFFFF0E8);
const kMazeText = Color(0xFF1A1A1A);
const kMazeTextMuted = Color(0xFF6B6B6B);
const kMazeBorder = Color(0xFFE8E0DB);

const double kCellSize = 44.0;
const double kWallThick = 3.5;
const double kBallRadius = 14.0;

// ---------------------------------------------------------------------------
// MazeCell — setiap sel labirin, dengan info dinding dan jenis rintangan
// ---------------------------------------------------------------------------
class MazeCell {
  bool top, right, bottom, left;
  bool isWater, isDirt;

  MazeCell({
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.left = true,
    this.isWater = false,
    this.isDirt = false,
  });
}

// ---------------------------------------------------------------------------
// MazeGenerator — Recursive Backtracker DFS
// ---------------------------------------------------------------------------
class MazeGenerator {
  final int cols;
  final int rows;
  final Random _rng;
  late List<List<MazeCell>> cells;

  MazeGenerator(this.cols, this.rows, {int? seed})
      : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    cells = List.generate(
      rows,
      (r) => List.generate(cols, (c) => MazeCell()),
    );
  }

  void generate() {
    final visited = List.generate(rows, (_) => List.filled(cols, false));
    _dfs(0, 0, visited);
  }

  void _dfs(int r, int c, List<List<bool>> visited) {
    visited[r][c] = true;
    // dr, dc per direction: 0=up, 1=right, 2=down, 3=left
    final drs = [-1, 0, 1, 0];
    final dcs = [0, 1, 0, -1];
    final dirs = [0, 1, 2, 3]..shuffle(_rng);
    for (final d in dirs) {
      final nr = r + drs[d];
      final nc = c + dcs[d];
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
      if (visited[nr][nc]) continue;
      // Remove wall between (r,c) and (nr,nc)
      switch (d) {
        case 0:
          cells[r][c].top = false;
          cells[nr][nc].bottom = false;
          break;
        case 1:
          cells[r][c].right = false;
          cells[nr][nc].left = false;
          break;
        case 2:
          cells[r][c].bottom = false;
          cells[nr][nc].top = false;
          break;
        case 3:
          cells[r][c].left = false;
          cells[nr][nc].right = false;
          break;
      }
      _dfs(nr, nc, visited);
    }
  }

  void addObstacles(int level) {
    final int waterCount = 2 + level;
    final int dirtCount = 1 + level;
    final total = cols * rows;
    final indices = List.generate(total, (i) => i)..shuffle(_rng);
    int added = 0;
    for (final idx in indices) {
      if (added >= waterCount + dirtCount) break;
      final r = idx ~/ cols;
      final c = idx % cols;
      if (r == 0 && c == 0) continue;
      if (r == rows - 1 && c == cols - 1) continue;
      if (added < waterCount) {
        cells[r][c].isWater = true;
      } else {
        cells[r][c].isDirt = true;
      }
      added++;
    }
  }
}

// ---------------------------------------------------------------------------
// Particle — efek visual saat menabrak rintangan
// ---------------------------------------------------------------------------
class _Particle {
  Offset pos;
  Offset vel;
  Color color;
  double life; // 1.0 → 0.0

  _Particle({required this.pos, required this.vel, required this.color})
      : life = 1.0;
}

// ===========================================================================
// SneakerMazeGameScreen
// ===========================================================================
class SneakerMazeGameScreen extends StatefulWidget {
  const SneakerMazeGameScreen({super.key});

  @override
  State<SneakerMazeGameScreen> createState() => _SneakerMazeGameScreenState();
}

class _SneakerMazeGameScreenState extends State<SneakerMazeGameScreen>
    with TickerProviderStateMixin {
  // -- Game state
  int _level = 1;
  int _lives = 3;
  double _cleanliness = 1.0;
  bool _gameOver = false;
  bool _levelComplete = false;
  bool _paused = false;

  // -- Maze
  late MazeGenerator _mazeGen;
  late List<List<MazeCell>> _cells;
  int _mazeRows = 6;
  int _mazeCols = 5;

  // -- Ball
  double _ballX = 0.5;
  double _ballY = 0.5;
  Offset _ballVel = Offset.zero;

  // -- Sensors
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _accelX = 0, _accelY = 0;
  double _gyroZ = 0;
  int _mazeRotation = 0; // 0, 90, 180, 270
  double _gyroZAccum = 0;

  // -- Game loop
  late AnimationController _gameLoop;
  DateTime _lastTick = DateTime.now();

  // -- Particles
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  // -- Obstacle tracking
  final Set<String> _visitedObstacles = {};

  // -- Timer
  int _elapsedSeconds = 0;
  Timer? _secondTimer;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _startSensors();
    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )
      ..addListener(_tick)
      ..forward();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && !_gameOver && !_levelComplete && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _initLevel() {
    _mazeRows = 5 + _level;
    _mazeCols = 4 + _level;
    _mazeGen = MazeGenerator(_mazeCols, _mazeRows, seed: _level * 137);
    _mazeGen.generate();
    _mazeGen.addObstacles(_level);
    _cells = _mazeGen.cells;
    _ballX = 0.5;
    _ballY = 0.5;
    _ballVel = Offset.zero;
    _visitedObstacles.clear();
    _particles.clear();
    _mazeRotation = 0;
    _gyroZAccum = 0;
    _levelComplete = false;
    _elapsedSeconds = 0;
  }

  void _startSensors() {
    _accelSub = accelerometerEventStream().listen((e) {
      _accelX = e.x;
      _accelY = e.y;
    });
    _gyroSub = gyroscopeEventStream().listen((e) {
      _gyroZ = e.z;
    });
  }

  void _tick() {
    if (_paused || _gameOver || _levelComplete) return;
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;
    if (dt <= 0 || dt > 0.1) return;

    // Gyroscope: accumulate Z rotation, snap at 90°
    _gyroZAccum += _gyroZ * dt;
    if (_gyroZAccum.abs() > pi / 2) {
      final dir = _gyroZAccum > 0 ? 1 : -1;
      _mazeRotation = ((_mazeRotation + dir * 90) % 360 + 360) % 360;
      _gyroZAccum = 0;
    }

    // Rotate gravity vector by maze rotation
    final rad = _mazeRotation * pi / 180;
    final cosR = cos(rad);
    final sinR = sin(rad);
    final gx = _accelX * cosR - _accelY * sinR;
    final gy = _accelX * sinR + _accelY * cosR;

    const double tilt = 3.5;
    const double friction = 0.88;
    const double maxVel = 8.0;

    double vx = (_ballVel.dx + gx * tilt * dt) * friction;
    double vy = (_ballVel.dy + (-gy) * tilt * dt) * friction;
    vx = vx.clamp(-maxVel, maxVel);
    vy = vy.clamp(-maxVel, maxVel);

    double nx = _ballX + vx * dt;
    double ny = _ballY + vy * dt;
    final r = kBallRadius / kCellSize;

    final col = _ballX.floor().clamp(0, _mazeCols - 1);
    final row = _ballY.floor().clamp(0, _mazeRows - 1);
    final cell = _cells[row][col];

    // Wall collisions
    final lw = col.toDouble();
    final rw = col + 1.0;
    final tw = row.toDouble();
    final bw = row + 1.0;

    if (cell.left && nx - r < lw) { nx = lw + r; vx = vx.abs() * 0.3; }
    if (cell.right && nx + r > rw) { nx = rw - r; vx = -vx.abs() * 0.3; }
    if (cell.top && ny - r < tw) { ny = tw + r; vy = vy.abs() * 0.3; }
    if (cell.bottom && ny + r > bw) { ny = bw - r; vy = -vy.abs() * 0.3; }

    // Boundary
    if (nx - r < 0) { nx = r; vx = 0; }
    if (nx + r > _mazeCols) { nx = _mazeCols - r; vx = 0; }
    if (ny - r < 0) { ny = r; vy = 0; }
    if (ny + r > _mazeRows) { ny = _mazeRows - r; vy = 0; }

    // Update particles
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _particles) {
      p.pos = Offset(p.pos.dx + p.vel.dx * dt, p.pos.dy + p.vel.dy * dt);
      p.life -= dt * 2.5;
    }

    // Obstacle check
    final newCol = nx.floor().clamp(0, _mazeCols - 1);
    final newRow = ny.floor().clamp(0, _mazeRows - 1);
    final newCell = _cells[newRow][newCol];
    final cellKey = '$newRow-$newCol';

    if (!_visitedObstacles.contains(cellKey)) {
      if (newCell.isWater) {
        _visitedObstacles.add(cellKey);
        _spawnParticles(nx * kCellSize, ny * kCellSize, const Color(0xFF2196F3));
        setState(() {
          _cleanliness = (_cleanliness - 0.15).clamp(0.0, 1.0);
          if (_cleanliness <= 0) _loseLife();
        });
      } else if (newCell.isDirt) {
        _visitedObstacles.add(cellKey);
        _spawnParticles(nx * kCellSize, ny * kCellSize, const Color(0xFF795548));
        setState(() {
          _cleanliness = (_cleanliness - 0.22).clamp(0.0, 1.0);
          if (_cleanliness <= 0) _loseLife();
        });
      }
    }

    // Goal check (bottom-right cell)
    if (newRow == _mazeRows - 1 && newCol == _mazeCols - 1) {
      setState(() => _levelComplete = true);
    }

    setState(() {
      _ballX = nx;
      _ballY = ny;
      _ballVel = Offset(vx, vy);
    });
  }

  void _spawnParticles(double px, double py, Color color) {
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 30.0 + _rng.nextDouble() * 70.0;
      _particles.add(_Particle(
        pos: Offset(px, py),
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
      ));
    }
  }

  void _loseLife() {
    _lives--;
    _cleanliness = 0.5;
    if (_lives <= 0) {
      _gameOver = true;
    }
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _cleanliness = (_cleanliness + 0.3).clamp(0.0, 1.0);
      _initLevel();
    });
  }

  void _restartGame() {
    setState(() {
      _level = 1;
      _lives = 3;
      _cleanliness = 1.0;
      _gameOver = false;
      _initLevel();
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _gameLoop.dispose();
    _secondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMazeBg,
      appBar: AppBar(
        backgroundColor: kMazeSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kMazeText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Text('👟', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Sneaker Tilt Maze',
              style: TextStyle(
                color: kMazeText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: kMazeAccent,
              size: 28,
            ),
            onPressed: () => setState(() => _paused = !_paused),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildHUD(),
          Expanded(child: _buildGameArea()),
          _buildHint(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: kMazeSurface,
        border: Border(bottom: BorderSide(color: kMazeBorder, width: 1)),
      ),
      child: Row(
        children: [
          _hudChip('LEVEL', '$_level', kMazeAccent),
          const SizedBox(width: 12),
          _hudChip('NYAWA', '❤️' * _lives.clamp(0, 3), Colors.red),
          const SizedBox(width: 12),
          _hudChip('WAKTU', '${_elapsedSeconds}s', kMazeTextMuted),
          const Spacer(),
          _buildCleanlinessBar(),
        ],
      ),
    );
  }

  Widget _hudChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: kMazeTextMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color)),
      ],
    );
  }

  Widget _buildCleanlinessBar() {
    final color = _cleanliness > 0.6
        ? const Color(0xFF4CAF50)
        : _cleanliness > 0.3
            ? const Color(0xFFFF9800)
            : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('KEBERSIHAN',
            style: TextStyle(
                fontSize: 9,
                color: kMazeTextMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          width: 76,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E0DB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * _cleanliness,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(_cleanliness * 100).toInt()}%',
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildGameArea() {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Transform.rotate(
                  angle: -_mazeRotation * pi / 180,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kMazeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kMazeAccent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: kMazeAccent.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: Size(
                        _mazeCols * kCellSize,
                        _mazeRows * kCellSize,
                      ),
                      painter: _MazePainter(
                        cells: _cells,
                        rows: _mazeRows,
                        cols: _mazeCols,
                        cellSize: kCellSize,
                        wallThick: kWallThick,
                        ballX: _ballX,
                        ballY: _ballY,
                        ballRadius: kBallRadius,
                        particles: _particles,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_levelComplete) _buildOverlay(win: true),
        if (_gameOver) _buildOverlay(win: false),
        if (_paused && !_gameOver && !_levelComplete) _buildPausedOverlay(),
      ],
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_filled, size: 72, color: Colors.white70),
            SizedBox(height: 12),
            Text(
              'GAME PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay({required bool win}) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: kMazeSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 28,
                  offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                win ? '🎉 Level $_level Selesai!' : '💀 Game Over',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kMazeText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                win
                    ? 'Sneakermu berhasil melewati labirin!\nKebersihan: ${(_cleanliness * 100).toInt()}% 👟✨'
                    : 'Sneakermu terlalu kotor!\nJaga kebersihan sneakermu ya! 🧹',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: kMazeTextMuted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 8),
              if (win)
                _statRow('Level berikutnya', 'Level ${_level + 1}', kMazeAccent),
              if (!win) _statRow('Level tercapai', 'Level $_level', kMazeTextMuted),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: win ? _nextLevel : _restartGame,
                  icon: Icon(win ? Icons.arrow_forward_rounded : Icons.refresh_rounded),
                  label: Text(win ? 'Lanjut ke Level ${_level + 1}' : 'Main Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMazeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: kMazeTextMuted, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: kMazeSurface,
        border: Border(top: BorderSide(color: kMazeBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _hintItem('📱 Miringkan HP', 'gerakkan sneaker'),
          const SizedBox(width: 20),
          _hintItem('🔄 Putar HP 90°', 'rotasi labirin'),
          const SizedBox(width: 20),
          _hintItem('💧 Hindari', 'air & kotoran'),
        ],
      ),
    );
  }

  Widget _hintItem(String icon, String desc) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMazeText)),
        Text(desc, style: const TextStyle(fontSize: 10, color: kMazeTextMuted)),
      ],
    );
  }
}

// ===========================================================================
// MazePainter
// ===========================================================================
class _MazePainter extends CustomPainter {
  final List<List<MazeCell>> cells;
  final int rows, cols;
  final double cellSize, wallThick, ballRadius;
  final double ballX, ballY;
  final List<_Particle> particles;

  _MazePainter({
    required this.cells,
    required this.rows,
    required this.cols,
    required this.cellSize,
    required this.wallThick,
    required this.ballRadius,
    required this.ballX,
    required this.ballY,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawObstacles(canvas);
    _drawWalls(canvas);
    _drawStartGoal(canvas);
    _drawBall(canvas);
    _drawParticles(canvas);
  }

  void _drawObstacles(Canvas canvas) {
    final rngCache = <String, Random>{};
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        final x = c * cellSize;
        final y = r * cellSize;
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

        if (cell.isWater) {
          // Water fill
          canvas.drawRect(rect, Paint()..color = const Color(0x442196F3));
          // Ripples
          final ripple = Paint()
            ..color = const Color(0xFF2196F3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          final cx = x + cellSize / 2;
          final cy = y + cellSize / 2;
          for (int i = 1; i <= 3; i++) {
            canvas.drawCircle(
                Offset(cx, cy), i * cellSize / 9, ripple);
          }
        } else if (cell.isDirt) {
          canvas.drawRect(rect, Paint()..color = const Color(0x44795548));
          final key = '$r-$c';
          rngCache[key] ??= Random(r * 31 + c * 17);
          final rng = rngCache[key]!;
          final speckle = Paint()..color = const Color(0xFF5D4037);
          for (int i = 0; i < 6; i++) {
            canvas.drawCircle(
                Offset(x + rng.nextDouble() * cellSize,
                    y + rng.nextDouble() * cellSize),
                1.2 + rng.nextDouble() * 2.0,
                speckle);
          }
        }
      }
    }
  }

  void _drawWalls(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xCC1A1A1A)
      ..strokeWidth = wallThick
      ..strokeCap = StrokeCap.square;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = cells[r][c];
        final x = c * cellSize;
        final y = r * cellSize;
        if (cell.top) {
          canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), paint);
        }
        if (cell.left) {
          canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), paint);
        }
        if (cell.bottom) {
          canvas.drawLine(
              Offset(x, y + cellSize), Offset(x + cellSize, y + cellSize), paint);
        }
        if (cell.right) {
          canvas.drawLine(
              Offset(x + cellSize, y), Offset(x + cellSize, y + cellSize), paint);
        }
      }
    }
  }

  void _drawStartGoal(Canvas canvas) {
    // Start indicator (top-left)
    final startPaint = Paint()..color = const Color(0x30FF6B35);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, cellSize, cellSize), startPaint);

    // Goal (bottom-right)
    final goalX = (cols - 1) * cellSize;
    final goalY = (rows - 1) * cellSize;
    final goalRect = Rect.fromLTWH(goalX, goalY, cellSize, cellSize);
    final goalPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x50FF6B35),
          const Color(0x80D94F1A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(goalRect);
    canvas.drawRect(goalRect, goalPaint);

    // Flag emoji at goal
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = const TextSpan(
          text: '🏁', style: TextStyle(fontSize: 24))
      ..layout();
    tp.paint(
        canvas,
        Offset(goalX + (cellSize - tp.width) / 2,
            goalY + (cellSize - tp.height) / 2));
  }

  void _drawBall(Canvas canvas) {
    final cx = ballX * cellSize;
    final cy = ballY * cellSize;

    // Drop shadow
    canvas.drawCircle(
        Offset(cx, cy + 3),
        ballRadius,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // Gradient ball
    canvas.drawCircle(
        Offset(cx, cy),
        ballRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [
              Colors.white,
              const Color(0xFFFF6B35),
              const Color(0xFFD94F1A),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(
              center: Offset(cx, cy), radius: ballRadius)));

    // Sneaker emoji
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = const TextSpan(text: '👟', style: TextStyle(fontSize: 15))
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(
          p.pos,
          3.5 * alpha,
          Paint()..color = p.color.withOpacity(alpha));
    }
  }

  @override
  bool shouldRepaint(_MazePainter old) => true;
}
