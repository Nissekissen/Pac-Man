
class Ghost

    attr_accessor :x, :y, :mode
    attr_reader :target_x, :target_y

    def initialize x, y
        @x = x
        @y = y

        @vel_x = 0
        @vel_y = -1

        @target_x = 27
        @target_y = 35

        @frame_offset = rand(4)

        @mode = :house

        @in_house = true
    end

    def get_directions board
        output = []

        for x_dir, y_dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]
            if @mode == :house
                next
            end

            if @in_house && board[@x + x_dir, @y + y_dir].to_s == "I"
                output.push([x_dir, y_dir])
            end
                

            if board.is_wall?(@x + x_dir, @y + y_dir)
                next
            end

            


            output.push([x_dir, y_dir])
        end

        return output
    end

    def distance x1, y1, x2, y2
        return Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)
    end

    def move board

        if ($frame + @frame_offset) % 3 == 0
            return
        end

        if @mode == :frightened && ($frame + @frame_offset) % 3 == 1
            return
        end 

        if @mode == :house
            return
        end

        if board[@x, @y].to_s == "I"
            @in_house = false
        end

        generate_target board

        if @mode != :house && @in_house
            @target_x = 13
            @target_y = 14
        end

        # find all possible directions
        possible_directions = get_directions(board)

        opposite_direction = [-@vel_x, -@vel_y]
        if possible_directions.include?(opposite_direction) && possible_directions.length > 1
            possible_directions.delete(opposite_direction)
        end

        closest_distance = 1000000
        closest_direction = nil
        for x_dir, y_dir in possible_directions
            if distance(@x + x_dir, @y + y_dir, @target_x, @target_y) < closest_distance
                closest_distance = distance(@x + x_dir, @y + y_dir, @target_x, @target_y)
                closest_direction = [x_dir, y_dir]
            end
        end

        if @mode == :frightened
            closest_direction = possible_directions.sample
        end


        @vel_x, @vel_y = closest_direction

        @x += @vel_x
        @y += @vel_y
    end

    def to_s
        "J"
    end
end

class Blinky < Ghost

    def initialize x, y
        super x, y

        @mode = :chase
        @in_house = false
    end

    def generate_target board

        if @mode == :scatter
            @target_x = 25
            @target_y = 0
            return
        end

        @target_x = board.pacman.x
        @target_y = board.pacman.y
    end
end

class Pinky < Ghost

    def generate_target board
        if @mode == :scatter
            @target_x = 2
            @target_y = 0
            return
        end

        @target_x = board.pacman.x + 4 * board.pacman.x_vel
        @target_y = board.pacman.y + 4 * board.pacman.y_vel

        # added the bug from the original game
        if board.pacman.y_vel == -1
            @target_x -= 4
        end
    end
end

class Inky < Ghost

    def generate_target board
        if @mode == :scatter
            @target_x = 27
            @target_y = 35
            return
        end

        blinky = board.ghosts[0]

        @target_x = blinky.x + ((board.pacman.x + 2 * board.pacman.x_vel) - blinky.x) * 2
        @target_y = blinky.y + ((board.pacman.y + 2 * board.pacman.y_vel) - blinky.y) * 2

        if @target_x < 0
            @target_x = 0
        end

        if @target_y < 0
            @target_y = 0
        end
    end
end

class Clyde < Ghost

    def generate_target board
        if @mode == :scatter
            @target_x = 0
            @target_y = 35
            return
        end

        if distance(@x, @y, board.pacman.x, board.pacman.y) < 8
            @target_x = 0
            @target_y = 35
        else
            @target_x = board.pacman.x
            @target_y = board.pacman.y
        end
    end
end