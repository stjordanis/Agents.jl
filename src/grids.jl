# A grid can be 0D (a node), 1D (a line of nodes), 2D (a surface of nodes) or 3D (a surface of nodes with values at each node).

"""
An abstract grid type. Your grid type should have the following fields: `dimensions` (Tuple{Integer, Integer, Integer}), agent_positions (Array{Array{Integer}}), and `grid`.
"""
abstract type AbstractGrid end

# TODO: Continuous space where each agent can have an arbitrary position.
# TODO: Hexagonal Grid: Extends Grid to handle hexagonal neighbors.

function grid0D() <: AbstractSpace
end

function grid1D(length::Integer; periodic=false)
  if periodic
    g = PathGraph(length)
    add_edge!(g, 1, length)
  else
    g = PathGraph(length)
  end
end

function grid2D(n::Integer, m::Integer; periodic=false)
  g = Grid([n, m], periodic=periodic)
end

function grid3D()
  #TODO
  throw("3D grids are not implemented yet!")
end

"""
A regular grid with equilateral triangles. 
"""
function grid2D_triangles(n::Integer, m::Integer; periodic=false)
  g = Grid([n, m], periodic=periodic)
  for x in 1:n
    for y in 1:m
      nodeid = coord_to_vertex((x, y, 1), (n, m, 1))
      connect_to = []
      if y == m
        if x == 1
          if periodic
            tp = (n, 1, 1); push!(connect_to, tp)
            tp = (2, m-1, 1); push!(connect_to, tp)
          else
            tp = (2, m-1, 1); push!(connect_to, tp)
          end
        elseif x == n
          if periodic
            tp = (1, 1, 1); push!(connect_to, tp)
            tp = (n-1, m-1, 1); push!(connect_to, tp)
          else
            tp = (n-1, m-1, 1); push!(connect_to, tp)
          end
        else
          if periodic
            tp = (x-1, 1, 1); push!(connect_to, tp)
            tp = (x+1, 1, 1); push!(connect_to, tp)
            tp = (x-1, y-1, 1); push!(connect_to, tp)
            tp = (x+1, y-1, 1); push!(connect_to, tp)
          else
            tp = (x-1, y-1, 1); push!(connect_to, tp)
            tp = (x+1, y-1, 1); push!(connect_to, tp)
          end
        end
      elseif y == 1
        if x == 1
          if periodic
            tp = (n, m, 1); push!(connect_to, tp)
            tp = (2, y+1, 1); push!(connect_to, tp)
          else
            tp = (2, y+1, 1); push!(connect_to, tp)
          end
        elseif x == n
          if periodic
            tp = (1, y, 1); push!(connect_to, tp)
            tp = (n-1, y+1, 1); push!(connect_to, tp)
          else
            tp = (n-1, y+1, 1); push!(connect_to, tp)
          end
        else
          if periodic
            tp = (x-1, y+1, 1); push!(connect_to, tp)
            tp = (x+1, y+1, 1); push!(connect_to, tp)
            tp = (x-1, m, 1); push!(connect_to, tp)
            tp = (x+1, m, 1); push!(connect_to, tp)
          else
            tp = (x-1, y+1, 1); push!(connect_to, tp)
            tp = (x+1, y+1, 1); push!(connect_to, tp)
          end
        end
      elseif y != 1 && y != m && x == 1
        if periodic
          tp = (x+1, y+1, 1); push!(connect_to, tp)
          tp = (x+1, y-1, 1); push!(connect_to, tp)
          tp = (n, y+1, 1); push!(connect_to, tp)
          tp = (n, y-1, 1); push!(connect_to, tp)
        else
          tp = (x+1, y+1, 1); push!(connect_to, tp)
          tp = (x+1, y-1, 1); push!(connect_to, tp)
        end       
      elseif y != 1 && y != m && x == n
        if periodic
          tp = (x-1, y+1, 1); push!(connect_to, tp)
          tp = (x-1, y-1, 1); push!(connect_to, tp)
          tp = (1, y+1, 1); push!(connect_to, tp)
          tp = (1, y-1, 1); push!(connect_to, tp)
        else
          tp = (x-1, y+1, 1); push!(connect_to, tp)
          tp = (x-1, y-1, 1); push!(connect_to, tp)
        end  
      else
          tp = (x+1, y+1, 1); push!(connect_to, tp)
          tp = (x-1, y-1, 1); push!(connect_to, tp)
          tp = (x+1, y-1, 1); push!(connect_to, tp)
          tp = (x-1, y+1, 1); push!(connect_to, tp)             
      end

      for pp in connect_to
        add_edge!(g, nodeid, coord_to_vertex((pp[1], pp[2], 1), (n, m, 1)))
      end
    end
  end
  return g
