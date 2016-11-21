class RemoveCodecogsEquationImageSettingKey < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    return unless Shard.current.default?

    Setting.remove('codecogs.equation_image_link')
  end

  def down
    return unless Shard.current.default?

    Setting.remove('equation_image_url')
  end
end
