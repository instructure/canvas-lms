module DataFixup::AddNewDefaultReport
  def self.run(new_report)
    PluginSetting.where(name: 'account_reports').find_each do |s|
      next if s.disabled?
      s.settings[new_report] = true
      s.save!
    end
  end
end
