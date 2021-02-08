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

# This makes it so all parameters get converted to UTF-8 before they hit your
# app.  If someone sends invalid UTF-8 to your server, raise an exception.
class ActionController::InvalidByteSequenceErrorFromParams < Encoding::InvalidByteSequenceError; end
class ActionController::Base
  def force_utf8_params
    traverse = lambda do |object, block|
      if object.kind_of?(Hash)
        object.each_value { |o| traverse.call(o, block) }
      elsif object.kind_of?(Array)
        object.each { |o| traverse.call(o, block) }
      else
        block.call(object)
      end
      object
    end
    force_encoding = lambda do |o|
      if o.respond_to?(:force_encoding)
        o.force_encoding(Encoding::UTF_8)
        raise ActionController::InvalidByteSequenceErrorFromParams unless o.valid_encoding?
      end
      if o.respond_to?(:original_filename) && o.original_filename
        o.original_filename.force_encoding(Encoding::UTF_8)
        raise ActionController::InvalidByteSequenceErrorFromParams unless o.original_filename.valid_encoding?
      end
    end
    traverse.call(params, force_encoding)
    path_str = request.path.to_s
    if path_str.respond_to?(:force_encoding)
      path_str = path_str.dup.force_encoding(Encoding::UTF_8)
      raise ActionController::InvalidByteSequenceErrorFromParams unless path_str.valid_encoding?
    end
  end
  before_action :force_utf8_params
end

module ActiveRecord::Coders
  Utf8SafeYAMLColumn = YAMLColumn
end
