

class WordData
    attr_accessor :word, :freq
    
    def initialize(word, freq)
        if word.instance_of? String
            @word = word
        end
        if freq.is_a? Integer
            @freq = freq
        end
    end
    
    def hash
        return @word.hash
    end
    
    def ==(other)
        if @word == other.word
            return true
        else
            return false
        end
    end
    
    def <=>(other)
        @freq <=> other.freq
    end
    
    def eql?(other)
        if @word == other.word
            return true
        else
            return false
        end
    end
    
    def to_s
        return "{\"#{@word}\" : #{@freq}}"
    end
end    
