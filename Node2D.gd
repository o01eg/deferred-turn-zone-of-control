extends Node2D

const TILE_SIZE = 64

const DIAG_ID:int= 100000
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

class TileInfo:
    var controls: Dictionary
    var control_empire

var selected_unit = null
var selected_movements = PoolVector2Array()

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
    
    astar.reserve_space(map_width * map_height * 2)
    for x in range(map_width):
        for y in range(map_height):
            astar.add_point(x + map_width * y, Vector2(x, y))
            if x < map_width - 1 and y < map_height: 
                astar.add_point(DIAG_ID + x + map_width * y, Vector2(x + 0.5, y + 0.5))
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
            if x < map_width - 1 and y < map_height - 1:
                astar.connect_points(x + map_width * y, DIAG_ID + x + map_width * y, true)
            if x > 0 and y < map_height - 1:
                astar.connect_points(x + map_width * y, DIAG_ID + (x - 1) + map_width * y, true)
            if x < map_width - 1 and y > 0:
                astar.connect_points(x + map_width * y, DIAG_ID + x + map_width * (y - 1), true)
            if x > 0 and y > 0:
                astar.connect_points(x + map_width * y, DIAG_ID + (x - 1) + map_width * (y - 1), true)
    
    calc_zones()
    
func calc_zones():
    for x in range(map_width):
        for y in range(map_height):
            map[x][y] = null
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
                                var control = TileInfo.new()
                                control.controls = Dictionary()
                                control.control_empire = null
                                map[x][y] = control
                            var control = map[x][y]
                            var empire_control = control.controls.get(e, 0)
                            control.controls[e] = floor(max(empire_control, u.min_control + u.r_control * (u.speed - path.size())))
    for x in range(map_width):
        for y in range(map_height):
            var control = map[x][y]
            if control != null:
                var max_control = null
                var max_empires = Array()
                for e in control.controls.keys():
                    if max_control == null or max_control < control.controls[e]:
                        max_control = control.controls[e]
                        max_empires.clear()
                        max_empires.push_back(e)
                    elif max_control == control.controls[e]:
                        max_empires.push_back(e)
                if max_empires.size() == 0:
                    map[x][y] = null
                elif max_empires.size() == 1:
                    control.control_empire = max_empires[0]
                else:
                    max_empires.sort()
                    control.control_empire = max_empires[(x + 37 * y) % max_empires.size()]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):

func _draw():
    for x in range(map_width):
        for y in range(map_height):
            var control = map[x][y]
            if control != null:
                if control.control_empire != null:
                    draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), empires[control.control_empire].color)
                    if selected_unit != null and control.control_empire == selected_unit.empire:
                        var movable = false
                        for m in selected_movements:
                            if m.x == x && m.y == y:
                                movable = true
                        if not movable:
                            draw_line(Vector2(x * TILE_SIZE, y * TILE_SIZE), Vector2(x * TILE_SIZE + TILE_SIZE - 1, y * TILE_SIZE + TILE_SIZE - 1), Color.black)
                            draw_line(Vector2(x * TILE_SIZE + TILE_SIZE - 1, y * TILE_SIZE), Vector2(x * TILE_SIZE, y * TILE_SIZE + TILE_SIZE - 1), Color.black)
                else:
                    draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), Color.black)
            else:
                draw_rect(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE), Color.black)
    for u in units:
        if selected_unit == u:
            draw_circle(Vector2(u.tile.x * TILE_SIZE + TILE_SIZE / 2, u.tile.y * TILE_SIZE + TILE_SIZE / 2), TILE_SIZE / 2, Color.gray)
        draw_texture(preload("res://assets/unit.png"), Vector2(u.tile.x * TILE_SIZE, u.tile.y * TILE_SIZE), empires[u.empire].color)
        if u.tile.x != u.next_tile.x or u.tile.y != u.next_tile.y:
            draw_line(Vector2(u.tile.x * TILE_SIZE + TILE_SIZE / 2, u.tile.y * TILE_SIZE + TILE_SIZE / 2), Vector2(u.next_tile.x * TILE_SIZE + TILE_SIZE / 2, u.next_tile.y * TILE_SIZE + TILE_SIZE / 2), Color.black)

func _input(event: InputEvent):
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
        var tiles = event.position / TILE_SIZE
        tiles = Vector2(floor(tiles.x), floor(tiles.y))
        if tiles.x >= 0 and tiles.x < map_width and tiles.y >= 0 and tiles.y < map_height:
            var movement = selected_unit != null
            if selected_unit == null:
                var found = false
                for u in units:
                    if u.tile.x == tiles.x and u.tile.y == tiles.y:
                        found = true
                        if selected_unit != u:
                            selected_unit = u
                            update()
                if not found:
                    selected_unit = null
                    for p in astar.get_points():
                        astar.set_point_disabled(p, false)
                    update()
            if selected_unit != null:
                selected_movements = PoolVector2Array()
                for p in astar.get_points():
                    astar.set_point_disabled(p, false)
                for x in range(map_width):
                    for y in range(map_height):
                        var control = map[x][y]
                        if control == null or control.control_empire == null or control.control_empire != selected_unit.empire:
                            astar.set_point_disabled(x + map_width * y, true)
                for u2 in units:
                    if selected_unit != u2:
                        astar.set_point_disabled(u2.next_tile.x + map_width * u2.next_tile.y, true)
                for x in range(map_width):
                    for y in range(map_height):
                        var path = astar.get_id_path(selected_unit.tile.x + map_width * selected_unit.tile.y, x + map_width * y)
                        if path != null and path.size() > 0 and path.size() <= selected_unit.speed:
                            selected_movements.append(Vector2(x, y))
            if movement:
                var path = astar.get_id_path(selected_unit.tile.x + map_width * selected_unit.tile.y, tiles.x + map_width * tiles.y)
                print(path)
                if path != null and path.size() > 0 and path.size() <= selected_unit.speed:
                    selected_unit.next_tile = tiles
                    for p in astar.get_points():
                        astar.set_point_disabled(p, false)
                    update()
    if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and selected_unit != null:
        selected_unit = null
        for p in astar.get_points():
            astar.set_point_disabled(p, false)
        update()


func _on_Button_pressed():
    for u in units:
        u.tile = u.next_tile
    selected_unit = null
    for p in astar.get_points():
        astar.set_point_disabled(p, false)
    calc_zones()
    update()
