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

require 'logger'
require 'syslog'

class SyslogWrapper

  attr_accessor :level, :datetime_format

  @@silencer = true
  def self.silencer; @@silencer; end
  def silencer; @@silencer; end
  def self.silencer=(obj); @@silencer = obj; end
  def silencer=(obj); @@silencer = obj; end

  def silence(temporary_level = Logger::ERROR)
    if silencer
      begin
        old_logger_level, @level = @level, temporary_level
        yield self
      ensure
        @level = old_logger_level
      end
    else
      yield self
    end
  end
  alias :quietly :silence

  # facility is a logical-or-ed collection of the following constants in Syslog
  #   LOG_AUTHPRIV - security or authorization messages which should be kept private
  #   LOG_CONSOLE - system console message
  #   LOG_CRON - system task scheduler (cron or at)
  #   LOG_DAEMON - a system daemon which has no facility value of its own
  #   LOG_FTP - an ftp server
  #   LOG_LRP - line printer subsystem
  #   LOG_MAIL - mail delivery or transport subsystem
  #   LOG_NEWS - usenet  news system
  #   LOG_NTP - network time protocol server
  #   LOG_SECURITY - general security message
  #   LOG_SYSLOG - messages generated internally by syslog
  #   LOG_USER - generic user-level message
  #   LOG_UUCP - uucp subsystem
  #   LOG_LOCAL0 through LOG_LOCAL7 - locally defined facilities
  # example: SyslogWrapper.new("canvas", Syslog::LOG_USER, :include_pid => true)
  def initialize(ident, facility=0, options={})
    unless $syslog
      flags = 0
      flags |= Syslog::LOG_CONS if options[:bail_to_console]
      flags |= Syslog::LOG_NDELAY if options[:ndelay]
      flags |= Syslog::LOG_PERROR if options[:perror]
      flags |= Syslog::LOG_PID if options[:include_pid]
      $syslog = Syslog.open(ident, flags, facility)
    end
    @level = 0
    @skip_thread_context = options[:skip_thread_context]
    @datetime_format = nil # ignored completely
  end
  
  def close; end

  SEVERITY_MAP = {
    Logger::DEBUG => :debug,
    Logger::INFO => :info,
    Logger::WARN => :warning,
    Logger::ERROR => :err,
    Logger::FATAL => :crit,
    Logger::UNKNOWN => :notice }

  def add(severity, message=nil, progname=nil)
    severity ||= Logger::UNKNOWN
    return if @level > severity
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
      end
    end
    message = message.to_s.strip.gsub(/\e\[([0-9]+(;|))+m/, '')
    unless @skip_thread_context
      context = Thread.current[:context] || {}
      message = "[#{context[:session_id] || "-"} #{context[:request_id] || "-"}] #{message}"
    end
    $syslog.send(SEVERITY_MAP[severity], "%s", message)
  end
  alias_method :log, :add
  
  def <<(msg); add(@level, msg); end
  
  def debug(progname=nil, &block); add(Logger::DEBUG, nil, progname, &block); end

  def info(progname=nil, &block); add(Logger::INFO, nil, progname, &block); end

  def warn(progname=nil, &block); add(Logger::WARN, nil, progname, &block); end

  def error(progname=nil, &block); add(Logger::ERROR, nil, progname, &block); end

  def fatal(progname=nil, &block); add(Logger::FATAL, nil, progname, &block); end

  def unknown(progname=nil, &block); add(Logger::UNKNOWN, nil, progname, &block); end

  def debug?; @level <= Logger::DEBUG; end

  def info?; @level <= Logger::INFO; end

  def warn?; @level <= Logger::WARN; end

  def error?; @level <= Logger::ERROR; end

  def fatal?; @level <= Logger::FATAL; end
  
end
