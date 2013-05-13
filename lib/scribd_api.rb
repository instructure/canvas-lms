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

# This is another Singleton to talk to the rscribd singleton with a
# little sugar to make things work a little better for us.  E.g.  All we
# need to do is call ScribdAPI.instance.set_user('some uuid') to change
# the user we're dealing with. 

require 'rubygems'
gem 'rscribd'
require 'rscribd'

class ScribdAPI
  class << self
    def instance
      @@inst ||= new
    end
    
    # Create a shorthand for everything, so ScribdAPI.get_status, etc.
    def method_missing(sym, *args, &block)
      self.instance.send(sym, *args, &block)
    end
  end
  
  def initialize
    self.authenticate
  end
  
  def api
     Scribd::API.instance
  end
  
  # Takes the doc, which is stored in Attachment.scribd_doc
  def get_status(doc)
    doc.conversion_status
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
  
  # This is actually setting up a 'phantom' user, or a unique user for
  # accessing these documents. 
  def set_user(uuid)
    uuid = uuid.uuid if uuid.is_a?(ScribdAccount)
    self.api.user = uuid
  end
  
  def self.config_check(settings)
    scribd = ScribdAPI.new
    scribd.api.key = settings['api_key']
    scribd.api.secret = settings['secret_key']
    begin
      Scribd::Document.find(0)
    rescue Scribd::ResponseError => e
      return "Configuration check failed, please check your settings" if e.code == '401'
    end
    nil
  end
  
  def self.config
    # Return existing value, even if nil, as long as it's defined
    return @config if defined?(@config)
    @config ||= Canvas::Plugin.find(:scribd).try(:settings)
    @config ||= (YAML.load_file(Rails.root+"config/scribd.yml")[Rails.env] rescue nil)
  end
  
  def self.enabled?
    !!config
  end
  
  protected
    def authenticate
      self.api.key = ScribdAPI.config['api_key']
      self.api.secret = ScribdAPI.config['secret_key']
    end
  
end
