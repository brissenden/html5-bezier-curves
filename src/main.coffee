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
    @downReduceLimit = 3

    $('#animate').bind 'click', => @runAnimate()

    $('#example1').bind 'click', =>
      initialPoints = [[180, 319], [230, 40], [29, 266], [143, 449], [306, 33], [313, 155], [138, 18]]
      c1 = new Curve("c1", initialPoints)

      @configure(c1)

  runAnimate: =>
    step = 0
    frame = =>
      if step <= @downReduceLimit
        step++
        @draw.layer.drawAnimate(@draw.curveLayer.layer.getCanvas(), step, '#ff0000')
      else
        clearInterval nre
        @errorDiagram()

    nre = setInterval frame, 1000

  errorDiagram: =>
    console.log @draw.layer.errorData(1)

    chart = new Highcharts.Chart(
      chart:
        renderTo: "error-diagram"
        type: "area"

      title:
        text: "Wykres błędu"

      yAxis:
        title:
          text: "Wartość błędu"

        labels:
          formatter: ->
            @value

      plotOptions:
        area:
          pointStart: 0.0
          marker:
            enabled: false
            symbol: "circle"
            radius: 2
            states:
              hover:
                enabled: true

      series: @dataSeries()
    )

  dataSeries: =>
    series = []
    for i in [1..@downReduceLimit]
      series.push { name: "Stopien o #{i} niższy", data:  @draw.layer.errorData(i) }

    series

  configure: (c1) =>
    $('#curves').children('.kineticjs-content').remove()

    @draw = new Draw("curves")

    @draw.layer.addCurve c1

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
    @colors = ['#24609d', '#ff0000']

    @N = 100

    @curvesControlPoints = []

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

  parseToFlatten: (points) =>
    _.flatten(_.map points, (p) => [p[0], p[1]])

  parseToArray: (points) =>
    outPoints = []
    i = 0
    while i < points.length
      outPoints.push [points[i], points[i + 1]]
      i = i + 2
    outPoints

  draw: (canvas) =>
    canvas.clear()
    context = canvas.getContext("2d")

    _.each @curves, (c, i) =>
      points = @curvePoints(c)
      context.bezier(@N, points, @colors[i])

  drawAnimate: (canvas, reduce, color) =>
    @draw(canvas)

    context = canvas.getContext("2d")

    points = @curvePoints(@curves[0])
    drawedPoints = @parseToFlatten(@reduce(@parseToArray(points), reduce))
    @curvesControlPoints.push drawedPoints

    context.bezier(@N, drawedPoints, color)

  distance: (a, b) ->
    Math.sqrt Math.pow(a[0] - b[0], 2) + Math.pow(a[1] - b[1], 2)

  fact: (k) =>
    if k is 0 or k is 1
      1
    else
      k * @fact(k - 1)

  B: (i, n, t) =>
    @fact(n) / (@fact(i) * @fact(n - i)) * Math.pow(t, i) * Math.pow(1 - t, n - i)

  P: (t, points) =>
    r = [0, 0]
    n = points.length - 1
    i = 0

    while i <= n
      r[0] += points[i][0] * @B(i, n, t)
      r[1] += points[i][1] * @B(i, n, t)
      i++
    r

  error: (p1, p2, t) =>
    @distance(@P(t, p1), @P(t, p2))

  testPoints: =>
    DN = []
    for i in [0..@N]
      DN.push i/@N
    DN.push 1
    DN

  errorData: (reduceDegree) =>
    errors = []
    original = @curvesControlPoints[0]

    points = @curvesControlPoints[reduceDegree]
    _.each @testPoints(), (t) =>
      errors.push @error(@parseToArray(original), @parseToArray(points), t)

    errors

  reduce: (initialPoints, reduce) =>
    points = initialPoints
    while reduce > 0
      points = @reduceDegree(points)
      reduce--
    points

  reduceDegree: (initialPoints) =>
    degree = initialPoints.length-1

    xs = initialPoints.map((p) => p[0])
    ys = initialPoints.map((p) => p[1])

    rXs = @reducedControlPoints(xs)
    rYs = @reducedControlPoints(ys)

    P = []
    for i in [0..degree-1]
      P[i] = []
      P[i][0] = rXs[i]
      P[i][1] = rYs[i]

    # console.debug rXs, rYs
    # console.debug P

    P

  reducedControlPoints: (initialPoints) =>
    Q = initialPoints

    p = initialPoints.length - 1
    r = (p - 1) / 2

    unless p > 2
      throw "To small curve degree"
      return 0

    P = []
    for i in [0..p]
      P[i] = 0

    P[0]   = Q[0]
    P[p-1] = Q[p]

    for i in [1..p-2]
      P[i] = ( p * Q[i] - i * P[i-1] ) / (p - i)

    for i in [p-2..r+1]
      P[i] = ( p * Q[i+1] - (p - i - 1.0 ) * P[i+1] ) / (i + 1.0)

    if p % 2 != 0

      [PL, PR] = [0, 0]

      PL = ( p * Q[r] - r * P[r-1] ) / ( p - r )
      PR = ( p * Q[r+1] - (p - r - 1.0) * P[r+1]) / (r + 1.0)

      P[r] = 0.5 * ( PL + PR )

    P

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