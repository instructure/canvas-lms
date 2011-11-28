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

module CustomValidations

  module ClassMethods

    def validates_as_url(*fields)
      fields.each do |field|
        validates_each(field.to_sym, :allow_nil => true) do |record, attr, value|
          begin
            value = value.strip
            raise ArgumentError if value.empty?
            uri = URI.parse(value)
            unless uri.scheme
              value = "http://#{value}"
              uri = URI.parse(value)
            end
            raise ArgumentError unless uri.host && %w(http https).include?(uri.scheme.downcase)
            record.url = value
          rescue URI::InvalidURIError, ArgumentError
            record.errors.add attr, 'is not a valid URL'
          end
        end
      end
    end

  end

  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.send :extend, ClassMethods
    end
  end

end
