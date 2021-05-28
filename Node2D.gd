extends Node2D

const TILE_SIZE = 64
const map_width = 16
const map_height = 16
const map = Array()

class Empire:
    var color: Color

class Unit:
    var min_control: int
    var r_control: int
    var speed: int
    var empire: int
    var tile: Vector2
    var next_tile: Vector2

var selected_unit = null

const empires = Array()
const allies = Array()
const units = Array()

var astar = AStar2D.new()

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
    u0.min_control = 1
    u0.r_control = 1
    u0.speed = 10
    u0.tile = Vector2(1, 1)
    u0.next_tile = u0.tile
    units.push_back(u0)
    
    var u1 = Unit.new()
    u1.empire = 1
    u1.min_control = 1
    u1.r_control = 1
    u1.speed = 10
    u1.tile = Vector2(1, 3)
    u1.next_tile = u1.tile
    units.push_back(u1)
    
    var u11 = Unit.new()
    u11.empire = 1
    u11.min_control = 1
    u11.r_control = 1
    u11.speed = 10
    u11.tile = Vector2(1, 5)
    u11.next_tile = u11.tile
    units.push_back(u11)
    
    var u2 = Unit.new()
    u2.empire = 2
    u2.min_control = 1
    u2.r_control = 1
    u2.speed = 10
    u2.tile = Vector2(1, 14)
    u2.next_tile = u2.tile
    units.push_back(u2)
    
    var u3 = Unit.new()
    u3.empire = 3
    u3.min_control = 1
    u3.r_control = 1
    u3.speed = 10
    u3.tile = Vector2(14, 1)
    u3.next_tile = u3.tile
    units.push_back(u3)
    
    $Button.margin_left = map_width * TILE_SIZE
    
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
    
    calc_zones()
    
func calc_zones():
    # for empires
    for e in range(empires.size()):
        for p in astar.get_points():
            astar.set_point_disabled(p, false)
        for u in units:
            if u.empire != e:
                astar.set_point_disabled(u.tile.x + map_width * u.tile.y, true)
        for u in units:
            if u.empire == e:
                for x in range(map_width):
                    for y in range(map_height):
                        var path = astar.get_id_path(u.tile.x + map_width * u.tile.y, x + map_width * y)
                        if path.size() <= u.speed and path.size() > 0:
                            if map[x][y] == null:
                                map[x][y] = Dictionary()
                            var controls = map[x][y]
                            var empire_control = controls.get(e, 0)
                            controls[e] = floor(max(empire_control, u.min_control + u.r_control * (u.speed - path.size())))

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
                    draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), Color.black)
                elif max_empires.size() == 1:
                    draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), empires[max_empires[0]].color)
                else:
                    max_empires.sort()
                    var e = max_empires[(x + map_width * y) % max_empires.size()]
                    draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), empires[e].color)
            else:
                draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), Color.black)
    for u in units:
        if selected_unit == u:
            draw_circle(Vector2(u.tile.x * TILE_SIZE + TILE_SIZE / 2, u.tile.y * TILE_SIZE + TILE_SIZE / 2), TILE_SIZE / 2, Color.gray)
        draw_texture(preload("res://assets/unit.png"), Vector2(u.tile.x * TILE_SIZE, u.tile.y * TILE_SIZE), empires[u.empire].color)

func _input(event: InputEvent):
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
        var tiles = event.position / TILE_SIZE
        tiles = Vector2(floor(tiles.x), floor(tiles.y))
        if tiles.x >= 0 and tiles.x < map_width and tiles.y >= 0 and tiles.y < map_height:
            var found = false
            for u in units:
                if u.tile.x == tiles.x and u.tile.y == tiles.y:
                    found = true
                    if selected_unit != u:
                        selected_unit = u
                        update()
            if not found:
                selected_unit = null
                update()
        else:
            if selected_unit != null:
                selected_unit = null
                update()
    if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and selected_unit != null:
        pass


func _on_Button_pressed():
    print("pressed")
