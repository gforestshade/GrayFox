
require 'set'

def calc_room_order(n, loop_count)
  g = Array.new(n) { Array.new(n) {|i| i} }
  r = Array.new(n-1) {|i| i + 1}

  min_d = n
  min_g = nil
  loop_count.times do
    r.shuffle!
    d = 0
    bucket = Set.new
    1.upto(n-1) do |i|
      from = g[i-1].index(r[i-1])
      bucket.add?(from) || d = d.succ
      n.times do |j|
        g[i][j] = (r[i-1] + j) % n
      end
    end
    if d < min_d then
      min_d = d
      min_g = g.map(&:clone)
    end
  end

  return [min_d, min_g]
end


