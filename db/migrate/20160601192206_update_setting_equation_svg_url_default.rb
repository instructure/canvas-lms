class UpdateSettingEquationSvgUrlDefault < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    return unless Shard.current.default?

    setting = Setting.where(name: 'codecogs.equation_image_link').take
    if setting.present?
      Setting.set('equation_image_url', "#{setting.value}?")
    end
  end

  def down
    return unless Shard.current.default?

    setting = Setting.where(name: 'equation_image_url').take
    if setting.present?
      Setting.set('codecogs.equation_image_link', setting.value.sub(/\?$/, ''))
    end
  end
end
