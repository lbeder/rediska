module Rediska
  class ZSet < Hash
    def []=(key, val)
      super(key, floatify(val))
    end

    def increment(key, val)
      self[key] += floatify(val)
    end

    def select_by_score(min, max)
      min = floatify(min)
      max = floatify(max)
      reject {|_,v| v < min || v > max }
    end

    private
    def floatify(str)
      if inf = str.to_s.match(/^([+-])?inf/i)
        (inf[1] == '-' ? -1.0 : 1.0) / 0.0
      else
        Float(str)
      end
    end
  end
end
