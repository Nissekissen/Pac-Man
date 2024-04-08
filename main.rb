require 'io/console'

class PacMan

    attr_accessor :x, :y, :direction, :score

    def initialize x, y, direction
        @x = x
        @y = y
        @direction = direction
        @score = 0
    end

    def move
        case @direction
        when "up"
            @y -= 1
        when "down"
            @y += 1
        when "left"
            @x -= 1
        when "right"
            @x += 1
        end
    end

    def key_press key
        case key
        when "w"
            @direction = "up"
        when "s"
            @direction = "down"
        when "a"
            @direction = "left"
        when "d"
            @direction = "right"
        end
    end

    def to_s
        case @direction
        when "up"
            "1"
        when "down"
            "3"
        when "left"
            "2"
        when "right"
            "0"
        end
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

    attr_accessor :board, :pacman

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

        @pacman = PacMan.new 1, 4, "right"
        
    end

    def [](x, y)
        @board[y][x]
    end

    def []=(x, y, value)
        @board[y][x] = value
    end

    def draw_board

        output_board = Array.new(36) { Array.new(28) { " " } }

        @board.each do |row|
            row.each do |cell|
                output_board[cell.y][cell.x] = cell.to_s
            end
        end

        output_board[@pacman.y][@pacman.x] = @pacman.to_s

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
    print "\e[2J\e[f"
    board.draw_board

    board.pacman.move

    sleep(0.1)
end