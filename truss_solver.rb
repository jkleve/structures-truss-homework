require 'matrix'
require 'pp'

# inputs
$DOF_per_node = 3
=begin
nnodes = 6
nelem  = 7
loads = Matrix[[0, 0, 0], [0, 0, 50], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, -15, 0]]
e = Array[10200, 10200, 10200, 10200, 10200, 10200, 10200]
#l = Array[16, 8, 8, 16, 18.113, 18.133, 16.25]
b = 1
h = 0.25
=end
nnodes = 3
nelem  = 2
loads = Matrix[[0, 0, 0], [0, 0, 50], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, -15, 0]]
e = Array[29000, 29000]
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
    @positions = p
    @forces = f
    @cos = nil
    @sin = nil
    @length = nil
    @t = nil

    calculate_properties(p) # must come before set_matrix
    @t = calculate_T()


    @k = set_matrix(@area, @mom_iner, @e, @length)

    @big_k = @t.transpose*@k*@t # TODO which one is right
    printMat(@big_k)

    @k_big = convert_to_global(@cos, @sin, @area, @mom_iner, @length)
  end

  def calculate_properties(pos)
    dx = (pos.instance_variable_get(:@x2) - pos.instance_variable_get(:@x1)).abs
    dy = (pos.instance_variable_get(:@y2) - pos.instance_variable_get(:@y1)).abs
    @length = Math.sqrt(dx**2 + dy**2)
    @cos = dx/@length
    @sin = dy/@length
  end

  def calculate_T()
    t = Matrix.zero($DOF_per_node*2)
    t[0,0] = @cos
    t[0,1] = @sin
    t[1,0] = -1*@sin
    t[1,1] = @cos
    t[2,2] = 1
    t[3,3] = @cos
    t[3,4] = @sin
    t[4,3] = -1*@sin
    t[4,4] = @cos
    t[5,5] = 1
    t

=begin
    @t = [[ @c, @s, 0,   0,  0, 0],
          [-1*@s, @c, 0,   0,  0, 0],
          [  0,  0, 1,   0,  0, 0],
          [  0,  0, 0,  @c, @s, 0],
          [  0,  0, 0, -1*@s, @c, 0],
          [  0,  0, 0,   0,  0, 1]]
=end
  end

  def set_matrix(a, i, e, l)
    m = Matrix.zero($DOF_per_node*2)
=begin
    m = [[ (e*i/l**3)*(a*l**2.0/i),                  0,                       0, (e*i/l**3)*(-a*l**2.0/i),                   0,                       0],
         [                       0,    (e*i/l**3)*12.0,      (e*i/l**3)*(6.0*l),                        0,    (e*i/l**3)*-12.0,      (e*i/l**3)*(6.0*l)],
         [                       0, (e*i/l**3)*(6.0*l), (e*i/l**3)*(4.0*l**2.0),                        0, (e*i/l**3)*(-6.0*l), (e*i/l**3)*(2.0*l**2.0)],
         [(e*i/l**3)*(-a*l**2.0/i),                  0,                       0,  (e*i/l**3)*(a*l**2.0/i),                   0,                       0],
         [                       0,              -12.0,     (e*i/l**3)*(-6.0*l),                        0,                12.0,     (e*i/l**3)*(-6.0*l)],
         [                       0, (e*i/l**3)*(6.0*l), (e*i/l**3)*(2.0*l**2.0),                        0, (e*i/l**3)*(-6.0*l), (e*i/l**3)*(4.0*l**2.0)]]
    p m[0,0]
