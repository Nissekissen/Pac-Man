$frame = 0
$frame_rate = 15.0

$start_time = Time.now
$current_time = Time.now - $start_time

require 'io/console'
require './ghosts.rb'

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

    def move

        if $frame % 3 == 0
            return
        end

        case @direction
        when 0
            @x_vel = 1
            @y_vel = 0
        when 1
            @y_vel = -1
            @x_vel = 0
        when 2 
            @x_vel = -1
            @y_vel = 0
        when 3
            @y_vel = 1
            @x_vel = 0
        end

        @x += @x_vel
        @y += @y_vel
    end

    def key_press key
        case key
        when "w"
            @direction = 1
        when "s"
            @direction = 3
        when "a"
            @direction = 2
        when "d"
            @direction = 0
        end
    end

    def to_s
        @direction.to_s
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
end

class Board

    attr_accessor :board, :pacman, :ghosts

    def initialize

        @board = Array.new(36) { Array.new(28) { Cell.new 0, 0, nil } }

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

        @pacman = PacMan.new 1, 4, 0

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
                output_board[cell.y][cell.x] = cell.to_s
            end
        end

        output_board[@pacman.y][@pacman.x] = @pacman.to_s
        for ghost in @ghosts
            output_board[ghost.y][ghost.x] = ghost.to_s
            # if ghost.target_x != nil && ghost.target_y != nil
            #     output_board[ghost.target_y][ghost.target_x] = "o"
            # end
        end
        

        output_board[0][1] = "P"
        output_board[0][2] = "Q"
        output_board[0][3] = "R"
        output_board[0][4] = "S"
        output_board[0][5] = "T"
        output_board[0][6] = "U"
        output_board[0][7] = "V"
        output_board[0][8] = "W"
        output_board[0][9] = "X"
        output_board[0][10] = "Y"
        output_board[1][11] = "O"

        result = ""
        output_board.each do |row|
            row.each do |cell|
                result += cell.to_s + " "
            end
            result += "\n" 
        end

        puts result

    end
end

board = Board.new

key_thread = Thread.new do
    loop do
        c = STDIN.getch
        # Do something with the keypress
        board.pacman.key_press c
    end
end


while true
    system 'cls'
    board.draw_board

    board.pacman.move
    
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