class CopyThrottlingSettingsToNewNames < ActiveRecord::Migration[5.2]
  tag :predeploy

  def copy_list(source, destination)
    value = Setting.get(source, nil)
    Setting.set(destination, value) if value
  end

  def up
    return unless Shard.current.default?

    copy_list("request_throttle.whitelist", "request_throttle.approvelist")
    copy_list("request_throttle.blacklist", "request_throttle.blocklist")
  end
end
