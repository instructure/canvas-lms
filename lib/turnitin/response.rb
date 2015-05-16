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

module Turnitin
  class Response
    SUCCESSFUL_RETURN_CODES = (1..99)

    def initialize(http_response)
      @http_response = http_response
      @document = extract_body_from(http_response)
    end

    def assignment_id
      extract_data_at('./assignmentid')
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

    # We store the actual error message we got back from turnitin in the hash
    # on the object, but often that message is not appropriate to show to
    # users. So we're picking out the most common error messages we see, fixing
    # up the wording, and then using this to display public facing error messages.
    def public_error_message
      return '' if success?
      case return_code
      when 216
        I18n.t('turnitin.error_216', "The student limit for this account has been reached. Please contact your account administrator.")
      when 217
        I18n.t('turnitin.error_217', "The turnitin product for this account has expired. Please contact your sales agent to renew the turnitin product.")
      when 414
        I18n.t('turnitin.error_414', "The originality report for this submission is not available yet.")
      when 415
        I18n.t('turnitin.error_415', "The originality score for this submission is not available yet.")
      when 1007
        I18n.t('turnitin.error_1007', "The uploaded file is too big.")
      when 1009
        I18n.t('turnitin.error_1009', "Invalid file type. (Valid file types are MS Word, Acrobat PDF, Postscript, Text, HTML, WordPerfect (WPD) and Rich Text Format.)")
      when 1013
        I18n.t('turnitin.error_1013', "The student submission must be more than twenty words of text in order for it to be rated by turnitin.")
      when 1023
        I18n.t('turnitin.error_1023', "The PDF file could not be read. Please make sure that the file is not password protected.")
      else
        I18n.t('turnitin.error_default', "There was an error submitting to turnitin. Please try resubmitting the file before contacting support.")
      end
    end

    # should be #object_id but, redefining that could have serious
    # consequences. So, we'll just not do that....
    def returned_object_id
      extract_data_at('./objectID')
    end

    def return_code
      @return_code ||= extract_data_at('./rcode', -1).to_i
    end

    def return_message
      extract_data_at('./rmessage')
    end

    def success?
      SUCCESSFUL_RETURN_CODES.cover?(return_code)
    end

    private

    def extract_body_from(http_response)
      # this was originally has rescue nil on it, but that would have just pushed the failure to
      # the first attempt to access any data from the document. Also, Nokogiri is insanely
      # fault tollerant so if it fails we probably should too...
      Nokogiri::XML::Document.parse(http_response.body)
    end

    def extract_data_at(xpath, default = '')
      return default unless return_data_node.present?
      found_node = return_data_node.at_xpath(xpath)
      found_node.present? ? found_node.content : default
    end

    def return_data_node
      @return_data_node ||= @document.at_xpath('/returndata')
    end
  end
end
