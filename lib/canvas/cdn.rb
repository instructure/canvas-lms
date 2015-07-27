module Canvas
  module Cdn
    class << self
      def config
        @config ||= begin
          config = ActiveSupport::OrderedOptions.new
          config.enabled = false
          yml = ConfigFile.load('canvas_cdn')
          config.merge!(yml.symbolize_keys) if yml
          config
        end
      end

      def enabled?
        config.enabled
      end

      def push_to_s3!(*args, &block)
        return unless enabled?
        uploader = Canvas::Cdn::S3Uploader.new(*args)
        uploader.upload!(&block)
      end
    end
  end
end
