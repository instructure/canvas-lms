module HandlebarsTasks
  class CompilationError < ::StandardError
    attr_reader :path, :line, :message
    def initialize(path, error)
      @path = path
      @message, @line = normalize_error(error)
    end

    # these come in many flavors :'(
    def normalize_error(error)
      line = 1
      patterns = [
        /\AParse error( on line (\d+)):\n/,
        /\A[^\n]+?( - (\d+):\d+\z)/,
        /\A[^\n]+?( on line (\d+)):[^\n]+\z/
      ]
      if patterns.any? { |pattern| error =~ pattern }
        match = Regexp.last_match
        line = match[2].to_i
        error.sub!(match[1], "")
      end
      [error, line]
    end
  end

  module TemplatePrecompiler
    def precompile_template(path, source, options = {})
      require 'json'
      payload = {path: path, source: source, ember: options[:ember]}.to_json
      compiler.puts payload
      result = JSON.parse(compiler.readline)
      raise CompilationError.new(path, result["error"]) if result["error"]
      result
    end

    # Returns the HBS preprocessor/compiler
    def compiler
      Thread.current[:hbs_compiler] ||= begin
        gempath = File.dirname(__FILE__) + "/../../.."
        IO.popen("#{gempath}/canvas_i18nliner/bin/prepare_hbs", "r+")
      end
    end
  end
end
