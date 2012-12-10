Math.round = (->
  oldRound = Math.round
  (number, precision) ->
    precision = Math.abs(parseInt(precision)) or 0
    coefficient = Math.pow(10, precision)
    oldRound(number * coefficient) / coefficient
)()

$ ->
  new Main()

class Main
  constructor: ->
    $('#animate').bind 'click', => @animate()

    $('#example1').bind 'click', =>
      c1 = new Curve("c1", [[161, 516], [399, 23], [51, 401], [254, 427]])
      c2 = new Curve("c2", [[400, 100], [700, 50], [650, 300], [400, 100]])
      @configure(c1, c2)

    $('#example2').bind 'click', =>
      c1 = new Curve("c1", [[180, 319], [230, 40], [29, 266], [143, 449], [306, 33], [313, 155], [138, 18], [120, 316]])
      c2 = new Curve("c2", [[401, 500], [824, 37], [718, 34], [453, 342], [513, 121], [772, 489], [817, 175], [401, 500]])
      @configure(c1, c2)

    $('#example3').bind 'click', =>
      c1 = new Curve("c1", [[15, 207], [230, 40], [45, 101], [164, 511], [165, 286], [27, 433], [312, 531], [10, 576], [456, 42], [301, 98], [238, 357], [23, 233]])
      c2 = new Curve("c2", [[380, 388], [590, 28], [660, 490], [406, 160], [475, 531], [645, 392], [820, 389], [699, 167], [464, 400], [382, 259], [392, 403], [400, 500]])
      @configure(c1, c2)

  configure: (c1, c2) =>
    $('#curves').children('.kineticjs-content').remove()

    @draw = new Draw("curves")

    @draw.layer.addCurve c1
    @draw.layer.addCurve c2

    @draw.layer.layer.beforeDraw =>
      @draw.layer.draw(@draw.curveLayer.layer.getCanvas())
      @draw.layer.updateDottedLines()

    @draw.stage.on "mouseout", =>
      @draw.layer.layer.draw()

    @draw.run()

  animate: =>
    b1 = @draw.layer.curvePoints(@draw.layer.curves[0])
    b2 = @draw.layer.curvePoints(@draw.layer.curves[1])

    t     = 0.0
    step  = 0.002
    anim = new Kinetic.Animation((frame) =>
      t += step ; t = Math.round(t, 3); $('#alpha span').html(t)
      @draw.layer.drawAnimate(@draw.curveLayer.layer.getCanvas(), @joinBezier(b1, b2, t))
      if t >= 1
        anim.stop()
    )

    anim.start()

  joinBezier: (a, b, alpha) =>
    return null if a.length != b.length
    z = []
    for i in [0..a.length-1]
      z[i] = alpha*a[i]+(1-alpha)*b[i]
    z

class Draw
  constructor: (id, width = 878, height = 600) ->
    @stage = new Kinetic.Stage(container: id, width: width, height: height)

    @layer      = new Layer()
    @curveLayer = new Layer()

  clear: =>
    @curveLayer.layer.clear()
    @layer.layer.clear()

  run: =>
    @stage.add @curveLayer.layer
    @stage.add @layer.layer

class Layer
  constructor: ->
    @layer  = new Kinetic.Layer()
    @curves = []

  addCurve: (curve) =>
    @curves.push curve
    @layer.add curve.line
    curve.buildAnchors(@layer)

  curvePoints: (curve) =>
    _.flatten(_.map curve.anchors, (p) => [p.attrs.x, p.attrs.y])

  updateDottedLines: =>
    _.each @curves, (c) =>
      points = @curvePoints(c)
      cline = @layer.get("##{c.id}")[0]
      cline.setPoints points

  clear: =>
    @layer.removeChildren()

  draw: (canvas) =>
    canvas.clear()
    context = canvas.getContext("2d")

    _.each @curves, (c) =>
      points = @curvePoints(c)
      context.bezier(points)

  drawAnimate: (canvas, points) =>
    canvas.clear()
    context = canvas.getContext("2d")
    context.bezier(points)

class Curve
  constructor: (@id, @points) ->
    @line = new Kinetic.Line(
      dashArray: [10, 10, 0, 10]
      strokeWidth: 1
      stroke: "grey"
      lineCap: "round"
      id: @id
      opacity: 0.1
    )

    @anchors = []

  buildAnchors: (layer) =>
    _.each @points, (p, i) =>
      @anchors.push @anchor(layer, p[0], p[1])

  anchor: (layer, x, y) =>
    anchor = new Kinetic.Circle(
      x: x
      y: y
      radius: 3
      stroke: "#666"
      fill: "#ddd"
      strokeWidth: 4
      draggable: true
    )

    anchor.on "mouseover", =>
      document.body.style.cursor = "pointer"
      layer.draw()

    anchor.on "mouseout", =>
      document.body.style.cursor = "default"
      layer.draw()

    layer.add anchor
    anchor