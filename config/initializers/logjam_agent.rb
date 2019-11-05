module LogjamAgent
  # Configure the application name (required). Must not contain dots or hyphens.
  self.application_name = "canvas_lms"

  # Configure the environment name (optional). Defaults to Rails.env.
  # self.environment_name = Rails.env

  # Configure the application revision (optional). Defaults to (git rev-parse HEAD).
  # self.application_revision = "f494e11afa0738b279517a2a96101a952052da5d"

  # Configure request data forwarder for stdout.
  add_forwarder(:stdout)

  # Configure ip obfuscation. Defaults to no obfuscation.
  self.obfuscate_ips = true

  # Configure cookie obfuscation. Defaults to [/_session\z/].
  self.obfuscated_cookies = [/_session\z/]

  # Configure asset request logging and forwarding. Defaults to ignore
  # asset requests in development mode. Set this to false if you need
  # to debug asset request handling.
  self.ignore_asset_requests = Rails.env.development?

  # Disable ActiveSupport::Notifications (and thereby logging) of ActionView
  # render events. Defaults to false.
  # self.ignore_render_events = Rails.env.production?

  # Configure log level for logging on disk: only lines with a log level
  # greater than or equal to the specified one will be logged to disk.
  # Defaults to Logger::INFO. Note that logjam_agent extends the standard
  # logger log levels by the constant NONE, which indicates no logging.
  # Also, setting the level has no effect on console logging in development.
  # self.log_device_log_level = Logger::WARN   # log warnings, errors, fatals and unknown log messages
  # self.log_device_log_level = Logger::NONE   # log nothing at all
  self.log_device_log_level =  Rails.logger.level

  # Configure lines which will not be logged locally.
  # They will still be sent to the logjam server. Defaults to nil.
  self.log_device_ignored_lines = /^\s*Rendered/

  # It is also possible to ovveride this on a per request basis,
  # for example in a Rails before_action
  # LogjamAgent.request.log_device_ignored_lines = /^\s*(?:Rendered|REDIS)/

  # Configure maximum size of logged parameters and environment variables sent to
  # logjam. Defaults to 1024.
  # self.max_logged_param_size = 1024

  # Configure maximum size of logged parameters and environment variables sent to
  # logjam. Defaults to 1024 * 100.
  # self.max_logged_cookie_size = 1024 * 100

  # Configure maximum log line length. Defaults to 2048.
  # This setting only applies to the lines sent with the request.
  self.max_line_length = 2048

  # Configure max bytes allowed for all log lines. Defaults to 1Mb.
  # This setting only applies to the lines sent with the request.
  self.max_bytes_all_lines = 1024 * 1024

  # Configure compression method. Defaults to NO_COMPRESSION. Available
  # compression methods are ZLIB_COMPRESSION, SNAPPY_COMPRESSION, LZ4_COMPRESSION.
  # Snappy and LZ4 are faster and less CPU intensive than ZLIB, ZLIB achieves
  # higher compression rates. LZ4 is faster to decompress than Snappy
  # and recommended.
  # self.compression_method = ZLIB_COMPRESSION
  # self.compression_method = SNAPPY_COMPRESSION
  # self.compression_method = LZ4_COMPRESSION

  # Activate the split between hard and soft-exceptions. Soft exceptions are
  # all exceptions below a log level of Logger::ERROR. Logjam itself can then
  # display those soft exceptions differently. Defaults to `true`.
  # self.split_hard_and_soft_exceptions = true

  # TODO: remove me or put behind a config. Just trying to see what Heroku shows if
  # I just use the normal STDOUTForwarder
  # Patch the STDOUT Forwarder to send to Rails' logger instead, since stdout
  # seems to get lost somewhere.
  #class STDOUTForwarder
  #  def forward(data, options={})
  #    msg = LogjamAgent.json_encode_payload(data)
  #    Rails.logger.info msg
  #  end
  #end
end
