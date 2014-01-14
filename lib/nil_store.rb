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

if CANVAS_RAILS2
  # This is a fix for the fact that, in development environment,
  # unmarshalling ActiveRecord objects across multiple requests
  # will result in serious sadness
  class NilStore < ActiveSupport::Cache::Store

    def initialize(location='//myloc'); end

    def read(name, options = nil); nil; end

    def read_multi(*names); {}; end

    def write(name, value, options = nil); value; end

    def delete(name, options = nil); nil; end

    def delete_matched(matcher, options = nil); nil; end

  end
end
