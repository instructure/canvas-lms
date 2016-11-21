require 'yaml'

module DrDiff
  class UserConfig
    USER_CONFIG_FILE = File.expand_path("../../../config/gergich_user_config.yml", __FILE__)

    def self.user_config
      @user_config ||= begin
        if File.exist?(USER_CONFIG_FILE)
          YAML.load_file(USER_CONFIG_FILE)
        else
          {}
        end
      end
    end

    def self.only_report_errors?
      user_list = user_config["only_report_errors"] || []
      user_list.include?(ENV['GERRIT_EVENT_ACCOUNT_EMAIL'])
    end
  end
end
