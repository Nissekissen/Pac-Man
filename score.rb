$scoreString = ""
$score = 0

def eatCheck(x, y, board)
    case board[x, y].to_s
    when "G"
        $score += 10
        board[x, y].value = " "
    when "H"
        $score += 50
        board[x, y].value = " "

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
def convertScore
    for i in 0...$score.to_s.length
        case $score.to_s[i].to_i
        when 0
            $scoreString[i] = "Q"
        when 1
            $scoreString[i] = "R"
        when 2
            $scoreString[i] = "S"
        when 3
            $scoreString[i] = "T"
        when 4
            $scoreString[i] = "U"
        when 5
            $scoreString[i] = "V"
        when 6
            $scoreString[i] = "W"
        when 7
            $scoreString[i] = "X"
        when 8
            $scoreString[i] = "Y"
        when 9
            $scoreString[i] = "Z"
        end
    end
end