=end
    m[0,0] = (e*i/l**3)* (a*l**2.0/i)
    m[0,3] = (e*i/l**3)*(-a*l**2.0/i)
    m[1,1] = (e*i/l**3)*        12.0
    m[1,2] = (e*i/l**3)*      (6.0*l)
    m[1,4] = (e*i/l**3)*       -12.0
    m[1,5] = (e*i/l**3)*      (6.0*l)
    m[2,1] = (e*i/l**3)*      (6.0*l)
    m[2,2] = (e*i/l**3)* (4.0*l**2.0)
    m[2,4] = (e*i/l**3)*     (-6.0*l)
    m[2,5] = (e*i/l**3)* (2.0*l**2.0)
    m[3,0] = (e*i/l**3)*(-a*l**2.0/i)
    m[3,3] = (e*i/l**3)* (a*l**2.0/i)
    m[4,1] = (e*i/l**3)*       -12.0
    m[4,2] = (e*i/l**3)*     (-6.0*l)
    m[4,4] = (e*i/l**3)*        12.0
    m[4,5] = (e*i/l**3)*     (-6.0*l)
    m[5,1] = (e*i/l**3)*      (6.0*l)
    m[5,2] = (e*i/l**3)* (2.0*l**2.0)
    m[5,4] = (e*i/l**3)*     (-6.0*l)
    m[5,5] = (e*i/l**3)* (4.0*l**2.0)
    m
  end

  def convert_to_global(c, s, a, i, l)
    k_big = Matrix.zero($DOF_per_node*2)
    k_big[0,0] = a*l**2*c**2/i + 12*s**2
    k_big[0,1] = (a*l**2/i - 12)*c*s
    k_big[0,2] = -6*l*s
    k_big[0,3] = -1*(a*l**2/i*c**2 + 12*s**2)
    k_big[0,4] = -1*(a*l**2/i - 12)*c*s
    k_big[0,5] = -6*l*s

    k_big[1,0] = (a*l**2/i - 12)*c*s
    k_big[1,1] = a*l**2*s**2/i + 12*c**2
    k_big[1,2] = 6*l*c
    k_big[1,3] = -1*(a*l**2/i - 12)*c*s
    k_big[1,4] = -1*(a*l**2*s**2/i + 12*c**2)
    k_big[1,5] = 6*l*c

    k_big[2,0] = -6*l*s
    k_big[2,1] = 6*l*c
    k_big[2,2] = 4*l**2
    k_big[2,3] = 6*l*s
    k_big[2,4] = -6*l*c
    k_big[2,5] = 2*l**2

    k_big[3,0] = -1*(a*l**2*c**2/i + 12*s**2)
    k_big[3,1] = -1*(a*l**2/i - 12)*c*s
    k_big[3,2] = 6*l*s
    k_big[3,3] = a*l**2*c**2/i + 12*s**2
    k_big[3,4] = (a*l**2/i - 12)*c*s
    k_big[3,5] = 6*l*s

    k_big[4,0] = -1*(a*l**2/i - 12)*c*s
    k_big[4,1] = -1*(a*l**2*s**2/i + 12*c**2)
    k_big[4,2] = -6*l*c
    k_big[4,3] = (a*l**2/i - 12)*c*s
    k_big[4,4] = a*l**2*s**2/i + 12*c**2
    k_big[4,5] = -6*l*c

    k_big[5,0] = -6*l*s
    k_big[5,1] = 6*l*c
    k_big[5,2] = 2*l**2
    k_big[5,3] = 6*l*s
    k_big[5,4] = -6*l*c
    k_big[5,5] = 4*l**2
    k_big
  end

  def printMatrix()
    for i in 0..($DOF_per_node*2-1)
      print "["
      for j in 0..($DOF_per_node*2-1)
        printf "%10.2f", @k_big[i,j]
      end
      print "]"
      puts("")
    end
  end

  def printMat(m)
    for i in 0..($DOF_per_node*2-1)
      print "["
      for j in 0..($DOF_per_node*2-1)
        printf "%10.2f", m[i,j]
      end
      print "]"
      puts("")
    end
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
#mom_inertia = (b*h**3)/12 TODO
#area = b*h
mom_intertia = 310
area = 11.8

# make array of Members
beams = Array.new(nelem)
p 'Local matrices in Global coordinates'
beams.each_index { |i|
  beams[i] = Member.new(area, mom_inertia, e[i], p[i], f[i])
  # Print matrix
  printf "Matrix %d\n", (i+1)
  beams[i].printMatrix()
  #beams[i].printMat(beams[i].instance_variable_get(:@t))
  t = beams[i].instance_variable_get(:@t)
  k = beams[i].instance_variable_get(:@k)
=begin
  pp k
  p 'k'
  beams[i].printMat(k)
  p ''
  t_trans = t.transpose
  beams[i].printMat(t)
  k_1 = t_trans*k
  p ''
  beams[i].printMat(t_trans)
=end
  #big_k = t_trans*k
  #beams[i].printMat(big_k)
  #pp beams[i].instance_variable_get(:@t)
}