end

"""
    grid(x::Ingeter, y::Integer, z::Integer)

Return a grid based on its size.
"""
function grid(x::Integer, y::Integer, z::Integer, periodic=false, triangle=false)
  if x < 1 || y < 1 || z < 1
    throw("x, y, or z can be minimum 1!")
  end
  if x + y + z == 1
    g = grid0D()
  elseif x > 1 && y == 1 && z == 1
    g = grid1D(x, periodic=periodic)
  elseif x > 1 && y > 1 && z == 1
    if triangle
      g = grid2D_triangles(x, y, periodic=periodic)
    else
      g = grid2D(x, y, periodic=periodic)
    end
  elseif x > 1 && y > 1 && z > 1
    g = grid3D(x, y, z)
  else
    throw("Invalid grid dimensions! If only one dimension is 1, it should be `z`, if two dimensions are 1, they should be `y` and `z`.")
  end
  return g
end

function grid(dims::Tuple{Integer, Integer, Integer}, periodic=false, triangle=false)
  grid(dims[1], dims[2], dims[3], periodic, triangle)
end

function gridsize(dims::Tuple{Integer, Integer, Integer})
  dims[1] * dims[2] * dims[3]
end

# function empty_pos_container(model::AbstractModel)
#   container = Array{Array{AbstractAgent}}(undef, )
# end

"""
Add `agentID` to a position in the grid. `pos` is tuple of x, y, z coordinates of the grid node. if `pos` is not given, the agent is added to a random position 
"""
function move_agent_on_grid!(agent::AbstractAgent, pos::Tuple{Integer, Integer, Integer}, model::AbstractModel)
  agentID = agent.id
  # node number from x, y, z coordinates
  nodenumber = coord_to_vertex(pos, model)
  push!(model.grid.agent_positions[nodenumber], agentID)
  # remove agent from old position
  oldnode = coord_to_vertex(agent.pos, model)
  splice!(model.grid.agent_positions[oldnode], findfirst(a->a==agent.id, model.grid.agent_positions[oldnode]))
  agent.pos = pos  # update agent position
end

function move_agent_on_grid!(agent::AbstractAgent, pos::Integer, model::AbstractModel)
  agentID = agent.id
  nodenumber = pos
  push!(model.grid.agent_positions[nodenumber], agentID)
  # remove agent from old position
  oldnode = coord_to_vertex(agent.pos, model)
  splice!(model.grid.agent_positions[oldnode], findfirst(a->a==agent.id, model.grid.agent_positions[oldnode]))
  agent.pos = vertex_to_coord(pos, model)  # update agent position
end

function move_agent_on_grid!(agent::AbstractAgent, model::AbstractModel)
  agentID = agent.id
  nodenumber = rand(1:nv(model.grid.grid))
  push!(model.grid.agent_positions[nodenumber], agentID)
  # remove agent from old position
  oldnode = coord_to_vertex(agent.pos, model)
  splice!(model.grid.agent_positions[oldnode], findfirst(a->a==agent.id, model.grid.agent_positions[oldnode]))
  agent.pos = vertex_to_coord(nodenumber, model) # update agent position
end

"""
Add `agentID` to a position in the grid. `pos` is tuple of x, y, z coordinates of the grid node. if `pos` is not given, the agent is added to a random position 
"""
function add_agent_to_grid!(agent::AbstractAgent, pos::Tuple{Integer, Integer, Integer}, model::AbstractModel)
  agentID = agent.id
  # node number from x, y, z coordinates
  nodenumber = coord_to_vertex(pos, model)
  push!(model.grid.agent_positions[nodenumber], agentID)
  agent.pos = pos  # update agent position
end

function add_agent_to_grid!(agent::AbstractAgent, model::AbstractModel)
  agentID = agent.id
  nodenumber = rand(1:nv(model.grid.grid))
  push!(model.grid.agent_positions[nodenumber], agentID)
  agent.pos = vertex_to_coord(nodenumber, model) # update agent position
end

