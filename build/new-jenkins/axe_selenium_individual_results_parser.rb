# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'nokogiri'
require 'csv'

STACK_TRACE_PREFIX = 'Failure/Error: raise RSpec::Expectations::ExpectationNotMetError, results '

def parse_errors(stack_trace, spec_description)
  summary = {}
  parsed_stack_trace = stack_trace.gsub(STACK_TRACE_PREFIX, '').delete("\n")
  parsed_stack_trace.scan(/Ensures.*?(?=Ensures|\z)/).each do |failure|
    selector_in_violation = failure.scan(/(Ensures.*)Violations/).join('')
    failed_assertion_locations = failure.scan(/Violations Found In\: (.*)(\.\/spec\/axe_selenium_helper|\z)/).join.split(' ')
    summary[selector_in_violation] = failed_assertion_locations.map { |stack| "#{spec_description}: #{stack}" }
  end
  summary
end

def get_child_element(xml, xpath_name)
  xml.select {|child| child.name == xpath_name}.first.text
end

def get_child_element_by_name(xml, xpath_name)
  xml.select {|child| child.name == xpath_name}
end

# Pass in parent directory of xml files
path = ARGV[0]
failures_to_specs_map = {}

Dir.glob("#{path}**/*.xml") do |filename|
  puts "working on #{filename}"
  doc = File.open(filename, 'r') { |f| Nokogiri::XML(f) }

  testsuite = get_child_element_by_name(doc.children, 'testsuite').first
  tests = get_child_element_by_name(testsuite.children, 'testcase')
  failed_tests = tests.select {|test| test.children.length > 0 && test.children.first.name != 'skipped'}
  failed_tests.each do |test|
    spec_description = test.attributes['name'].text
    error_stack_trace = test.children.first.attributes['message'].text
    error_summary = parse_errors(error_stack_trace, spec_description)
    error_summary.each do |violation, desc_and_stack|
      failures_to_specs_map[violation] = if failures_to_specs_map[violation]
          failures_to_specs_map[violation] + desc_and_stack
      else
          [desc_and_stack].flatten
      end
    end
  end
end

file_name = 'axe_results.csv'
CSV.open(file_name, 'w') do |csv|
  csv << ['Violation', 'Specs Failed']
  failures_to_specs_map.each do |violation, desc_and_stack|
    csv << [violation.gsub("   ","\n  "), desc_and_stack.join("\n")]
  end
end

puts "Results for #{failures_to_specs_map.keys.count} failure(s) written to #{file_name}"
