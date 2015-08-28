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
        subject: self.subject,
        description: self.comments,
        report_type: self.report_type,
        error_message: self.message,
        perceived_severity: self.user_severity,
        account_id: self.account_id,
        account_domain: self.account_domain_value,
        report_origin_url: self.url,
        reporter: {
          canvas_id: self.user_id.to_s,
          email: self.guess_email,
          name: self.user_name,
          role: self.user_roles,
          become_user_uri: self.become_user_id_uri,
          environment: self.pretty_http_env
        },
        canvas_details: {
          request_context_id: self.request_context_id,
          error_report_id: self.id,
          sub_account: self.sub_account_tag,
        }
      }
    end

    def sub_account_tag(asset_manager=::Context, expected_type=Course)
      if context_string = self.data['context_asset_string']
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
    def report_type(default_value='ERROR')
      return default_value unless self.backtrace.present?
      first_line = self.backtrace.split("\n").first
      match = first_line.match(/^Posted as[^_]*_([A-Z]*)_/) if first_line.present?
      (match.nil? ? nil : match[1]) || default_value
    end

    def user_severity
      self.data.is_a?(Hash) ? self.data['user_perceived_severity'] : ''
    end

    def user_roles
      self.data.is_a?(Hash) ? self.data['user_roles'] : nil
    end

    def account_domain_value
      self.account.try(:domain)
    end

    def user_name
      self.user.try(:name) || "Unknown User"
    end

    def become_user_id_uri
      begin
        if url && user_id
          begin
            become_user_uri = URI.parse(url)
            become_user_uri.query = (Hash[*(become_user_uri.query || '').
                            split('&').map {|part| part.split('=') }.flatten]).
                            merge({'become_user_id' => user_id}).to_query
          rescue URI::Error => e
            become_user_uri = "unable to parse uri: #{url}"
          end
          become_user_uri.to_s
        end
      rescue
        nil
      end
    end

    def pretty_http_env
      if http_env && http_env.respond_to?(:each)
        http_env.map{ |key, val| "#{key}: #{val.inspect}" }.join("\n")
      else
        nil
      end
    end

    def raw_report
      self.__getobj__
    end

  end
end
