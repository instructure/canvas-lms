#
# Copyright (C) 2014 Instructure, Inc.
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

require 'nokogiri'

module VeriCite
  class Response
    SUCCESSFUL_RETURN_CODES = (200..299)

    attr_accessor :return_code
    attr_accessor :assignment_id
    attr_accessor :returned_object_id
    attr_accessor :similarity_score
    attr_accessor :report_url
    attr_accessor :public_error_message
    attr_accessor :return_message
    
    def initialize()
    end

    def assignment_id
     @assignment_id
    end
    
    def report_url
     @report_url
    end

    def similarity_score
      @similarity_score
    end

    def css(*args)
      @document.css(*args)
    end

    def error?
      !success?
    end

    def error_hash
      return {} unless error?
      {
        error_code: return_code,
        error_message: return_message,
        public_error_message: public_error_message,
      }
    end

    # We store the actual error message we got back from vericite in the hash
    # on the object, but often that message is not appropriate to show to
    # users. So we're picking out the most common error messages we see, fixing
    # up the wording, and then using this to display public facing error messages.
    def public_error_message
      @public_error_message
    end

    # should be #object_id but, redefining that could have serious
    # consequences. So, we'll just not do that....
    def returned_object_id
      @returned_object_id
    end

    def return_code
      @return_code
    end

    def return_message
      @return_message
    end

    def success?
      begin
        return_code != nil && SUCCESSFUL_RETURN_CODES.cover?(Integer(return_code))
      rescue
        false
      end
    end

    private

    def extract_body_from(http_response)
      # this was originally has rescue nil on it, but that would have just pushed the failure to
      # the first attempt to access any data from the document. Also, Nokogiri is insanely
      # fault tollerant so if it fails we probably should too...
      Nokogiri::XML::Document.parse(http_response.body)
    end

    def extract_data_at(xpath, default = '')
      return default
    end

    def return_data_node
      @return_data_node
    end
  end
end
