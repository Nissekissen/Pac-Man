require 'rainbow/refinement'
using Rainbow

# Beskrivning:         Klassen för spökena i spelet. Hanterar deras position, rörelse och beteende.
# Lokal variabel (@x)                 Float - x-koordinat
# Lokal variabel (@y)                 Float - y-koordinat
# Lokal variabel (@x_vel)             Integer - x-koordinatens hastighet
# Lokal variabel (@y_vel)             Integer - y-koordinatens hastighet
# Lokal variabel (@last_turn)         Array - koordinaten för senaste svängen. För att förhindra spöket att svänga två gånger på samma ruta.  
# Lokal variabel (@target_x)          Integer - x-koordinat för spökets mål
# Lokal variabel (@target_y)          Integer - y-koordinat för spökets mål
# Lokal variabel (@frame_offset)      Integer - slumpmässig offset för att spöket ska röra sig olika
# Lokal variabel (@mode)              Symbol - beteende för spöket
# Lokal variabel (@frightened_start)  Time - tiden då spöket blev rädd
# Lokal variabel (@in_house)          Boolean - om spöket är i huset
# Lokal variabel (@speed)             Float - hastigheten för spöket
# Lokal variabel (@animation_handler) AnimationHandler - hanterar spökets animation      
# Datum:               2024-05-06
# Namn:                Nils Lindblad
class Ghost

    attr_accessor :mode, :animation_handler, :in_house
    attr_reader :target_x, :target_y

    def initialize x, y
        @x = x
        @y = y

        @last_turn = [0, 0]

        @vel_x = 0
        @vel_y = -1

        @target_x = 27
        @target_y = 35

        @frame_offset = rand(4)

        @mode = :house
        @frightened_start = Time.now

        @in_house = true

        @speed = 0.2

        @animation_handler = AnimationHandler.new([
            Animation.new(:default, ["J".color(@color)], 1),
            Animation.new(:frightened, ["K".blue], 1),
            Animation.new(:frightened_flicker, ["K".blue, "K".white], 10),
            Animation.new(:eyes, ["L".white], 1)
        ])

        @animation_handler.start(:default, true)
    end

    # Beskrivning:         Metoden räknar ut alla möjliga riktningar som spöket kan röra sig i. Den används för AI:n för att räkna ut vilken riktning spöket ska ta.
    # Argument 1:          Board - brädet som spöket rör sig på
    # Return:              Array - tvådimensionell array med riktningar som spöket kan röra sig i           
    # Datum:               2024-05-06
    # Namn:                Nils Lindblad
    def get_directions board
        output = []

        for x_dir, y_dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]
            if @mode == :house
                next
            end

            if @in_house && board[@x.floor + x_dir, @y.floor + y_dir].to_s == "I"
                output.push([x_dir, y_dir])
            end
                

            if board.is_wall?(@x.floor + x_dir, @y.floor + y_dir)
                next
            end

            output.push([x_dir, y_dir])
        end

        return output
    end

    def distance x1, y1, x2, y2
        return Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)
    end

    # Beskrivning:         Metoden rör spöket på brädet. Den hanterar spökets beteende och rörelse.
    # Argument 1:          Board - brädet som spöket rör sig på
    # Return:              nil     
    # Datum:               2024-05-06
    # Namn:                Nils Lindblad
    def move board

        if @mode == :house
            return
        end

        if board[@x.floor, @y.floor].to_s == "I"
            @in_house = false
        end

        generate_target board

        if @mode != :house && @in_house
            @target_x = 13
            @target_y = 14
        end

        if @mode == :eyes
            if @x.floor == 13 && @y.floor == 14
                @mode = :chase
                @animation_handler.start :default, true
                @speed = 0.2
            end

            @target_x = 13
            @target_y = 14
        end

        if Time.now - @frightened_start > 5 && @mode == :frightened
            @animation_handler.start :frightened_flicker, true
        end

        if Time.now - @frightened_start > 10 && @mode == :frightened
            @mode = :chase
            @animation_handler.start :default, true

            @speed = 0.2
        end

        if check_collision_pacman(board) && @mode == :frightened
            @mode = :eyes
            @animation_handler.start :eyes, true

            @speed = 0.5

            $ghost_count += 1
            $score += 200 * 2 ** $ghost_count
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
            if distance(@x.floor + x_dir, @y.floor + y_dir, @target_x, @target_y) < closest_distance
                closest_distance = distance(@x.floor + x_dir, @y.floor + y_dir, @target_x, @target_y)
                closest_direction = [x_dir, y_dir]
            end
        end

        if @mode == :frightened
            closest_direction = possible_directions.sample
        end

        temp = [@vel_x, @vel_y]

        # it can only turn if it is at the last_turn spot
        if @last_turn != [@x.floor, @y.floor]
            @vel_x, @vel_y = closest_direction
        end

        if temp != [@vel_x, @vel_y]
            @last_turn = [@x.floor, @y.floor]
        end

        @x += @vel_x * @speed
        @y += @vel_y * @speed

        if @x.floor == 28
            @x = 0.0
        elsif @x.floor == -1
            @x = 27.0
        end

    end

    def frightened
        @mode = :frightened
        @animation_handler.start :frightened, true

        @speed = 0.1

        # frightened mode lasts for 10 seconds, set a timer
        @frightened_start = Time.now
    end

    def kill
        @mode = :eyes
        @animation_handler.start :eyes, true
        
        @speed = 0.5
    end

    def draw
        @animation_handler.draw
    end

    def x
        @x.floor
    end

    def x=(value)
        @x = value
    end

    def y=(value)
        @y = value
    end

    def y
        @y.floor
    end

    def real_x
        @x
    end

    def real_y
        @y
    end

    def check_collision_pacman board
        (@y - board.pacman.real_y).abs < 0.8 && (@x - board.pacman.real_x).abs < 0.8
    end
