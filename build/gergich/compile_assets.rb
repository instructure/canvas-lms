# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
