# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

begin
  require "../../spec/coverage_tool"
  CoverageTool.start("canvas-quiz-statistics-gem")
rescue LoadError => e
  puts "Error: #{e} "
end

require "debug"
require "canvas_quiz_statistics"

Constants = CanvasQuizStatistics::Analyzers::Base::Constants

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = "random"
end

File.join(File.dirname(__FILE__), "canvas_quiz_statistics").tap do |cwd|
  # spec support in support/
  Dir.glob(File.join([
                       cwd, "support", "**", "*.rb"
                     ])).each { |file| require file }

  # specs for shared metrics in analyzers/shared_metrics
  Dir.glob(File.join([
                       cwd, "analyzers", "shared_metrics", "**", "*.rb"
                     ])).each { |file| require file }
end
