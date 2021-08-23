# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

if $0 == "irb"
  class TeeLogger < Struct.new(:loggers)
    def method_missing(method, *args, &block)
      loggers.each do |logger|
        logger.send(method, *args, &block)
      end
    end
  end

  ActiveRecord::Base.logger = TeeLogger.new([ActiveRecord::Base.logger, Logger.new($stderr)])
end
