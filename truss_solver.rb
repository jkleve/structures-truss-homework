require 'matrix'
require 'pp'

# inputs
$DOF_per_node = 3
nnodes = 6
nelem  = 7
loads = Matrix[[0, 0, 0], [0, 0, 50], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, -15, 0]]
l = Array[16, 8, 8, 16, 18.113, 18.133, 16.25]
p = Array.new() # pins
b = 1
h = 0.25

# definitions
class Position
  def initialize(x, y)
    @x = x
    @y = y
  end
end

# input TODO have this be read in from file
p.push(Position.new(0, 16.25)) # 1
p.push(Position.new(16, 16.25)) # 2
p.push(Position.new(24, 16.25)) # 3
p.push(Position.new(0, 0)) # 4
p.push(Position.new(8, 0)) # 5
p.push(Position.new(24, 0)) # 6

class Member
  def initialize(a, i, p1, p2)
    @area = a
    @i = i
    #@length = l
    @l = calculate_length(p)
    @k = set_matrix(a, i, l)
    @x = 0
    @y = 0
    @m = 0
  end

  def set_x_force(x)
    @x = x
  end
  def set_y_force(y)
    @y = y
  end
  def set_moment(m)
    @m = m
  end

  def calculate_length(p)
    l = 
    l
  end

  def set_matrix(a, i, l)
    m = Matrix.zero(6)
    m[0,0] = a*l**2/i
    m[0,3] = -a*l**2/i
    m[1,1] = 12
    m[1,2] = 6*l
    m[1,4] = -12
    m[1,5] = 6*l
    m[2,1] = 6*l
    m[2,2] = 4*l**2
    m[2,4] = -6*l
    m[2,5] = 2*l**2
    m[3,0] = -a*l**2/i
    m[3,3] = a*l**2/i
    m[4,1] = -12
    m[4,2] = -6*l
    m[4,4] = 12
    m[4,5] = -6*l
    m[5,1] = 6*l
    m[5,2] = 2*l**2
    m[5,4] = -6*l
    m[5,5] = 4*l**2
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
# calculate some parameteres
i_all = (b*h**3)/12
i = Array.new(nelem, i_all)
area = b*h

# make array of Members
beams = Array.new(nelem)
for i in 0..(beams.size()-1)
  beams[i] = Member.new(area, i_all, p[i], p[i+1]) # doesn't work
  beams[i].printMat()
end




