import logworld.LogCamera;
import logworld.LogCamera.Projection;

class Capture {
    static function main() {
        var curved = Sys.args()[0] == "curved";
        LogCamera.curved = curved;
        LogCamera.zoom = 0.72;
        LogCamera.refresh();
        var points = [];
        // World-space control points are fixed in both captures.
        for (row in 0...13) {
            for (col in 0...17) {
                var x = (col - 8) * 147 + Math.sin(row * 4 + col) * 31;
                var forward = row * 110 - 270 + Math.cos(col + row) * 27;
                var p = LogCamera.project(x, -forward, new Projection());
                if (p.visible && !p.beyondHorizon) {
                    points.push({row: row, col: col, x: p.sx, y: p.sy, scale: p.scale, fog: LogCamera.fog(forward)});
                }
            }
        }
        Sys.println(haxe.Json.stringify(points));
    }
}
