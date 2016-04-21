require 'matrix'
require 'pp'

# inputs
$DOF_per_node = 3
nnodes = 6
nelem  = 7
loads = Matrix[[0, 0, 0], [0, 0, 50], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, -15, 0]]
e = Array[10200, 10200, 10200, 10200, 10200, 10200, 10200]
#l = Array[16, 8, 8, 16, 18.113, 18.133, 16.25]
b = 1
h = 0.25

# definitions
class ElemPositions
  def initialize(x1, y1, x2, y2)
    @x1 = x1
    @y1 = y1
    @x2 = x2
    @y2 = y2
  end
end

class ElemForces
  def initialize(x1, y1, m1, x2, y2, m2)
    @x1 = x1
    @y1 = y1
    @m1 = m1
    @x2 = x2
    @y2 = y2
    @m2 = m2
  end
end

#===========#
# Member class
#===========#
class Member
  def initialize(a, i, e, p, f)
    @area = a
    @mom_iner = i
    @e = e
    #@e = # TODO
    @positions = p
    @forces = f
    @cos = nil
    @sin = nil
    @length = nil

    calculate_properties(p) # must come before set_matrix

    @k = set_matrix(@area, @mom_iner, @e, @length)
    pp @k
  end

  def calculate_properties(pos)
    dx = (pos.instance_variable_get(:@x2) - pos.instance_variable_get(:@x1)).abs
    dy = (pos.instance_variable_get(:@y2) - pos.instance_variable_get(:@y1)).abs
    @length = Math.sqrt(dx**2 + dy**2)
    @cos = dx/@length
    @sin = dy/@length
  end

  def set_matrix(a, i, e, l)
    m = Matrix.zero(6)
    m[0,0] = (e*i/l**3)* (a*l**2/i)
    m[0,3] = (e*i/l**3)*(-a*l**2/i)
    m[1,1] = (e*i/l**3)*        12
    m[1,2] = (e*i/l**3)*      (6*l)
    m[1,4] = (e*i/l**3)*       -12
    m[1,5] = (e*i/l**3)*      (6*l)
    m[2,1] = (e*i/l**3)*      (6*l)
    m[2,2] = (e*i/l**3)*   (4*l**2)
    m[2,4] = (e*i/l**3)*     (-6*l)
    m[2,5] = (e*i/l**3)*   (2*l**2)
    m[3,0] = (e*i/l**3)*(-a*l**2/i)
    m[3,3] = (e*i/l**3)* (a*l**2/i)
    m[4,1] = (e*i/l**3)*       -12
    m[4,2] = (e*i/l**3)*     (-6*l)
    m[4,4] = (e*i/l**3)*        12
    m[4,5] = (e*i/l**3)*     (-6*l)
    m[5,1] = (e*i/l**3)*      (6*l)
    m[5,2] = (e*i/l**3)*   (2*l**2)
    m[5,4] = (e*i/l**3)*     (-6*l)
    m[5,5] = (e*i/l**3)*   (4*l**2)
    m
  end

  def printMat()
    for i in 0..($DOF_per_node*2-1)
      for j in 0..($DOF_per_node*2-1)
        printf "%10.2f", @k[i,j]
      end
      puts("")
    end
    puts("")
  end
end






#==== script start =====

# input TODO have this be read in from file
p = Array.new() # elements
p.push(ElemPositions.new(0,  16.25, 16.0, 16.25)) # 1
p.push(ElemPositions.new(16, 16.25, 24.0, 16.25)) # 2
p.push(ElemPositions.new(0,  0,     8.0,  0))     # 3
p.push(ElemPositions.new(8,  0,     24, 0))     # 4
p.push(ElemPositions.new(8.0,  0,     16.0, 16.25)) # 5
p.push(ElemPositions.new(16.0, 16.25,  24.0, 0))    # 6
p.push(ElemPositions.new(24.0, 0,     24.0, 16.25)) # 7
f = Array.new() # elements
f.push(ElemForces.new(0, 0, 0, 0, 0, 50))   # 1
f.push(ElemForces.new(0, 0, 50, 0, 0, 0))   # 2
f.push(ElemForces.new(0, 0, 0, 0, 0, 0))    # 3
f.push(ElemForces.new(0, 0, 0, -15, 0, 0))  # 4
f.push(ElemForces.new(0, 0, 0, 0, 0, 50))   # 5
f.push(ElemForces.new(0, 0, 50, -15, 0, 0)) # 6
f.push(ElemForces.new(0, 0, -15, 0, 0, 0))  # 7


# calculate some parameteres
mom_inertia = (b*h**3)/12
area = b*h

# make array of Members
beams = Array.new(nelem)
beams.each_index { |i|
  beams[i] = Member.new(area, mom_inertia, e, p[i], f[i])
}
