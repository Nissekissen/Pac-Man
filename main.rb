$frame = 0
$frame_rate = 5.0

require 'rainbow/refinement'
using Rainbow

require 'io/console'
require './ghosts.rb'


class PacMan

    attr_accessor :x, :y, :direction, :score

    def initialize x, y, direction
        @x = x
        @y = y
        @direction = direction
        @score = 0

        @x_vel = 0
        @y_vel = 0
    end

    def move
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

    attr_accessor :board, :pacman, :ghost

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
        @ghost = Blinky.new 4, 4
        
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
        output_board[@ghost.y][@ghost.x] = @ghost.to_s

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
    board.ghost.move board

    sleep(1 / $frame_rate)

    $frame += 1
end