module DataFixup
  module ConvertHighContrastSettingToFeatureFlag
    def self.run
      User.where("preferences LIKE '%high_contrast%'").where("workflow_state<>'deleted'").find_each do |user|
        if user.preferences[:enabled_theme] == 'high_contrast'
          user.enable_feature!(:high_contrast)
        end
      end
    end
  end
end
