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
class Gergich::Biome
  # See
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions
  # for more information on the schema of the output. This reporter was chosen because all other reporters that Biome
  # has either don't output enough information (JUnit), or aren't stable (JSON).
  #
  # Example output:
  # [
  #   {
  #     "path": "ui/features/lti_registrations/manage/model/LtiRegistration.ts",
  #     "message": "File content differs from formatting output",
  #     "position": {
  #       "start_line": 1,
  #       "end_line": 1,
  #       "start_character": 2,
  #       "end_character": 2
  #     },
  #     "severity": "error"
  #   },
  #   ...
  # ]
  def run(output)
    # Parse output in GitHub Actions workflow command format:
    # ::error title=format,file=ui/features/lti_registrations/manage/model/LtiRegistration.ts,line=1,endLine=1,col=2,endColumn=2::File content differs from formatting output
    pattern = /^::error(.*)/

    output.scan(pattern).filter_map do |(data)|
      # According to GitHub, each of these is optional and the order doesn't
      # matter, so we can't just use one monster regex to match the whole thing.
      # We can safely assume that a file will always be present, but the rest *might* not be.
      file = data.match(/file=([^,]+)/)[1]
      start_line = data.match(/line=(\d+)/)[1]&.to_i
      end_line = data.match(/endLine=(\d+)/)[1]&.to_i

      start_character = data.match(/col=(\d+)/)[1]&.to_i
      end_character = data.match(/endColumn=(\d+)/)[1]&.to_i
      title = data.match(/title=([^,]+)/)[1]
      message = data.match(/::(.+)/)[1]

      missing_info = start_line.nil? || end_line.nil? || start_character.nil? || end_character.nil?

      {
        path: file,
        message: "[biome] #{title ? "#{title}: " : ""}#{message}",
        position: if missing_info
                    start_line || 1
                  else
                    {
                      start_line:,
                      end_line:,
                      start_character:,
                      end_character:
                    }
                  end,
        severity: "error"
      }
    end
  end
end
