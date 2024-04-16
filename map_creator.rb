require 'io/console'


width = ARGV[0].to_i
height = ARGV[1].to_i

output_format = ARGV[2]

file_name = ARGV[3] || "map.txt"

if width == 0 || height == 0
    puts "Invalid arguments"
    exit
end


map = Array.new(height) { Array.new(width, 0) }

def draw_map map
    result = ""
    map.each do |row|
        row.each do |cell|
            result += cell.to_s + " "
        end
        result += "\n" 
    end

    puts result
end

x = 0
y = 0

while true
    system "cls"
    draw_map map
    input = STDIN.getch

    if input == "\u0008"
        x -= 1
        map[y][x] = "0"
        next
    end

    map[y][x] = input
    
    if input == "q"
        break
    end
    
    # remove last input
    
    
    x += 1

    if x >= width
        x = 0
        y += 1
    end

    if y >= height
        # Save map to file
        File.open(file_name, "w") do |file|
            if output_format == "json"
                # for json
                file.write "[" + map.map { |row| "[" + row.map { |cell| "\"#{cell}\"" }.join(",") + "]" }.join(",") + "]"
            else
                # for lines and commas
                file.write map.map { |row| row.join(",") }.join(", \n") + ", "
            end
        end

        system 'cls'
        draw_map map
        puts "Map saved to #{file_name}"
        break
    end
end