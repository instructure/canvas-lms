module HandlebarsTasks
  module TemplatePrecompiler
    def precompile_template(path, source, options = {})
      require 'json'
      payload = {path: path, source: source, ember: options[:ember]}.to_json
      compiler.puts payload
      result = JSON.parse(compiler.readline)
      raise result["error"] if result["error"]
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
