#
# Copyright (C) 2012 Instructure, Inc.
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

# A small wrapper around the CutyCapt binary.
# 
# Requires a config file in RAILS_ROOT/config/cutycapt.yml that looks like this:
# 
# production:
#   path: /usr/bin/cutycapt
#   delay: 3000
#   timeout: 30000
#   display: ':0'
#
# delay is how many ms to wait before taking the snapshot (to let the page finish rendering)
# display is whatever display cutycapt should use. (You should probably use Xvfb.)

require 'resolv'
require 'netaddr'

class CutyCapt
  CUTYCAPT_DEFAULTS = {
    :delay => 3000,
    :timeout => 30000,
    :ip_blacklist => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '169.254.169.254' ],
    :domain_blacklist => [ ],
    :allowed_schemes => [ 'http', 'https' ]
  }
  
  cattr_writer :config
  
  def self.config
    return @@config if defined?(@@config) && @@config
    @@config = CUTYCAPT_DEFAULTS.merge(Setting.from_config('cutycapt') || {}).with_indifferent_access
    self.process_config
    @@config = nil unless @@config[:path]
    @@config
  end
  
  def self.process_config
    @@config[:ip_blacklist] = @@config[:ip_blacklist].map {|ip| NetAddr::CIDR.create(ip) } if @@config[:ip_blacklist]
    @@config[:domain_blacklist] = @@config[:domain_blacklist].map {|domain| Resolv::DNS::Name.create(domain) } if @@config[:domain_blacklist]
  end
  
  def self.logger
    RAILS_DEFAULT_LOGGER
  end
  
  def self.enabled?
    return !self.config.nil?
  end
  
  def self.verify_url(url)
    config = self.config
    
    uri = URI.parse(url)
    unless config[:allowed_schemes] && config[:allowed_schemes].include?(uri.scheme)
      logger.warn("Skipping non-http[s] URL: #{url}")
      return false
    end
    
    dns_host = Resolv::DNS::Name.create(uri.host)
    if config[:domain_blacklist] && config[:domain_blacklist].any? {|bl_host| dns_host == bl_host || dns_host.subdomain_of?(bl_host) }
      logger.warn("Skipping url because of blacklisted domain: #{url}")
      return false
    end
    
    addresses = Resolv.getaddresses(uri.host)
    if config[:ip_blacklist] && addresses.any? {|address| config[:ip_blacklist].any? {|cidr| cidr.matches?(address) rescue false } }
      logger.warn("Skipping url because of blacklisted IP address: #{url}")
      return false
    end
    
    true
  end
  
  def self.snapshot_url(url, format = "png", &block)
    return nil unless config = self.config
    return nil unless self.verify_url(url)
    
    img_file = Tempfile.new('websnappr').path + ".#{format}"
    
    saved_display = ENV["DISPLAY"]
    ENV["DISPLAY"] = config[:display] if config[:display]
    result = Kernel.system(config[:path], "--url=#{url}",
                                          "--out=#{img_file}",
                                          "--out-format=#{format}",
                                          "--delay=#{config[:delay]}",
                                          "--max-wait=#{config[:timeout]}")
    ENV["DISPLAY"] = saved_display
    
    if !result
      logger.error("Capture failed with code: #{$?}")
      File.unlink(img_file)
      return nil
    end
    
    if block_given?
      yield img_file
      File.unlink(img_file)
      return nil
    end
    
    img_file
  end
end
