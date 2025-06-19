# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Manages temporary files created during test execution to ensure they aren't
# garbage collected prematurely and are cleaned up properly when tests complete.
class TestFileManager
  attr_reader :temp_files

  def initialize
    @temp_files = []
    # Register finalizer to clean up files when Ruby process exits
    ObjectSpace.define_finalizer(self, self.class.finalize(@temp_files))
  end

  def self.finalize(temp_files)
    proc do
      temp_files.each do |temp_file|
        temp_file.unlink if temp_file.respond_to?(:unlink) && File.exist?(temp_file.path)
      rescue => e
        puts "Error cleaning up temp file: #{e.message}" if defined?(puts)
      end
    end
  end

  def add_file(temp_file)
    @temp_files << temp_file
    temp_file
  end

  def cleanup
    @temp_files.each do |temp_file|
      temp_file.unlink if temp_file.respond_to?(:unlink) && File.exist?(temp_file.path)
    rescue => e
      puts "Error cleaning up temp file: #{e.message}" if defined?(puts)
    end
    @temp_files = []
  end

  # Singleton instance accessor
  # Use the singleton instance to manage test files across the entire test suite
  class << self
    def instance
      @instance ||= new
    end
  end
end
