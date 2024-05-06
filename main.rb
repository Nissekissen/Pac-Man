$frame = 0
$frame_rate = 60.0

$start_time = Time.now
$current_time = Time.now - $start_time
$running = true

$deaths = 0

require 'rainbow/refinement'
using Rainbow

require 'tty-cursor'
$cursor = TTY::Cursor
$cursor.hide

require 'io/console'
require './ghosts.rb'
require './animation.rb'
require './score.rb'

# first is scatter, second is chase, third is scatter, fourth is chase, etc.
$mode_timer = [7, 20, 7, 20, 7, 20, 5, 20]

def save_highscore score
    # check if highscore.txt exists
    if !File.file?("highscore.txt")
        # if it doesn't, create it
        File.open("highscore.txt", "w") do |file|
            file.puts "0"
        end
    end

    # read the highscore from the file
    highscore = File.read("highscore.txt").to_i

    # if the current score is higher than the highscore, update the highscore
    if score > highscore
        File.open("highscore.txt", "w") do |file|
            file.puts score
        end
    end

    return [highscore, score].max
end

def get_mode
    total = 0
    $mode_timer.each_with_index do |time, i|
        total += time
        if $current_time < total
            return i % 2 == 0 ? :scatter : :chase
        end
    end

    return :chase
end


def find_differences arr1, arr2

    differences = []

    arr1.each_with_index do |row, y|
        row.each_with_index do |cell, x|
            if cell.to_s != arr2[y][x].to_s
                differences.push([x, y])
            end
        end
    end

    return differences

end

class PacMan

    attr_accessor :direction, :score, :x_vel, :y_vel, :current_key, :animation_handler

    def initialize x, y, direction
        @x = x
        @y = y
        @direction = direction
        @score = 0

        @current_key = [nil, nil] # first is the key, second is the time pressed
        @reset_time = 1
        @last_key = nil

        @x_vel = 0
        @y_vel = 0

        @speed = 0.2
        
        @animation_handler = AnimationHandler.new([
            Animation.new(:right, ["4", "0", "5", "0"].map(&:yellow), 2),
            Animation.new(:up,    ["4", "1", "6", "1"].map(&:yellow), 2),
            Animation.new(:left,  ["4", "2", "7", "2"].map(&:yellow), 2),
            Animation.new(:down,  ["4", "3", "8", "3"].map(&:yellow), 2),
            Animation.new(:death, ["4", "4", "1", "6", "9", "G", ".", ",", ","].map(&:yellow), 5)
        ])

        @animation_handler.start(:right, true)
    end
    
    def check_dir(dir)
        case dir
        when 0
            return [1, 0]
        when 1
            return [0, -1]
        when 2 
            return [-1, 0]
        when 3
            return [0, 1]
        end
    end

    def check_rot(dir, board)
        x, y = check_dir(dir)
        return !board.is_wall?(@x.floor + x, @y.floor + y)
    end

    def move board

        if @current_key[0] != nil
            key_press @current_key[0], board
            @last_key = @current_key[0]
        end

        if @current_key[1] != nil && Time.now - @current_key[1] > @reset_time
            @current_key = [nil, nil]
        end

        @x_vel, @y_vel = check_dir(@direction)

        if !board.is_wall? @x.floor + @x_vel, @y.floor + @y_vel
            @x += @x_vel * @speed
            @y += @y_vel * @speed
        end
      
        if @x.floor == 28
            @x = 0.0
        elsif @x.floor == -1
            @x = 27.0
        end

        eatCheck(@x, @y, board)
    end

    def key_press key, board
        case key
        when "w"
            if check_rot(1, board)
                @direction = 1
                @animation_handler.start(:up, true)
            end
        when "s"
            if check_rot(3, board)
                @direction = 3
                @animation_handler.start(:down, true)
            end
        when "a"
            if check_rot(2, board)
                @direction = 2
                @animation_handler.start(:left, true)

            end
        when "d"
            if check_rot(0, board)
                @direction = 0
                @animation_handler.start(:right, true)
            end
        when "g"
            # kill ghosts
            for ghost in board.ghosts
                if !([:chase, :scatter, :frightened].include?(ghost.mode))
                    next
                end

                ghost.kill
            end
        when "q"
            $running = false
        when "r"
            @animation_handler.start(:death, false)
        end
        
    end

    def to_s
        @direction.to_s
    end

    def draw
        @animation_handler.draw
    end

    def x
        @x.floor
    end

    def x= x
        @x = x
    end

    def y
        @y.floor
    end

    def y= y
        @y = y
    end

    def real_x
        @x
    end

    def real_y
        @y
    end
end

class Cell

    attr_accessor :x, :y, :value
    def initialize x, y, value
        @x = x
        @y = y
        @value = value
    end

    def to_s
        @value
    end

    def draw
        color = :white
        case @value
        when "A", "B", "C", "D", "E", "F"
            color = :blue
        when "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
            color = :yellow
        else
            color = :white
        end
        @value.color(color)
    end
end

