class Fixnum
    include KeyCode

    def fit( min, max )
        return self if max < min
        return min if self < min
        return max if self > max
        return self
    end
end

