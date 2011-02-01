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


class CutyCapt
  CUTYCAPT_DEFAULTS = {
    :delay => 3000,
    :timeout => 30000
  }
  
  def self.config
    return @@config if defined?(@@config)
    @@config ||= CUTYCAPT_DEFAULTS.merge(YAML.load_file(RAILS_ROOT + "/config/cutycapt.yml")[RAILS_ENV]).with_indifferent_access rescue nil
    @@config = nil unless @@config['path']
    @@config
  end
  
  def self.logger
    RAILS_DEFAULT_LOGGER
  end
  
  def self.enabled?
    return !self.config.nil?
  end
  
  def self.snapshot_url(url, format = "png", &block)
    return nil unless config = self.config
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