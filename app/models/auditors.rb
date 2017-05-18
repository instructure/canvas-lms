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

module Auditors
  def self.stream(&block)
    ::EventStream::Stream.new(&block).tap do |stream|
      stream.raise_on_error = Rails.env.test?

      stream.on_insert do |record|
        Canvas::EventStreamLogger.info('AUDITOR', identifier, 'insert', record.to_json)
      end

      stream.on_error do |operation, record, exception|
        next unless Canvas::Cassandra::DatabaseBuilder.configured?(:auditors)
        Canvas::EventStreamLogger.error('AUDITOR', identifier, operation, record.to_json, exception.message.to_s)
      end
    end
  end

  def self.logger
    Rails.logger
  end
end