"""
    move_agent_on_grid_single!(agent::AbstractAgent, model::AbstractModel)

Randomly move agents to another nodes on the grid while keeping a maximum one agent per node.
"""
function move_agent_on_grid_single!(agent::AbstractAgent, model::AbstractModel)
  empty_cells = [i for i in 1:length(model.grid.agent_positions) if length(model.grid.agent_positions[i]) == 0]
  random_node = rand(empty_cells)
  move_agent_on_grid!(agent, random_node, model)
end

"""
    add_agent_to_grid_single!(agent::AbstractAgent, model::AbstractModel)

Randomly add agent to a node on the grid while keeping a maximum one agent per node.
"""
function add_agent_to_grid_single!(agent::AbstractAgent, model::AbstractModel)
  empty_cells = [i for i in 1:length(model.grid.agent_positions) if length(model.grid.agent_positions[i]) == 0]
  random_node = rand(empty_cells)
  add_agent_to_grid!(agent, vertex_to_coord(random_node, model), model)
end


"""
get node number from x, y, z coordinates
"""
function coord_to_vertex(coord::Tuple{Integer, Integer, Integer}, model::AbstractModel)
  dims = model.grid.dimensions
  if dims[1] > 1 && dims[2] == 1 && dims[3] == 1  # 1D grid
    nodeid = coord[1]
  elseif dims[1] > 1 && dims[2] > 1 && dims[3] == 1  # 2D grid
    nodeid = (coord[2] * dims[2]) - (dims[2] - coord[1])  # (y * xlength) - (xlength - x)
  else # 3D grid
    #TODO
  end
end

"""
get node number from x, y, z coordinates
"""
function coord_to_vertex(coord::Tuple{Integer, Integer, Integer}, dims::Tuple{Integer, Integer, Integer})
  if dims[1] > 1 && dims[2] == 1 && dims[3] == 1  # 1D grid
    nodeid = coord[1]
  elseif dims[1] > 1 && dims[2] > 1 && dims[3] == 1  # 2D grid
    nodeid = (coord[2] * dims[2]) - (dims[2] - coord[1])  # (y * xlength) - (xlength - x)
  else # 3D grid
    #TODO
  end
end

"""
    vertex_to_coord(vertex::Integer, model::AbstractModel)

Return the coordinates of a node number on the grid
"""
function vertex_to_coord(vertex::Integer, model::AbstractModel)
  dims = model.grid.dimensions
  if dims[1] > 1 && dims[2] == 1 && dims[3] == 1  # 1D grid
    coord = (vertex, 1, 1)
  elseif dims[1] > 1 && dims[2] > 1 && dims[3] == 1  # 2D grid
    x = vertex % dims[1]
    if x == 0
      x = dims[1]
    end
    y = ceil(Integer, vertex/dims[1])
    coord = (x, y, 1)
  else # 3D grid
    #TODO
  end
  return coord
end

"""
    vertex_to_coord(vertex::Integer, dims::Tuple{Integer, Integer, Integer})

Return the coordinates of a node number on the grid
"""
function vertex_to_coord(vertex::Integer, dims::Tuple{Integer, Integer, Integer})
  if dims[1] > 1 && dims[2] == 1 && dims[3] == 1  # 1D grid
    coord = (vertex, 1, 1)
  elseif dims[1] > 1 && dims[2] > 1 && dims[3] == 1  # 2D grid
    x = vertex % dims[1]
    if x == 0
      x = dims[1]
    end
    y = ceil(Integer, vertex/dims[1])
    coord = (x, y, 1)
  else # 3D grid
    #TODO
  end
  return coord
end

"""
    get_node_contents(agent::AbstractAgent, model::AbstractModel)
  
Return other agents in the same node as the `agent`.
"""
function get_node_contents(agent::AbstractAgent, model::AbstractModel)
  agent_node = coord_to_vertex(agent.pos, model)
  ns = model.grid.agent_positions[agent_node] # TODO: exclude agent
end

"""
    get_node_contents(coords::Tuple, model::AbstractModel)

Return the content of the node at `coords`
"""
function get_node_contents(coords::Tuple, model::AbstractModel)
  node_number = coord_to_vertex(coords, model)
  ns = model.grid.agent_positions[node_number] # TODO: exclude agent
end

"""
Return neighboring nodes of the node on which the agent resides.
"""
function node_neighbors(agent::AbstractAgent, model::AbstractModel)
  agent_node = coord_to_vertex(agent.pos, model)
  nn = neighbors(model.grid.grid, agent_node)
  nc = [vertex_to_coord(i, model) for i in nn]
end
