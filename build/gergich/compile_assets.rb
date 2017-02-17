# gergich capture custom:./gergich/compile_assets:Gergich::CompileAssets \
#   "bundle exec rake RAILS_ENV=test canvas:compile_assets[$GENERATE_DOCS,$CHECK_SYNTAX,$COMPILE_STYLEGUIDE,$BUILD_JS]"
class Gergich::CompileAssets
  def run(output)
    # HBS
    pattern = %r|                     # Example:
      ^HBS\sPRECOMPILATION\sFAILED\n  #   HBS PRECOMPILATION FAILED
      ([^:\n]+):(\d+):\s([^\n]+\n     #   app/views/jst/googleDocsTreeView.handlebars:3 Parse error:
        (\s\s[^\n]+\n)*               #     ...le="menuitem">  {{t}  {{name}}  <ul>
                                      #     ----------------------^
                                      #     Expecting 'CLOSE', 'CLOSE_UNESCAPED', 'STRING', ...
      )
    |mx

    result = output.scan(pattern).map {|file, line, error|
      error.sub!(/\n/, "\n\n") # separate first line from the rest, which will be indented (monospace)
      { path: file, message: error, position: line.to_i, severity: "error" }
    }

    # COFFEE
    cwd = Dir.pwd
    puts cwd

    pattern = %r|                                       # Example:
      ^#{cwd}/([^\n]+?):(\d+):\d+:\serror:\s([^\n]+)\n  #   /absolute/path/to/file.coffee:7:1: error: unexpected INDENT
      ([^\n]+)\n                                        #        falseList = []
      ([^\n]+)\n                                        #   ^^^^^
    |mx

    result.concat output.scan(pattern).map {|file, line, error, context1, context2|
      error = "#{error}\n\n #{context1}\n #{context2}"
      { path: file, message: error, position: line.to_i, severity: "error" }
    }
  end
end
