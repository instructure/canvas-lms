# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
    def validates_as_url(*fields, allowed_schemes: %w[http https])
      validates_each(fields, allow_nil: true) do |record, attr, value|
        value, = CanvasHttp.validate_url(value, allowed_schemes:)

        record.send(:"#{attr}=", value)
      rescue CanvasHttp::Error, URI::Error, ArgumentError
        record.errors.add attr, "is not a valid URL"
      end
    end

    def validates_as_readonly(*fields)
      validates_each(fields) do |record, attr, _value|
        if !record.new_record? && record.send(:"#{attr}_changed?")
          record.errors.add attr, "cannot be changed"
        end
      end
    end

    # alloweds is a hash of old_value => [new_value]
    # on update, only those transitions will be allowed for the given field
    def validates_allowed_transitions(field, alloweds)
      validates_each(field) do |record, attr, value|
        if !record.new_record? && record.send(:"#{attr}_changed?")
          old_val = record.send(:"#{attr}_was")
          unless alloweds.any? { |old, news| old_val == old && Array(news).include?(value) }
            record.errors.add attr, "cannot be changed to that value"
          end
        end
      end
    end
  end

  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.extend ClassMethods
    end
  end
end
