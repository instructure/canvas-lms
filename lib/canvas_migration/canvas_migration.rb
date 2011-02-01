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

module Canvas::Migration
  #logging
  LOG_DIR_PATH = "log"
  LOG_FILENAME = "exporter.log"
  LOG_LEVEL = 0
  HISTORY_LOGS_TO_KEEP = 5
  MAX_LOG_FILE_SIZE = 10*1024*1024  # 10 MB

  def self.init_logging(log_dir=LOG_DIR_PATH, log_level=LOG_LEVEL)
    @logger ||= Rails.logger rescue nil
    return @logger if @logger

    require 'logger'
    @log_dir = log_dir
    make_dir @log_dir
    @logger = Logger.new(File.join(@log_dir, LOG_FILENAME), HISTORY_LOGS_TO_KEEP, MAX_LOG_FILE_SIZE)
    @logger.level = log_level

    @logger
  end

  # Returns the Logger object
  def self.logger
    @logger ||= init_logging
  end

  # Sets the Logger object
  def self.logger=(logger)
    @logger = logger
  end

  # the base log folder
  def self.log_dir
    @log_dir
  end

  # Creates the given directory tree if it doesn't exist
  def self.make_dir(dir)
    if not File.exists?(dir) or not File.directory?(dir)
      FileUtils.mkdir_p dir
    end
    dir
  end

  #instance methods
  def logger
    Canvas::Migration::logger
  end

end
