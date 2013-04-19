#
# Copyright (C) 2011 Instructure, Inc.
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

# This is used for the GradebookImporter
require 'ostruct'

class CSVParser
  
  attr_reader :contents
  
  # Not using opts, but to keep a standard API, I accept it and ignore it.
  def initialize(contents, opts={})
    @contents = contents
  end
  
  def gradebook
    return @gradebook if @gradebook
    @gradebook = blank_gradebook
    trimmed_contents.each_with_index do |row,i|
      row.each_with_index do |cell,j|
        @gradebook[i][j].value = cell
      end
    end
    @gradebook
  end
  
  # For a generic API, run is used to return a gradebook.
  alias :run :gradebook

  private
    # Get n columns
    def blank_row(n)
      Array.new(n) {OpenStruct.new}
    end

    # Get n columns and m rows
    def blank_gradebook
      Array.new(num_rows) {blank_row(num_cols)}
    end

    # Slurps up the contents and converts them with CSV, returning an array of arrays.
    def raw_contents
      @raw_contents ||= CSV.parse( contents, :converters => :numeric )
    end

    # Deletes the notes row
    def trimmed_contents
      return @trimmed_contents if @trimmed_contents
      @trimmed_contents = raw_contents.dup
      @trimmed_contents.delete_at(1)
      @trimmed_contents.each {|row| row.delete_at(1)}
      @trimmed_contents
    end

    def num_rows; trimmed_contents.size end
    def num_cols; trimmed_contents.first.size end

end
