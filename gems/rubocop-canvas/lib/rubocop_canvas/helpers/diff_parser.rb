module RuboCop::Canvas
  class DiffParser

    attr_reader :diff

    def initialize(input, raw = true)
      @diff = (raw ? parse_raw_diff(input) : input)
    end

    def relevant?(path, line_number)
      return false unless diff[path]
      diff[path].any?{|range| range.include?(line_number)}
    end

    private

    def parse_raw_diff(raw_diff)
      parsed = {}
      key = ""
      raw_diff.each_line.map(&:strip).each do |line|
        if file_line?(line)
          key = path_from_file_line(line)
          parsed[key] ||= []
        end
        line_range?(line) && (parsed[key] << range_from_file_line(line))
      end
      parsed
    end

    def file_line?(line)
      line =~ /^\+\+\+ b\/.*\./
    end

    def line_range?(line)
      line =~ /^@@ -\d.*\+\d.* @@/
    end

    def path_from_file_line(line)
      line.split(/\s/).last.gsub(/^b\//, "")
    end

    def range_from_file_line(line)
      line_plus_size = line.split(/\s/)[2].split(",")
      start = line_plus_size[0].gsub("+",'').to_i
      (start..(start + line_plus_size[1].to_i))
    end
  end
end
