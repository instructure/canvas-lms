#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

class ScribdAPI
  class << self
    def initialize
      self.authenticate if config
    end

    # This uploads the file and returns the doc_id.
    # This should not need to use any other API options, as long as the file
    # has its extension in tact.
    def upload(filename, filetype=nil)
      if filetype
        # MAKE SURE THAT THIS IS PRIVATE, that would suck bad if anything ever got sent as not private
        Scribd::Document.upload(:file => filename, :type => filetype, :access => 'private')
      else
        ErrorReport.log_error(:default, {
          :message => "tried to upload a scribd doc that does not have a filetype, that should never happen.",
          :url => filename,
        })
      end
    end

    def config_check(settings)
      authenticate(settings)
      begin
        Scribd::Document.find(0)
      rescue Scribd::ResponseError => e
        return "Configuration check failed, please check your settings" if e.code == '401'
      end
      nil
    end

    def config
      Canvas::Plugin.find(:scribd).try(:settings)
    end

    def enabled?
      !!config
    end

    protected
    def authenticate(settings = config)
      Scribd::API.instance.key = settings['api_key']
      Scribd::API.instance.secret = settings['secret_key']
    end
  end
end
