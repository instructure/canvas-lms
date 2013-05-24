if $0 == "irb"
  class TeeLogger < Struct.new(:loggers)
    def method_missing(method, *args, &block)
      loggers.each do |logger|
        logger.send(method, *args, &block)
      end
    end
  end

  ActiveRecord::Base.logger = TeeLogger.new([ActiveRecord::Base.logger, Logger.new($stderr)])
end
