# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
#
require "yaml"

SPEC_THRESHOLD = 40_000

spec_count = YAML.load_file("crystalball_map.yml")[:version].split[0].to_i
spec_files_in_map = File.read("crystalball_map.yml").split("\n").grep(/spec\.rb\[\d*\]/).map { |file| file.split("[").first.gsub(%r{^"./}, "") }.uniq
spec_files_in_code = (Dir.glob("/usr/src/app/spec/**/*spec.rb") + Dir.glob("/usr/src/app/gems/plugins/**/spec_canvas/**/*spec.rb")).uniq.map { |file| file.gsub("/usr/src/app/", "") }

# Remove filtered out specs
spec_files_in_code.reject! { |file| file.match?("(selenium/performance|instfs/selenium|contracts|force_failure)") }

delta_spec_files = spec_files_in_code - spec_files_in_map

unless delta_spec_files.empty?
  puts "*#{delta_spec_files.count} Missing Spec Files in crystalball_map.yml*"
  puts(delta_spec_files.map { |file| " - #{file}" })
end

if spec_count >= SPEC_THRESHOLD
  puts "*Map Contains #{spec_count} specs*"
else
  raise "*Map Only Contains #{spec_count} Specs, but #{SPEC_THRESHOLD} required to push map*"
end
