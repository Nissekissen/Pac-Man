
class Ghost
    def initialize x, y
        @x = x
        @y = y

        @vel_x = 0
        @vel_y = 1

        @target_x = 0
        @target_y = 0
    end

    def is_wall? board, x, y
        return board[y][x] != "G" && board[y][x] != " " && board[y][x] != "H"

    end

    def distance x1, y1, x2, y2
        return Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)

    def move board
        @x += @vel_x
        @y += @vel_y

        # find all possible directions
        possible_directions = []
        for x_dir, y_dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]
            if !is_wall?(board, @x + x_dir, @y + y_dir)
                possible_directions.push([x_dir, y_dir])
            end
        end

        # exclude opposite direction
        opposite_direction = [-@vel_x, -@vel_y]
        possible_directions.reject! { |dir| dir == opposite_direction }

        closest_direction = nil
        closest_distance = 999999
        for x_dir, y_dir in possible_directions
            distance = distance(@x + x_dir, @y + y_dir, @target_x, @target_y)
            if distance < closest_distance
                closest_distance = distance
                closest_direction = [x_dir, y_dir]
            end
        end

        @vel_x, @vel_y = closest_direction
    end
end