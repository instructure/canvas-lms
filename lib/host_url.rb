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

class HostUrl
  class << self
    attr_accessor :outgoing_email_address, :outgoing_email_domain, :outgoing_email_default_name

    @@default_host = nil
    @@file_host = nil
    @@domain_config = nil
    @@protocol = nil

    def reset_cache!
      @@default_host = @@file_host = @@domain_config = @@protocol = nil
    end

    def domain_config
      if !@@domain_config
        @@domain_config = ConfigFile.load("domain")
        @@domain_config ||= {}
      end
      @@domain_config
    end

    # returns "http" or "https" depending on whether this instance of canvas runs over ssl
    def protocol
      if !@@protocol
        if domain_config.key?('ssl')
          is_secure = domain_config['ssl']
        elsif Attachment.file_store_config.key?('secure')
          is_secure = Attachment.file_store_config['secure']
        else
          is_secure = Rails.env.production?
        end

        @@protocol = is_secure ? "https" : "http"
      end

      @@protocol
    end

    def context_host(context=nil, current_host=nil)
      default_host
    end

    def context_hosts(context=nil, current_host=nil)
      Array(context_host(context, current_host))
    end

    def default_host
      if !@@default_host
        @@default_host = domain_config[:domain] if domain_config.has_key?(:domain)
      end
      res = @@default_host
      res ||= ENV['RAILS_HOST_WITH_PORT']
      res
    end
    
    def file_host_with_shard(account, current_host = nil)
      return [@@file_host, Shard.default] if @@file_host
      res = nil
      res = @@file_host = domain_config[:files_domain] if domain_config.has_key?(:files_domain)
      Rails.logger.warn("No separate files host specified for account id #{account.id}.  This is a potential security risk.") unless res || !Rails.env.production?
      res ||= @@file_host = default_host
      [res, Shard.default]
    end

    def file_host(account, current_host = nil)
      file_host_with_shard(account, current_host).first
    end

    def cdn_host
      # by default only set it for development. useful so that gravatar can
      # proxy our fallback urls
      host = ENV['CANVAS_CDN_HOST']
      host ||= "canvas.instructure.com" if Rails.env.development?
      host
    end

    def short_host(context)
      context_host(context)
    end
    
    def outgoing_email_address(preferred_user="notifications")
      @outgoing_email_address.presence || "#{preferred_user}@#{outgoing_email_domain}"
    end

    def outgoing_email_default_name
      @outgoing_email_default_name.presence || I18n.t("#email.default_from_name", "Instructure Canvas")
    end

    def file_host=(val)
      @@file_host = val
    end
    def default_host=(val)
      @@default_host = val
    end
    
    def is_file_host?(domain)
      safer_host = file_host(Account.default)
      safer_host != default_host && domain == safer_host
    end

    def has_file_host?
      default_host != file_host(Account.default)
    end
  end
end
