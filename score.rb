$scoreString = ""
$score = 0
$ghost_count = 0
$highscore = 0

def eatCheck(x, y, board)
    case board[x, y].to_s
    when "G"
        $score += 10
        board[x, y].value = " "
        board.eat
    when "H"
        $score += 50
        board[x, y].value = " "
        board.eat
        $ghost_count = 0

        # make ghosts frightened
        for ghost in board.ghosts
            if !([:chase, :scatter, :frightened].include?(ghost.mode))
                next
            end
            ghost.frightened
        end
    else

    end
end
def convertScore score
    str = ""
    for i in 0...score.to_s.length
        case score.to_s[i].to_i
        when 0
            str[i] = "Q"
        when 1
            str[i] = "R"
        when 2
            str[i] = "S"
        when 3
            str[i] = "T"
        when 4
            str[i] = "U"
        when 5
            str[i] = "V"
        when 6
            str[i] = "W"
        when 7
            str[i] = "X"
        when 8
            str[i] = "Y"
        when 9
            str[i] = "Z"
        end
    end

    return str
end