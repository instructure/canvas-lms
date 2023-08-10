# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "securerandom"

module LegacyMultipart
  module Post
    class << self
      def header(boundary)
        { "Content-type" => "multipart/form-data; boundary=#{boundary}" }
      end

      def prepare_query_stream(params, field_priority = [])
        params.delete(:basic_auth)

        parts = []
        completed_fields = {}
        field_priority.each do |k|
          next if completed_fields.key?(k)
          next unless params.key?(k)

          parts << Param.from(k, params[k])
          completed_fields[k] = true
        end

        params.each do |k, v|
          next if completed_fields.key?(k)

          parts << Param.from(k, v)
        end

        parts << TERMINATOR

        boundary = ::SecureRandom.hex(32)
        streams = parts.map { |part| part.to_multipart_stream(boundary) }
        [SequencedStream.new(streams), header(boundary)]
      end

      def prepare_query(params, field_priority = [])
        stream, header = prepare_query_stream(params, field_priority)
        [stream.read, header]
      end
    end
  end
end
