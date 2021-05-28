extends Node2D

const map_width = 16
const map_height = 16
const map = Array()

class Empire:
    var color: Color

class Unit:
    var control: int
    var speed: int
    var empire: int
    var tile_x: int
    var tile_y: int

const empires = Array()
const allies = Array()
const units = Array()

# Called when the node enters the scene tree for the first time.
func _ready():
    for empire_color in [Color.red, Color.green, Color.blue, Color.yellow]:
        var e = Empire.new()
        e.color = empire_color
        empires.push_back(e)
    allies.push_back(Vector2(1, 2))
    
    map.clear()
    map.resize(map_width)
    for x in range(map_width):
        var a = Array()
        a.resize(map_height)
        map[x] = a
    
    # set units
    var u0 = Unit.new()
    u0.empire = 0
    u0.control = 10
    u0.speed = 10
    u0.tile_x = 1
    u0.tile_y = 1
    units.push_back(u0)
    
    var u1 = Unit.new()
    u1.empire = 1
    u1.control = 10
    u1.speed = 10
    u1.tile_x = 1
    u1.tile_y = 3
    units.push_back(u1)
    
    var u11 = Unit.new()
    u11.empire = 1
    u11.control = 10
    u11.speed = 10
    u11.tile_x = 1
    u11.tile_y = 5
    units.push_back(u11)
    
    var u2 = Unit.new()
    u2.empire = 2
    u2.control = 15
    u2.speed = 10
    u2.tile_x = 1
    u2.tile_y = 14
    units.push_back(u2)
    
    var u3 = Unit.new()
    u3.empire = 3
    u3.control = 10
    u3.speed = 10
    u3.tile_x = 14
    u3.tile_y = 1
    units.push_back(u3)
    
    calc_zones()
    
func calc_zones():
    var astar = AStar2D.new()
    astar.reserve_space(map_width * map_height)
    for x in range(map_width):
        for y in range(map_height):
            astar.add_point(x + map_width * y, Vector2(x, y))
    for x in range(map_width):
        for y in range(map_height):
            if x > 0:
                astar.connect_points(x + map_width * y, (x - 1) + map_width * y, true)
            if x < map_width - 1:
                astar.connect_points(x + map_width * y, (x + 1) + map_width * y, true)
            if y > 0:
                astar.connect_points(x + map_width * y, x + map_width * (y - 1), true)
            if y < map_height - 1:
                astar.connect_points(x + map_width * y, x + map_width * (y + 1), true)
    
    # for empires
    for e in range(empires.size()):
        for p in astar.get_points():
            astar.set_point_disabled(p, false)
        for u in units:
            if u.empire != e:
                astar.set_point_disabled(u.tile_x + map_width * u.tile_y, true)
        for u in units:
            if u.empire == e:
                for x in range(map_width):
                    for y in range(map_height):
                        var path = astar.get_id_path(u.tile_x + map_width * u.tile_y, x + map_width * y)
                        if path.size() <= u.speed and path.size() > 0 and u.control - path.size() > 0:
                            if map[x][y] == null:
                                map[x][y] = Dictionary()
                            var controls = map[x][y]
                            var empire_control = controls.get(e, 0)
                            controls[e] = floor(max(empire_control, u.control - path.size()))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _draw():
    for x in range(map_width):
        for y in range(map_height):
            var controls = map[x][y]
            if controls != null:
                var max_control = null
                var max_empires = Array()
                for e in controls.keys():
                    if max_control == null or max_control < controls[e]:
                        max_control = controls[e]
                        max_empires.clear()
                        max_empires.push_back(e)
                    elif max_control == controls[e]:
                        max_empires.push_back(e)
                if max_empires.size() == 0:
                    draw_rect(Rect2(x * 64, y * 64, 64, 64), Color.black)
                elif max_empires.size() == 1:
                    draw_rect(Rect2(x * 64, y * 64, 64, 64), empires[max_empires[0]].color)
                else:
                    max_empires.sort()
                    draw_rect(Rect2(x * 64, y * 64, 64, 64), empires[max_empires[(x + map_width * y) % max_empires.size()]].color)
            else:
                draw_rect(Rect2(x * 64, y * 64, 64, 64), Color.black)
    print("---")
    for u in units:
        draw_texture(preload("res://assets/unit.png"), Vector2(u.tile_x * 64, u.tile_y * 64), empires[u.empire].color)
        print(u.empire, " ", empires[u.empire].color, " ", map[u.tile_x][u.tile_y])

