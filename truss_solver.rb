require 'matrix'
require 'pp'
require 'nyaplot'

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
# Worked 1 example from slides
=begin
nnodes = 3
nelem  = 2
loads = Matrix[[0, 0, 0], [0, 0, 50], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, -15, 0]]
e = Array[29000, 29000]
=end
# Worked 2 example from slides
nnodes = 6
nelem = 6
loads = Matrix[[0, 0, 0], [100, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [10, 0, 0]]
e = Array[10200, 10200, 10200, 10200, 10200, 10200]
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
    @u = nil # not set until set_u() is called
    @q = nil # not set until set_q() is called
    @f = nil # not set until set_f() is called
    @r = nil # not set until set_reaction_forces() is called
    @r_nodes = nil # not set until set_reaction_forces() is called
    @sigma = nil # not set until set_stress() is called
    @epsilon = nil # not set until set_strain() is called

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
    @length = Math.sqrt(dx**2 + dy**2)
    @cos = dx/(@length)
    @sin = dy/(@length)
    p dx
    p dy
    p @cos
    p @sin
    p @length
    p ""
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

  def set_u(u)
    @u = u
  end

  def set_q(q)
    @q = q
  end

  def set_stress(s)
    @sigma = s
  end

  def set_strain(s)
    @epsilon = s
  end

  def set_f(f)
    @f = f
  end

  def set_reaction_forces(r, nodes)
    @r = r
    @r_nodes = nodes
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

  def self.printMat(m, size)
    for i in 0..(size-1)
      print "["
      for j in 0..(size-1)
        printf "%10.2f", m[i,j]
      end
      print "]"
      puts("")
    end
  end

  def self.printColumnVec(v, size)
    for i in 0..(size-1)
      printf "[ %12.6f ]\n", v[i,0]
    end
  end
end






#==== script start =====

# input TODO have this be read in from file
# Nodes
n = Array.new()
n.push(NodeNumbers.new(1)) # node 1 (0)
n.push(NodeNumbers.new(4)) # node 2
n.push(NodeNumbers.new(7)) # node 3
n.push(NodeNumbers.new(10)) # node 4
n.push(NodeNumbers.new(13)) # node 5
n.push(NodeNumbers.new(16)) # node 6

# Elements
p = Array.new() # elements
# Worked Example 1 from slides
=begin
p.push(ElemPositions.new(0,  0, n[0], 10.0, 20.0, n[1])) # 1
p.push(ElemPositions.new(10.0, 20.0, n[1], 30.0, 20.0, n[2])) # 2
=end
# Worked Example 2 from slides
p.push(ElemPositions.new(0,  0, n[0], 0, 8, n[1])) # 1
p.push(ElemPositions.new(0, 8, n[1], 0, 16, n[2])) # 2
p.push(ElemPositions.new(16.25, 0, n[3], 16.25, 8, n[4])) # 3
p.push(ElemPositions.new(16.25, 8, n[4], 16.25, 16, n[5])) # 4
p.push(ElemPositions.new(0, 8, n[1], 16.25, 8, n[4])) # 5
p.push(ElemPositions.new(0, 16, n[2], 16.25, 16, n[5])) # 6
=begin
p.push(ElemPositions.new(0,  16.25, 16.0, 16.25)) # 1
p.push(ElemPositions.new(16, 16.25, 24.0, 16.25)) # 2
p.push(ElemPositions.new(0,  0,     8.0,  0))     # 3
p.push(ElemPositions.new(8,  0,     24, 0))     # 4
p.push(ElemPositions.new(8.0,  0,     16.0, 16.25)) # 5
p.push(ElemPositions.new(16.0, 16.25,  24.0, 0))    # 6
p.push(ElemPositions.new(24.0, 0,     24.0, 16.25)) # 7
=end

# Forces on elements
f = Array.new() # elements
# Worked example 1 from slides
=begin
f.push(ElemForces.new(0, 0, 0, 50, 0, -1500))   # 1
f.push(ElemForces.new(50, 0, -1500, 0, 0, 0))   # 2
f_s_vec = [50, 0, -1500]         # s TODO I don't like this
=end
# Worked example 2 from slides
f.push(ElemForces.new(0, 0, 0, 0, 0, 100))   # 1
f.push(ElemForces.new(0, 0, 100, 0, 0, 0))   # 2
f.push(ElemForces.new(0, 0, 0, 0, 0, 0))   # 3
f.push(ElemForces.new(0, 0, 0, 10, 0, 0))   # 4
f.push(ElemForces.new(0, 0, 100, 0, 0, 0))   # 5
f.push(ElemForces.new(0, 0, 0, 10, 0, 0))   # 6
f_s_vec = [0, 0, 0.100, 0, 0, 0, 0, 0, 0, 0.010, 0, 0]
=begin
f.push(ElemForces.new(0, 0, 0, 0, 0, 50))   # 1
f.push(ElemForces.new(0, 0, 50, 0, 0, 0))   # 2
f.push(ElemForces.new(0, 0, 0, 0, 0, 0))    # 3
f.push(ElemForces.new(0, 0, 0, -15, 0, 0))  # 4
f.push(ElemForces.new(0, 0, 0, 0, 0, 50))   # 5
f.push(ElemForces.new(0, 0, 50, -15, 0, 0)) # 6
f.push(ElemForces.new(0, 0, -15, 0, 0, 0))  # 7
=end

# Worked 2 parameters
b = 1
h = 0.25


# calculate some parameteres
mom_inertia = (b*h**3)/12
area = b*h
# Worked 1 parameters
#mom_inertia = 310
#area = 11.8

# Worked example 1
#$s = MatrixSClass.new(3, n[1].instance_variable_get(:@nodes), f_s_vec)
# Worked example 2
u_con_nodes = [4, 5, 6, 7, 8, 9, 13, 14, 15, 16, 17, 18]
$s = MatrixSClass.new(12, u_con_nodes, f_s_vec)

# make array of Members
beams = Array.new(nelem)
p 'Local matrices in Global coordinates'
beams.each_index { |i|
  beams[i] = Member.new(area, mom_inertia, e[i], p[i], f[i])

  # build s
  a1 = Array.new()
  a2 = Array.new()
  for j in 0..($DOF_per_node*2-1)
    for k in 0..($s.instance_variable_get(:@size)-1)
      if ($s.instance_variable_get(:@nodes)[k] == beams[i].instance_variable_get(:@nodes)[j])
        a1.push(j)
        a2.push(k)
        break
      end
    end
  end
  for j in 0..(a1.size()-1)
    for k in 0..(a1.size()-1)
      $s.instance_variable_get(:@m)[a2[j],a2[k]] += beams[i].instance_variable_get(:@k_big)[a1[j],a1[k]]
    end
  end
}

# Calculate d
# get P as a column vector
p_column_vec = Matrix.column_vector($s.instance_variable_get(:@f))
# d = P^-1 * F
$d = $s.instance_variable_get(:@m).inverse * p_column_vec # TODO change d back to local variable if possible

# Calculate u for each member
beams.each_index { |i|
  # calculate v
  v = Array.new()
  for j in 0..($DOF_per_node*2-1)
    contained = false
    l = 0
    for k in 0..($s.instance_variable_get(:@size)-1)
      if (beams[i].instance_variable_get(:@nodes)[j] == $s.instance_variable_get(:@nodes)[k])
        contained = true
        l = k
      end
    end
    if contained
      v.push($d[l,0])
    else
      v.push(0.0)
    end
  end
  v_column = Matrix.column_vector(v)
  u = beams[i].instance_variable_get(:@t) * v_column
  beams[i].set_u(u)

  # calculate Q
  q = beams[i].instance_variable_get(:@k) * u
  beams[i].set_q(q)

  # calculate stress
  beams[i].set_stress((-1*q[0,0])/beams[i].instance_variable_get(:@area))

  # calculate strain
  beams[i].set_strain(beams[i].instance_variable_get(:@sigma)/beams[i].instance_variable_get(:@e))

  # calculate global force reations
  f = beams[i].instance_variable_get(:@t).transpose * q
  beams[i].set_f(f)

  # calculate reaction forces
  r = Array.new()
  r_nodes = Array.new()
  for j in 0..($DOF_per_node*2-1)
    is_reaction_force = true
    for k in 0..($s.instance_variable_get(:@size))
      if (beams[i].instance_variable_get(:@nodes)[j] == $s.instance_variable_get(:@nodes)[k])
        is_reaction_force = false
        break
      end
    end
    if is_reaction_force
      r.push(f[j,0])
      r_nodes.push(beams[i].instance_variable_get(:@nodes)[j])
    end
  end
  r = Matrix.column_vector(r)
  beams[i].set_reaction_forces(r, r_nodes)
}


# Print output
puts "Output"
beams.each_index { |i|
  # local k
  printf "Member %d\n", i+1
  puts "k"
  Member.printMat(beams[i].instance_variable_get(:@k), $DOF_per_node*2)

  # global K
  puts "K"
  Member.printMat(beams[i].instance_variable_get(:@k_big), $DOF_per_node*2)

  # u
  puts "u"
  Member.printColumnVec(beams[i].instance_variable_get(:@u), $DOF_per_node*2)

  # Q
  puts "q"
  Member.printColumnVec(beams[i].instance_variable_get(:@q), $DOF_per_node*2)

  # F
  puts "F"
  Member.printColumnVec(beams[i].instance_variable_get(:@f), $DOF_per_node*2)

  puts "R"
  Member.printColumnVec(beams[i].instance_variable_get(:@r), beams[i].instance_variable_get(:@r_nodes).size())

  # stress
  printf "axial stress (sigma): %10.6e ksi\n", beams[i].instance_variable_get(:@sigma)

  # strain
  printf "axial strain (epsilon): %10.6e micron\n", beams[i].instance_variable_get(:@epsilon)*10**6

  puts ""
}

# globals
puts "\nGlobals"
# S
puts "S"
Member.printMat($s.instance_variable_get(:@m), $s.instance_variable_get(:@size))

# d
puts "d"
Member.printColumnVec($d, $s.instance_variable_get(:@size))


# Calculate sigma_b (stress due to moment) for members 5 and 6
sigma_b = Array.new()
for i in 4..5
  c = 0
  s = Array.new()
  for j in 0..100
    #s_tmp = c*()
    #s.push(beams[i]
  end
end

x = 0
c_top = h/2
c_bottom = -1*h/2
q2 = beams[0].instance_variable_get(:@q)[1,0]
q3 = beams[0].instance_variable_get(:@q)[2,0]
l = beams[0].instance_variable_get(:@length)
sig_b_top = Array.new()
sig_b_bottom = Array.new()
i_ar = Array.new()
for i in 0..5
  i_ar.push(i)
  x = l*(i/5.0)
  p q2
  p q3
  sig_b_top.push(c_top*(q2*x - q3)/ beams[0].instance_variable_get(:@mom_iner))
  sig_b_bottom.push(c_bottom*(q2*x - q3)/ beams[0].instance_variable_get(:@mom_iner))
  printf "%16.12f\n", sig_b_top[i]
  printf "%16.12f\n", sig_b_bottom[i]
end

plot = Nyaplot::Plot.new
sc = plot.add(:line, i_ar, sig_b_top, {color: "#fbb4ae"})
sc = plot.add(:line, i_ar, sig_b_bottom, {color: "#b3cde3"})
plot.export_html
