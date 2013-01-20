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
    $('#example1').bind 'click', =>
      initialPoints = [[180, 319], [230, 40], [29, 266], [143, 449], [306, 33], [313, 155], [138, 18], [120, 316]]
      c1 = new Curve("c1", initialPoints)
      c2 = new Curve("c2", initialPoints)

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

class Draw
  constructor: (id, width = 800, height = 600) ->
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