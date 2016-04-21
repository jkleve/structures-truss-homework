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
=begin
class NodeNumbers
  def initialize(start1, start2)
    nodes1 = Array.new()
    nodes2 = Array.new()
    for i in 0..2
      nodes1.push(start1 + i)
      nodes2.push(start2 + i)
    end
  end
end
=end
class MatrixSClass
  def initialize(m_size, nodes, f)
    @size = m_size
    @m = Matrix.zero(m_size)
    @nodes = nodes
    @f = f
  end
end

class NodeNumbers
  def initialize(start)
    @nodes = Array.new()
    for i in 0..2
      @nodes.push(start + i)
    end
  end
end

class ElemPositions
  def initialize(x1, y1, n1, x2, y2, n2)
    @x1 = x1
    @y1 = y1
    @nodes1 = n1
    @x2 = x2
    @y2 = y2
    @nodes2 = n2
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
    @nodes = get_nodes(p)
    @forces = f
    @cos = nil
    @sin = nil
    @length = nil
    @t = nil

    calculate_properties(p) # must come before set_matrix
    @t = calculate_T()


    @k = set_matrix(@area, @mom_iner, @e, @length)

    @k_big = @t.transpose*@k*@t # TODO which one is right
    #printMat(@big_k)

    #@k_big = convert_to_global(@cos, @sin, @area, @mom_iner, @length)
  end

  def get_nodes(p)
    r = Array.new()
    nodes1 = p.instance_variable_get(:@nodes1).instance_variable_get(:@nodes)
    nodes2 = p.instance_variable_get(:@nodes2).instance_variable_get(:@nodes)
    nodes1.each{ |node| r.push(node) }
    nodes2.each{ |node| r.push(node) }
    r
  end

  def calculate_properties(pos)
    dx = (pos.instance_variable_get(:@x2) - pos.instance_variable_get(:@x1)).abs
    dy = (pos.instance_variable_get(:@y2) - pos.instance_variable_get(:@y1)).abs
    @length = Math.sqrt(dx**2 + dy**2)*12
    @cos = dx/(@length/12)
    @sin = dy/(@length/12)
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
  end

  def set_matrix(a, i, e, l)
    m = Matrix.zero($DOF_per_node*2)
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
# Nodes
n = Array.new()
n.push(NodeNumbers.new(1))
n.push(NodeNumbers.new(4))
n.push(NodeNumbers.new(7))

# Elements
p = Array.new() # elements
#p n[0].instance_variable_get(:@nodes)
p.push(ElemPositions.new(0,  0, n[0], 10.0, 20.0, n[1])) # 1
p.push(ElemPositions.new(10.0, 20.0, n[1], 30.0, 20.0, n[2])) # 2
=begin
p.push(ElemPositions.new(0,  16.25, 16.0, 16.25)) # 1
p.push(ElemPositions.new(16, 16.25, 24.0, 16.25)) # 2
p.push(ElemPositions.new(0,  0,     8.0,  0))     # 3
p.push(ElemPositions.new(8,  0,     24, 0))     # 4
p.push(ElemPositions.new(8.0,  0,     16.0, 16.25)) # 5
p.push(ElemPositions.new(16.0, 16.25,  24.0, 0))    # 6
p.push(ElemPositions.new(24.0, 0,     24.0, 16.25)) # 7
=end
f = Array.new() # elements
f.push(ElemForces.new(0, 0, 0, 50, 0, -125))   # 1
f.push(ElemForces.new(50, 0, -125, 0, 0, 0))   # 2
f_s_vec = [50, 0, -125]         # s TODO I don't like this
=begin
f.push(ElemForces.new(0, 0, 0, 0, 0, 50))   # 1
f.push(ElemForces.new(0, 0, 50, 0, 0, 0))   # 2
f.push(ElemForces.new(0, 0, 0, 0, 0, 0))    # 3
f.push(ElemForces.new(0, 0, 0, -15, 0, 0))  # 4
f.push(ElemForces.new(0, 0, 0, 0, 0, 50))   # 5
f.push(ElemForces.new(0, 0, 50, -15, 0, 0)) # 6
f.push(ElemForces.new(0, 0, -15, 0, 0, 0))  # 7
=end


# calculate some parameteres
#mom_inertia = (b*h**3)/12 TODO
#area = b*h
mom_inertia = 310
area = 11.8
$s = MatrixSClass.new(3, n[1].instance_variable_get(:@nodes), f_s_vec)

# make array of Members
beams = Array.new(nelem)
p 'Local matrices in Global coordinates'
beams.each_index { |i|
  beams[i] = Member.new(area, mom_inertia, e[i], p[i], f[i])
  # Print matrix
  printf "Matrix %d\n", (i+1)
  beams[i].printMatrix()

  # build s
  a1 = Array.new()
  a2 = Array.new()
  for j in 0..($DOF_per_node*2-1)
    for k in 0..($s.instance_variable_get(:@size)-1)
      if ($s.instance_variable_get(:@nodes)[k] == beams[i].instance_variable_get(:@nodes)[j])
        a1.push(j)
        a2.push(k)
      end
    end
  end
  for j in 0..(a1.size()-1)
    for k in 0..(a1.size()-1)
      $s.instance_variable_get(:@m)[a2[j],a2[k]] += beams[i].instance_variable_get(:@k_big)[a1[j],a1[k]]
    end
  end
}
d = $s.instance_variable_get(:@m).transpose * $s.instance_variable_get(:@f).transpose
p d
