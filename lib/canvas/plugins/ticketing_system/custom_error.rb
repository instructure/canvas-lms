# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas::Plugins::TicketingSystem
  # a decorator for ErrorReport that provides some helper
  # methods to massage data on the way out to an external ticketing
  # system.  Used by wrapping the ErrorReport as the single parameter
  # to this classes constructor:
  #
  # error = CustomError.new(error_report)
  #
  class CustomError < DelegateClass(::ErrorReport)
    delegate :id, to: :__getobj__

    # whether sending to a web endpoint, or an email message,
    # this is the canonical way to present a Canvas ErrorReport
    # to the outside world. The "reporter" element has info
    # about the user involved in the trouble ticket or
    # exception, and the "canvas_details" element has
    # a hash of useful information in case a ticket gets
    # escalated back to instructure.
    #
    # returns Hash
    def to_document
      {
        subject:,
        description: comments,
        report_type:,
        error_message: message,
        perceived_severity: user_severity,
        account_id:,
        account_domain: account_domain_value,
        report_origin_url: url,
        reporter: {
          canvas_id: user_id.to_s,
          email: guess_email,
          name: user_name,
          role: user_roles,
          become_user_uri: become_user_id_uri,
          environment: http_env
        },
        canvas_details: {
          request_context_id:,
          error_report_id: id,
          sub_account: sub_account_tag,
        }
      }
    end

    def sub_account_tag(asset_manager = ::Context, expected_type = Course)
      if (context_string = data["context_asset_string"])
        context = asset_manager.find_by_asset_string(context_string)
        if context.is_a? expected_type
          "subaccount_#{context.account_id}"
        end
      end
    end

    # this tries to strip the TYPE of the error
    # report from the "Posted as _ERROR_" portion of our
    # error report backtrace attribute, but if there's nothing
    # recognizable there it will just assume it's an ERROR
    def report_type(default_value = "ERROR")
      return default_value unless backtrace.present?

      first_line = backtrace.split("\n").first
      match = first_line.match(/^Posted as[^_]*_([A-Z]*)_/) if first_line.present?
      (match.nil? ? nil : match[1]) || default_value
    end

    def user_severity
      (data.is_a?(Hash) && data["user_perceived_severity"]) || ""
    end

    def user_roles
      data.is_a?(Hash) ? data["user_roles"] : nil
    end

    def account_domain_value
      account.try(:domain)
    end

    def user_name
      user.try(:name) || "Unknown User"
    end

    def become_user_id_uri
      if url && user_id
        begin
          become_user_uri = URI.parse(url)
          become_user_uri.query = (Hash[*(become_user_uri.query || "")
                          .split("&").map { |part| part.split("=") }.flatten])
                                  .merge({ "become_user_id" => user_id }).to_query
        rescue URI::Error
          become_user_uri = "unable to parse uri: #{url}"
        end
        become_user_uri.to_s
      end
    rescue
      nil
    end

    def pretty_http_env
      if http_env.respond_to?(:each)
        http_env.map { |key, val| "#{key}: #{val.inspect}" }.join("\n")
      else
        nil
      end
    end

    def raw_report
      __getobj__
    end
  end
end
