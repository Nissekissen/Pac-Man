
class Ghost

    attr_accessor :x, :y

    def initialize x, y
        @x = x
        @y = y

        @vel_x = 0
        @vel_y = 1

        @target_x = 27
        @target_y = 35
    end

    def get_directions board
        output = []

        for x_dir, y_dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]
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

        # find all possible directions
        possible_directions = get_directions(board)

        opposite_direction = [-@vel_x, -@vel_y]
        if possible_directions.include?(opposite_direction)
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




        @vel_x, @vel_y = closest_direction

        @x += @vel_x
        @y += @vel_y
    end

    def to_s
        "J"
    end
end