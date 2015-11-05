require 'diplomat'

module Canvas
  class DynamicSettings

    class ConsulError < StandardError
    end

    KV_NAMESPACE = "/config/canvas".freeze

    class << self
      attr_accessor :config

      def config=(conf_hash)
        @config = conf_hash
        if conf_hash.present?
          Diplomat.configure do |diplomat_conf|
            protocol = conf_hash.fetch("ssl", true) ? "https" : "http"
            host_and_port = "#{conf_hash.fetch('host')}:#{conf_hash.fetch('port')}"
            diplomat_conf.url = "#{protocol}://#{host_and_port}"
            diplomat_conf.acl_token = conf_hash.fetch("acl_token", nil)
          end

          init_data = conf_hash.fetch("init_values", {})
          init_values(init_data)
        end
      end

      def find(key)
        raise(ConsulError, "Unable to contact consul without config") if config.nil?
        config_records = Diplomat::Kv.get("#{KV_NAMESPACE}/#{key}", recurse: true)
        config_records.each_with_object({}) do |node, hash|
          hash[node[:key].split("/").last] = node[:value]
        end
      end

      private
      def init_values(hash)
        hash.each do |parent_key, settings|
          settings.each do |child_key, value|
            Diplomat::Kv.put("#{KV_NAMESPACE}/#{parent_key}/#{child_key}", value)
          end
        end
      end
    end

  end
end
