module CanvasStatsd
  class Counter

    attr_reader :key
    attr_reader :blocked_names

    def initialize(key, blocked_names=[])
      @blocked_names = blocked_names
      @key = key
    end

    def start
      Thread.current[key] = 0
    end

    def track(name)
      Thread.current[key] += 1 if Thread.current[key] && accepted_name?(name)
    end

    def finalize_count
      final_count = count
      Thread.current[key] = 0
      final_count
    end

    def count
      Thread.current[key]
    end

    def accepted_name?(name)
      !blocked_names.include?(name)
    end

  end
end
