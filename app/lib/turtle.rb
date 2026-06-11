# Minimal turtle-graphics engine (turtletoy-style) that records pen paths
# as arrays of [x, y] points, ready to emit as SVG polylines.
#
# Conventions: heading in degrees, 0 = +x axis, angles increase clockwise
# in SVG screen space (y grows downward). `left`/`right` are screen-relative.
class Turtle
  def initialize(x: 0.0, y: 0.0, heading: 0.0)
    @x = x.to_f
    @y = y.to_f
    @h = heading.to_f
    @pen = true
    @paths = []
    @cur = [[@x, @y]]
  end

  attr_reader :h

  def position
    [@x, @y]
  end

  def setheading(deg)
    @h = deg.to_f
    self
  end

  def left(deg)
    @h -= deg
    self
  end

  def right(deg)
    @h += deg
    self
  end
  alias turn right

  def forward(dist)
    r = @h * Math::PI / 180.0
    @x += Math.cos(r) * dist
    @y += Math.sin(r) * dist
    @cur << [@x, @y] if @pen
    self
  end
  alias fd forward

  # Move while drawing (if pen down) to an absolute point.
  def goto(x, y)
    @x = x.to_f
    @y = y.to_f
    @cur << [@x, @y] if @pen
    self
  end

  # Move WITHOUT drawing; starts a fresh path at the destination.
  def jump(x, y)
    flush
    @x = x.to_f
    @y = y.to_f
    @cur = [[@x, @y]]
    self
  end

  def penup
    flush
    @pen = false
    @cur = []
    self
  end

  def pendown
    @pen = true
    @cur = [[@x, @y]]
    self
  end

  # All recorded polylines (each = array of [x, y]). Drops single-point paths.
  def paths
    out = @paths.dup
    out << @cur if @cur.size > 1
    out
  end

  private

  def flush
    @paths << @cur if @cur && @cur.size > 1
  end
end
