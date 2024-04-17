
class AnimationHandler

    attr_accessor :animations

    def initialize animations = []
        @animations = animations

        @current = nil
        @animation_start = 0
    end

    def start animation_name, repeat = false
        if @current != nil && @animations[@current].name == animation_name
            return
        end
        @current = @animations.index { |animation| animation.name == animation_name }
        @animation_start = $frame
        @repeat = repeat
    end
    

    def draw
        if @current == nil || @animations[@current] == nil
            return " "
        end

        frame_index = @repeat ? (($frame - @animation_start) % (@animations[@current].frames.length * @animations[@current].frame_length)) : ($frame - @animation_start)
        frame_index = frame_index / @animations[@current].frame_length

        if frame_index >= @animations[@current].frames.length
            if !@repeat
                @current = nil
                return " "
            end
        end

        frame = @animations[@current].draw(frame_index)

        return frame.to_s
    end
end

class Animation

    attr_reader :name, :frames, :frame_length

    def initialize name, frames, frame_length = 1
        @name = name
        @frames = frames
        @frame_length = frame_length
    end

    def draw frame
        @frames[frame].to_s
    end
end