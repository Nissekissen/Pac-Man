$frame = 0
$frame_rate = 60.0

$start_time = Time.now
$current_time = Time.now - $start_time
$running = true

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

    attr_accessor :direction, :score, :x_vel, :y_vel, :current_key

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
            Animation.new(:death, ["4", "4", "1", "6", "9", "G", ".", ",", ","].map(&:yellow), 4)
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
        when "G"
            return false
        when " "
            return false
        when "H"
            return false
        else
            return true
        end
    end

    def draw_board

        output_board = Array.new(36) { Array.new(28) { " " } }

        
        @board.each do |row|
            row.each do |cell|
                output_board[cell.y][cell.x] = cell.draw
            end
        end
        
        output_board[@pacman.y][@pacman.x] = @pacman.draw
        for ghost in @ghosts
            output_board[ghost.y][ghost.x] = ghost.draw
            # output_board[ghost.target_y][ghost.target_x] = "T".color(:green)
        end

        convertScore
        for i in 0...$scoreString.to_s.length
            output_board[1][10 + i] = $scoreString.to_s[i]
        end
        print $cursor.move_to(70, 10) + $scoreString
        
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


$cursor.invisible {
    loop do
        board.draw_board

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
            if ghost.mode != :house
                ghost.mode = get_mode
            end
        end
        

        sleep(1 / $frame_rate)

        $frame += 1
        $current_time = Time.now - $start_time
    end

}

system "cls"