$frame = 0
$frame_rate = 15.0

$start_time = Time.now
$current_time = Time.now - $start_time

require 'rainbow/refinement'
using Rainbow

require 'tty-cursor'
$cursor = TTY::Cursor
$cursor.hide

require 'io/console'
require './ghosts.rb'
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

    attr_accessor :x, :y, :direction, :score, :x_vel, :y_vel

    def initialize x, y, direction
        @x = x
        @y = y
        @direction = direction
        @score = 0

        @x_vel = 0
        @y_vel = 0
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
        return !board.is_wall?(@x + x, @y + y)
    end

    def move board

        if $frame % 3 == 0
            return
        end

        @x_vel, @y_vel = check_dir(@direction)

        if !board.is_wall? @x + @x_vel, @y + @y_vel
            @x += @x_vel
            @y += @y_vel
        end

        if @x == 28
            @x = 0
        elsif @x == -1
            @x = 27
        end

        eatCheck(@x, @y, board)
    end

    def key_press key, board
        case key
        when "w"
            if check_rot(1, board) == true
                @direction = 1
            end
        when "s"
            if check_rot(3, board) == true
                @direction = 3
            end
        when "a"
            if check_rot(2, board)
                @direction = 2
            end
        when "d"
            if check_rot(0, board)
                @direction = 0
            end
        end
    end

    def to_s
        @direction.to_s
    end

    def draw
        if $frame % 2 == 0
            return @direction.to_s.yellow
        end
        return "4".yellow
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
        end

        for i in 0...$score.to_s.length
            output_board[1][10 + i] = $score.to_s[i]
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



system "cls"

key_thread = Thread.new do
    loop do
        c = STDIN.getch
        # Do something with the keypress
        board.pacman.key_press c, board
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