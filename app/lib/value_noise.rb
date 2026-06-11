# Deterministic 2D value noise (no gem dependency). Same seed => same field.
# Returns values in 0.0..1.0.
class ValueNoise
  MASK = 0xFFFFFFFF

  def initialize(seed)
    @seed = seed.to_i & MASK
  end

  def noise(x, y)
    xi = x.floor
    yi = y.floor
    xf = x - xi
    yf = y - yi

    tl = hash(xi,     yi)
    tr = hash(xi + 1, yi)
    bl = hash(xi,     yi + 1)
    br = hash(xi + 1, yi + 1)

    u = smooth(xf)
    v = smooth(yf)

    top = tl + (tr - tl) * u
    bot = bl + (br - bl) * u
    top + (bot - top) * v
  end

  private

  def smooth(t)
    t * t * (3 - 2 * t)
  end

  def hash(xi, yi)
    n = (xi * 374_761_393 + yi * 668_265_263 + @seed * 374_761) & MASK
    n = ((n ^ (n >> 13)) * 1_274_126_177) & MASK
    n / MASK.to_f
  end
end
