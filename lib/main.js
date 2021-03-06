// Generated by CoffeeScript 1.4.0
(function() {
  var Curve, Draw, Layer, Main,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Math.round = (function() {
    var oldRound;
    oldRound = Math.round;
    return function(number, precision) {
      var coefficient;
      precision = Math.abs(parseInt(precision)) || 0;
      coefficient = Math.pow(10, precision);
      return oldRound(number * coefficient) / coefficient;
    };
  })();

  $(function() {
    return new Main();
  });

  Main = (function() {

    function Main() {
      this.joinBezier = __bind(this.joinBezier, this);
      this.animate = __bind(this.animate, this);
      this.configure = __bind(this.configure, this);
      var _this = this;
      $('#animate').bind('click', function() {
        return _this.animate();
      });
      $('#example1').bind('click', function() {
        var c1, c2;
        c1 = new Curve("c1", [[161, 516], [399, 23], [51, 401], [254, 427]]);
        c2 = new Curve("c2", [[400, 100], [700, 50], [650, 300], [400, 100]]);
        return _this.configure(c1, c2);
      });
      $('#example2').bind('click', function() {
        var c1, c2;
        c1 = new Curve("c1", [[180, 319], [230, 40], [29, 266], [143, 449], [306, 33], [313, 155], [138, 18], [120, 316]]);
        c2 = new Curve("c2", [[401, 500], [824, 37], [718, 34], [453, 342], [513, 121], [772, 489], [817, 175], [401, 500]]);
        return _this.configure(c1, c2);
      });
      $('#example3').bind('click', function() {
        var c1, c2;
        c1 = new Curve("c1", [[15, 207], [230, 40], [45, 101], [164, 511], [165, 286], [27, 433], [312, 531], [10, 576], [456, 42], [301, 98], [238, 357], [23, 233]]);
        c2 = new Curve("c2", [[380, 388], [590, 28], [660, 490], [406, 160], [475, 531], [645, 392], [820, 389], [699, 167], [464, 400], [382, 259], [392, 403], [400, 500]]);
        return _this.configure(c1, c2);
      });
    }

    Main.prototype.configure = function(c1, c2) {
      var _this = this;
      $('#curves').children('.kineticjs-content').remove();
      this.draw = new Draw("curves");
      this.draw.layer.addCurve(c1);
      this.draw.layer.addCurve(c2);
      this.draw.layer.layer.beforeDraw(function() {
        _this.draw.layer.draw(_this.draw.curveLayer.layer.getCanvas());
        return _this.draw.layer.updateDottedLines();
      });
      this.draw.stage.on("mouseout", function() {
        return _this.draw.layer.layer.draw();
      });
      return this.draw.run();
    };

    Main.prototype.animate = function() {
      var anim, b1, b2, step, t,
        _this = this;
      b1 = this.draw.layer.curvePoints(this.draw.layer.curves[0]);
      b2 = this.draw.layer.curvePoints(this.draw.layer.curves[1]);
      t = 0.0;
      step = 0.002;
      anim = new Kinetic.Animation(function(frame) {
        t += step;
        t = Math.round(t, 3);
        $('#alpha span').html(t);
        _this.draw.layer.drawAnimate(_this.draw.curveLayer.layer.getCanvas(), _this.joinBezier(b1, b2, t));
        if (t >= 1) {
          return anim.stop();
        }
      });
      return anim.start();
    };

    Main.prototype.joinBezier = function(a, b, alpha) {
      var i, z, _i, _ref;
      if (a.length !== b.length) {
        return null;
      }
      z = [];
      for (i = _i = 0, _ref = a.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        z[i] = alpha * a[i] + (1 - alpha) * b[i];
      }
      return z;
    };

    return Main;

  })();

  Draw = (function() {

    function Draw(id, width, height) {
      if (width == null) {
        width = 878;
      }
      if (height == null) {
        height = 600;
      }
      this.run = __bind(this.run, this);
      this.clear = __bind(this.clear, this);
      this.stage = new Kinetic.Stage({
        container: id,
        width: width,
        height: height
      });
      this.layer = new Layer();
      this.curveLayer = new Layer();
    }

    Draw.prototype.clear = function() {
      this.curveLayer.layer.clear();
      return this.layer.layer.clear();
    };

    Draw.prototype.run = function() {
      this.stage.add(this.curveLayer.layer);
      return this.stage.add(this.layer.layer);
    };

    return Draw;

  })();

  Layer = (function() {

    function Layer() {
      this.drawAnimate = __bind(this.drawAnimate, this);
      this.draw = __bind(this.draw, this);
      this.clear = __bind(this.clear, this);
      this.updateDottedLines = __bind(this.updateDottedLines, this);
      this.curvePoints = __bind(this.curvePoints, this);
      this.addCurve = __bind(this.addCurve, this);      this.layer = new Kinetic.Layer();
      this.curves = [];
    }

    Layer.prototype.addCurve = function(curve) {
      this.curves.push(curve);
      this.layer.add(curve.line);
      return curve.buildAnchors(this.layer);
    };

    Layer.prototype.curvePoints = function(curve) {
      var _this = this;
      return _.flatten(_.map(curve.anchors, function(p) {
        return [p.attrs.x, p.attrs.y];
      }));
    };

    Layer.prototype.updateDottedLines = function() {
      var _this = this;
      return _.each(this.curves, function(c) {
        var cline, points;
        points = _this.curvePoints(c);
        cline = _this.layer.get("#" + c.id)[0];
        return cline.setPoints(points);
      });
    };

    Layer.prototype.clear = function() {
      return this.layer.removeChildren();
    };

    Layer.prototype.draw = function(canvas) {
      var context,
        _this = this;
      canvas.clear();
      context = canvas.getContext("2d");
      return _.each(this.curves, function(c) {
        var points;
        points = _this.curvePoints(c);
        return context.bezier(points);
      });
    };

    Layer.prototype.drawAnimate = function(canvas, points) {
      var context;
      canvas.clear();
      context = canvas.getContext("2d");
      return context.bezier(points);
    };

    return Layer;

  })();

  Curve = (function() {

    function Curve(id, points) {
      this.id = id;
      this.points = points;
      this.anchor = __bind(this.anchor, this);
      this.buildAnchors = __bind(this.buildAnchors, this);
      this.line = new Kinetic.Line({
        dashArray: [10, 10, 0, 10],
        strokeWidth: 1,
        stroke: "grey",
        lineCap: "round",
        id: this.id,
        opacity: 0.1
      });
      this.anchors = [];
    }

    Curve.prototype.buildAnchors = function(layer) {
      var _this = this;
      return _.each(this.points, function(p, i) {
        return _this.anchors.push(_this.anchor(layer, p[0], p[1]));
      });
    };

    Curve.prototype.anchor = function(layer, x, y) {
      var anchor,
        _this = this;
      anchor = new Kinetic.Circle({
        x: x,
        y: y,
        radius: 3,
        stroke: "#666",
        fill: "#ddd",
        strokeWidth: 4,
        draggable: true
      });
      anchor.on("mouseover", function() {
        document.body.style.cursor = "pointer";
        return layer.draw();
      });
      anchor.on("mouseout", function() {
        document.body.style.cursor = "default";
        return layer.draw();
      });
      layer.add(anchor);
      return anchor;
    };

    return Curve;

  })();

}).call(this);