end

# Beskrivning:            Klassen för det röda spöket. Ärver från Ghost.
# Lokal variabel (@color) Symbol - färgen på spöket
# Datum:                  2024-05-06
# Namn:                   Nils Lindblad

class Blinky < Ghost

    def initialize x, y
        @color = :red
        super x, y

        @mode = :chase
        @in_house = false

    end

    # Beskrivning:         Generar målet för spöket. Om spöket är i scatter mode så sätts målet till en hårdkodad position. Annars sätts målet till pacman.
    # Argument 1:          Board - brädet som spöket rör sig på
    # Return:              nil
    # Datum:               2024-05-06
    # Namn:                Nils Lindblad
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

# Beskrivning:            Klassen för det rosa spöket. Ärver från Ghost.
# Lokal variabel (@color) Symbol - färgen på spöket
# Datum:                  2024-05-06
# Namn:                   Nils Lindblad
class Pinky < Ghost

    def initialize x, y
        @color = :magenta
        super x, y

    end

    # Beskrivning:         Generar målet för spöket. Om spöket är i scatter mode så sätts målet till en hårdkodad position. Annars sätts målet till 4 steg framför pacman. Om pacman rör sig uppåt så sätts målet 4 steg till vänster, det är från en bugg i originalet.
    # Argument 1:          Board - brädet som spöket rör sig på
    # Return:              nil
    # Datum:               2024-05-06
    # Namn:                Nils Lindblad
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


# Beskrivning:            Klassen för det blåa spöket. Ärver från Ghost.
# Lokal variabel (@color) Symbol - färgen på spöket
# Datum:                  2024-05-06
# Namn:                   Nils Lindblad
class Inky < Ghost

    def initialize x, y
        @color = :cyan
        super x, y

    end

    # Beskrivning:         Generar målet för spöket. Om spöket är i scatter mode så sätts målet till en hårdkodad position. Annars sätts målet till en position som är 2 steg framför pacman och 2 steg framför blinky.
    # Argument 1:          Board - brädet som spöket rör sig på
    # Return:              nil
    # Datum:               2024-05-06
    # Namn:                Nils Lindblad
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

# Beskrivning:            Klassen för det gula spöket. Ärver från Ghost.
# Lokal variabel (@color) Symbol - färgen på spöket
# Datum:                  2024-05-06
# Namn:                   Nils Lindblad
class Clyde < Ghost

    def initialize x, y
        @color = :yellow
        super x, y

    end


    # Beskrivning:         Generar målet för spöket. Om spöket är i scatter mode så sätts målet till en hårdkodad position. Annars sätts målet till pacman om avståndet är större än 8, annars sätts målet till en hårdkodad position.
    # Argument 1:          Board - brädet som spöket rör sig på
    # Return:              nil
    # Datum:               2024-05-06
    # Namn:                Nils Lindblad
    def generate_target board
        if @mode == :scatter
            @target_x = 0
            @target_y = 35
            return
        end

        if distance(@x.floor, @y.floor, board.pacman.x, board.pacman.y) < 8
            @target_x = 0
            @target_y = 35
        else
            @target_x = board.pacman.x
            @target_y = board.pacman.y
        end
    end
end