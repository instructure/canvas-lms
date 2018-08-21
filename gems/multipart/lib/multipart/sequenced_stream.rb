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

module Multipart
  class SequencedStream
    def initialize(streams)
      @streams = streams
    end

    def eof?
      @streams.all?(&:eof?)
    end

    def size
      @streams.map(&:size).sum
    end

    def read(size=nil, outbuf="")
      outbuf.replace("")
      if size.nil?
        # slurp up all remaining contents, even if that's just "" when eof at
        # beginning
        @streams.each { |stream| outbuf.concat(stream.read) }
        return outbuf
      elsif size.zero?
        # return "" (which is already in outbuf) even if eof at beginning
        return outbuf
      elsif eof?
        # size >= 1 but eof at beginning, return nil
        return nil
      else
        # size >= 1 and not eof at beginning, read up to size
        remaining = size
        @streams.each do |stream|
          break if remaining.zero?
          next if stream.eof?
          readbuf = ""
          if stream.read(remaining, readbuf)
            remaining -= readbuf.length
            outbuf.concat(readbuf)
          end
        end
        return outbuf
      end
    end
  end
end
