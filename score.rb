$score = ""
score = 0

def eatCheck(x, y, board)
    case board[x, y].to_s
    when "G"
        score += 10
        board[x, y].value = " "
    when "H"
        score += 50
        board[x, y].value = " "
    end
end
def convertScore
    for i in 0...score.length
        case score.to_s[i]
        when 0
            $score[i] = "Q"
        when 1
            $score[i] = "R"
        when 2
            $score[i] = "S"
        when 3
            $score[i] = "T"
        when 4
            $score[i] = "U"
        when 5
            $score[i] = "V"
        when 6
            $score[i] = "W"
        when 7
            $score[i] = "X"
        when 8
            $score[i] = "Y"
        when 9
            $score[i] = "Z"
        end
    end
end