module DrDiff
  class DiffParser
    attr_reader :diff

    def initialize(input, raw = true)
      @diff = (raw ? parse_raw_diff(input) : input)
    end

    def relevant?(path, line_number, severe=false)
      return false unless diff[path]
      if UserConfig.only_report_errors?
        if severe
          diff[path][:change].include?(line_number)
        end
      else
        if severe
          diff[path][:context].any?{|range| range.include?(line_number)}
        else
          diff[path][:change].include?(line_number)
        end
      end
    end

    private

    def parse_raw_diff(raw_diff)
      key = "GLOBAL"
      parsed = {key => {context: [], change: []}}
      cur_line_number = 0
      raw_diff.each_line.map(&:strip).each do |line|
        if file_line?(line)
          key = path_from_file_line(line)
          parsed[key] ||= {context: [], change: []}
        end

        if line_range?(line)
          range = range_from_file_line(line)
          parsed[key][:context] << range
          cur_line_number = range.first
        end

        if code_line?(line)
          if touched?(line)
            parsed[key][:change] << cur_line_number
          end
          cur_line_number += 1 unless line_gone?(line)
        end
      end
      parsed
    end

    def line_gone?(line)
      line =~ /^\-/
    end

    def code_line?(line)
      return false if file_line?(line)
      return false if line_range?(line)
      return false if line =~ /^\-\-\- a\/.*\./
      return false if line =~/^index .*\d\d\d$/
      return false if line =~/^diff \-\-git/
      true
    end

    def touched?(line)
      line =~ /^\+/
    end

    def file_line?(line)
      line =~ /^\+\+\+ b\//
    end

    def line_range?(line)
      line =~ /^@@ -\d.*\+\d.* @@/
    end

    def path_from_file_line(line)
      line.split(/\s/).last.gsub(/^b\//, "")
    end

    def range_from_file_line(line)
      line_plus_size = line.split(/\s/)[2].split(",")
      start = line_plus_size[0].delete("+").to_i
      (start..(start + line_plus_size[1].to_i))
    end
  end
end