class Board

    attr_accessor :board, :pacman, :ghosts

    def initialize

        @board = Array.new(36) { Array.new(29) { Cell.new 0, 0, nil } }
        @last_board = nil

        File.open("map.txt", "r") do |file|
            # read the file line by line and store the values in the board
            file.each_with_index do |line, y|
                line.chomp.split(",").each_with_index do |value, x|
                    @board[y][x].x = x
                    @board[y][x].y = y
                    @board[y][x].value = value
                end
            end
        end

        @pacman = PacMan.new 14,26, 0

        @ghosts = [Blinky.new(13, 14), Pinky.new(13, 16), Inky.new(14, 16), Clyde.new(12, 16)]
        
    end

    def [](x, y)
        @board[y][x]
    end

    def []=(x, y, value)
        @board[y][x] = value
    end

    def is_wall? x, y
        case @board[y][x].to_s
        when "G", "H", " "
            return false
        else
            return true
        end
    end

    def draw_board dead

        output_board = Array.new(36) { Array.new(28) { " " } }

        
        @board.each do |row|
            row.each do |cell|
                output_board[cell.y][cell.x] = cell.draw
            end
        end
        
        output_board[@pacman.y][@pacman.x] = @pacman.draw
        if dead == false
            for ghost in @ghosts

                output_board[ghost.y][ghost.x] = ghost.draw
                # output_board[ghost.target_y][ghost.target_x] = "T".color(:green)
            end
        end
        
        if dead
            str = "game  over"
            for i in 0...str.length
                output_board[20][9 + i] = str[i].red
            end
        end

        str = "Rup   high score"
        for i in 0...str.length
            output_board[0][3 + i] = str[i].white
        end

        
        str = convertScore $score
        str.to_s.reverse.each_char.with_index do |char, i|
            output_board[1][6 - i] = char
        end

        str = convertScore $highscore
        str.to_s.reverse.each_char.with_index do |char, i|
            output_board[1][16 - i] = char
        end
        
        for i in 0...(2 - $deaths)
            output_board[35][1 + i] = "0".yellow
        end
        
        if @last_board != nil
            differences = find_differences @last_board, output_board
            for x, y in differences
                # move the cursor to the correct position
                print $cursor.move_to(x * 2 + 1, y)
                # print the new value
                print output_board[y][x]
            end

            @last_board = output_board.clone
            return
        end

        output_board.each_with_index do |row, y|
            row.each_with_index do |cell, x|
                print $cursor.move_to(x * 2 + 1, y)
                print cell
            end
        end

        @last_board = output_board.clone

    end
end

board = Board.new

def check_dead board

    for ghost in board.ghosts
        if ghost.check_collision_pacman(board) && [:chase, :scatter].include?(ghost.mode)
            return true
        end
    end
    return false
end

system "cls"

key_thread = Thread.new do
    loop do
        c = STDIN.getch
        press_time = Time.now
        # Do something with the keypress

        board.pacman.current_key = [c, press_time]

        # board.pacman.key_press c, board
    end
end

# to create the highscore file if it doesn't exist
$highscore = save_highscore 0

def reset_board board
    $start_time = Time.now
    $current_time = Time.now - $start_time
    board.pacman.x = 14
    board.pacman.y = 26
    board.ghosts[0].x = 13
    board.ghosts[0].y = 14
    board.ghosts[0].mode = :scatter
    board.ghosts[1].x = 13
    board.ghosts[1].y = 16
    board.ghosts[1].mode = :house
    board.ghosts[1].in_house = true
    board.ghosts[2].x = 12
    board.ghosts[2].y = 16
    board.ghosts[2].mode = :house
    board.ghosts[2].in_house = true
    board.ghosts[3].x = 14
    board.ghosts[3].y = 16
    board.ghosts[3].mode = :house
    board.ghosts[3].in_house = true

end

$cursor.invisible {
    loop do
        if check_dead board
            $deaths += 1
            if $deaths == 3
                break
            end
            reset_board board

        end

        board.draw_board false

        board.pacman.move board
        
        if $current_time.to_i > 3 && board.ghosts[1].mode == :house
            board.ghosts[1].mode = get_mode
        end

        if $current_time.to_i > 5 && board.ghosts[2].mode == :house
            board.ghosts[2].mode = get_mode
        end

        if $current_time.to_i > 7 && board.ghosts[3].mode == :house
            board.ghosts[3].mode = get_mode
        end

        if !$running
            break
        end

        board.ghosts.each_with_index do |ghost, i|
            ghost.move board
            if ghost.mode != :house && ghost.mode != :frightened && ghost.mode != :eyes
                ghost.mode = get_mode
            end
        end
        

        sleep(1 / $frame_rate)

        $frame += 1
        $current_time = Time.now - $start_time
    end
    board.draw_board true
    board.pacman.animation_handler.start :death, false
    for i in 0...72
        board.draw_board true
        sleep(1 / $frame_rate)
        $frame += 1
    end

    save_highscore $score
    STDIN.getch

}

system "cls"