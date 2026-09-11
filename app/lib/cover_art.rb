# Generative, deterministic cover artwork in the turtletoy plotter style.
# Same issue id => same art every render. Output is pure SVG (crisp in print).
#
#   CoverArt.new(issue.id).to_svg
class CoverArt
  PALETTES = [
    # { bg: "#0a0a0a", stroke: "#84cc16" },
    # { bg: "#0f1923", stroke: "#38bdf8" },
    # { bg: "#1a0a2e", stroke: "#c084fc" },
    # { bg: "#1a0a0a", stroke: "#fb7185" },
    # { bg: "#0a1a0f", stroke: "#34d399" },
    # { bg: "#1a1206", stroke: "#fbbf24" },
    # { bg: "#1c1c1c", stroke: "#e5e5e5" },
    # { bg: "#f5f0e8", stroke: "#1c1c1c" },
    # { bg: "#e8f4f8", stroke: "#0369a1" },
    # { bg: "#fef3c7", stroke: "#92400e" }
    { bg: "#f9f9f9", stroke: "#000000" }
  ].freeze

  ALGORITHMS = %i[flow_field hilbert phyllotaxis tree rings].freeze

  W = 300.0
  H = 400.0

  def initialize(seed = Random.random_number * 100)
    @rng     = Random.new(seed.to_i)
    @noise   = ValueNoise.new(seed.to_i)
    @palette = PALETTES[@rng.rand(PALETTES.size)]
    @algo    = ALGORITHMS[@rng.rand(ALGORITHMS.size)]
    @sw      = (@rng.rand(3) * 0.3 + 0.5).round(2)
    @op      = (@rng.rand(5) * 0.08 + 0.45).round(2)
  end

  def to_svg
    polylines = send(@algo).map { |pts| polyline(pts) }.join("\n")

    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{W.to_i} #{H.to_i}"
           width="100%" height="100%" preserveAspectRatio="xMidYMid slice"
           style="display:block;">
        <rect width="100%" height="100%" fill="#{@palette[:bg]}"/>
        <g fill="none" stroke="#{@palette[:stroke]}" stroke-width="#{@sw}"
           stroke-opacity="#{@op}" stroke-linecap="round" stroke-linejoin="round">
        #{polylines}
        </g>
      </svg>
    SVG
  end

  private

  def polyline(pts)
    d = pts.map { |x, y| "#{x.round(2)},#{y.round(2)}" }.join(" ")
    %(<polyline points="#{d}"/>)
  end

  # --- Algorithms ---------------------------------------------------------

  # Many short streamlines following a Perlin-ish noise vector field.
  def flow_field
    paths = []
    cols  = 22
    rows  = 30
    scale = 0.010 + @rng.rand * 0.006
    turns = 2 + @rng.rand(3) # how many full rotations the field spans

    (0...cols).each do |i|
      (0...rows).each do |j|
        next if @rng.rand > 0.6

        t = Turtle.new(x: i / cols.to_f * W, y: j / rows.to_f * H)
        70.times do
          x, y = t.position
          break if x < -5 || x > W + 5 || y < -5 || y > H + 5

          t.setheading(@noise.noise(x * scale, y * scale) * 360 * turns)
          t.forward(5)
        end
        paths.concat(t.paths)
      end
    end
    paths
  end

  # Hilbert space-filling curve via L-system. One continuous line.
  def hilbert
    order = 5
    rules = { "A" => "+BF-AFA-FB+", "B" => "-AF+BFB+FA-" }
    s = "A"
    order.times { s = s.chars.map { |c| rules[c] || c }.join }

    n      = 2**order
    margin = 24.0
    step   = ([ W, H ].min - 2 * margin) / (n - 1)
    side   = step * (n - 1)
    t      = Turtle.new(x: (W - side) / 2, y: (H - side) / 2)

    s.each_char do |c|
      case c
      when "F" then t.forward(step)
      when "+" then t.left(90)
      when "-" then t.right(90)
      end
    end
    t.paths
  end

  # Golden-angle spiral of short noise-oriented strokes.
  def phyllotaxis
    paths  = []
    golden = 137.5
    cx     = W / 2
    cy     = H / 2
    c      = 7.5
    count  = 520

    (1..count).each do |i|
      a = i * golden * Math::PI / 180
      r = c * Math.sqrt(i)
      x = cx + r * Math.cos(a)
      y = cy + r * Math.sin(a)
      nn = @noise.noise(x * 0.012, y * 0.012)

      t = Turtle.new(x: x, y: y, heading: nn * 360)
      t.forward(2 + nn * 5)
      paths.concat(t.paths)
    end
    paths
  end

  # Recursive plant via L-system with a turtle stack.
  def tree
    rules = { "X" => "F+[[X]-X]-F[-FX]+X", "F" => "FF" }
    s = "X"
    5.times { s = s.chars.map { |c| rules[c] || c }.join }

    angle = 18 + @rng.rand(10)
    len   = 3.0
    t     = Turtle.new(x: W / 2, y: H - 12, heading: -90)
    stack = []

    s.each_char do |c|
      case c
      when "F" then t.forward(len)
      when "+" then t.right(angle)
      when "-" then t.left(angle)
      when "[" then stack.push([ t.position, t.h ])
      when "]"
        (pos, h) = stack.pop
        t.jump(pos[0], pos[1]).setheading(h)
      end
    end
    t.paths
  end

  # Concentric rings warped by noise — topographic / contour look.
  def rings
    paths = []
    cx    = W / 2
    cy    = H / 2
    count = 24
    gap   = ([ W, H ].min / 2.0 - 8) / count

    (1..count).each do |k|
      pts = []
      (0..360).step(4) do |deg|
        a  = deg * Math::PI / 180
        nn = @noise.noise(Math.cos(a) * 0.9 + k * 0.35, Math.sin(a) * 0.9 + k * 0.35)
        r  = k * gap + (nn - 0.5) * 16
        pts << [ cx + r * Math.cos(a), cy + r * Math.sin(a) ]
      end
      pts << pts.first
      paths << pts
    end
    paths
  end
end
