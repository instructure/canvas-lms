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

class ErrorLogging
  include ActiveSupport::Callbacks
  def self.log_error(type, hash)
    @instance ||= new
    @instance.log_error(type, hash)
  end
  
  def self.javascript_error_url
    nil
  end
  
  def self.ajax_error_url
    nil
  end
  
  attr_accessor :type
  attr_accessor :hash
  define_callbacks :record_error
  
  def log_error(type, hash)
    @type = type
    @hash = hash
    run_callbacks :record_error
  end
  
  def self.log_exception(type, e, opts)
    message = opts[:message] || e.to_s
    url = opts[:url] || ""
    user_id = opts[:user_id] || nil
    params = opts[:params] || {}
    log_error(type, params.merge({
      "message" => message,
      'user_id' => user_id,
      "backtrace" => (e.backtrace.join("<br/>\n") rescue "none"),
      "caught_message" => (e.to_s rescue "none"),
      "url" => url
    })) rescue nil
  end
end