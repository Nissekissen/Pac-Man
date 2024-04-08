require 'io/console'


width = 28
height = 36

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
        File.open("map.txt", "w") do |file|
            file.write "[" + map.map { |row| "[" + row.map { |cell| "\"#{cell}\"" }.join(",") + "]" }.join(",") + "]"
        end

        system 'cls'
        draw_map map
        puts "Map saved to map.txt"
        break
    end
end