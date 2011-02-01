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
    def context_host(context=nil)
      default_host
    end
    
    def default_host
      @@default_host ||= nil
      if !@@default_host
        @@domain_config ||= File.exist?("#{RAILS_ROOT}/config/domain.yml") && YAML.load_file("#{RAILS_ROOT}/config/domain.yml")[RAILS_ENV].with_indifferent_access
        @@default_host = @@domain_config[:domain] if @@domain_config && @@domain_config.has_key?(:domain)
      end
      res = @@default_host
      res ||= ENV['RAILS_HOST_WITH_PORT']
      res
    end
    
    def file_host(account)
      @@file_host ||= nil
      return @@file_host if @@file_host
      res = nil
      unless Rails.env.development?
        @@domain_config ||= File.exist?("#{RAILS_ROOT}/config/domain.yml") && YAML.load_file("#{RAILS_ROOT}/config/domain.yml")[RAILS_ENV].with_indifferent_access
        res = @@file_host = @@domain_config[:files_domain] if @@domain_config && @@domain_config.has_key?(:files_domain)
        Rails.logger.warn("No separate files host specified for account id #{account.id}.  This is a potential security risk.") unless res
      end
      res ||= default_host
    end
    
    def configure_email(options)
      options = options.with_indifferent_access
      raise "missing domain configuration!" unless options.has_key?(:domain)
      options[:authentication] = options[:authentication].to_sym if options.has_key?(:authentication)
      ActionMailer::Base.smtp_settings = options
    end
    
    def outgoing_email_address(preferred_user="notifications")
      config = ActionMailer::Base.smtp_settings
      return config[:outgoing_address] if config.has_key?(:outgoing_address)
      return "#{preferred_user}@" + config[:domain]
    end
    
    def outgoing_email_domain
      return ActionMailer::Base.smtp_settings[:domain]
    end
  end
end
