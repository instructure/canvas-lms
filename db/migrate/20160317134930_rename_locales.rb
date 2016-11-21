class RenameLocales < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  CHANGES = {
      'zh_Hant' => 'zh-Hant',
      'zh' => 'zh-Hans',
      'fa-IR' => 'fa'
  }.freeze

  def up
    CHANGES.each do |(old, new)|
      apply_change(old, new)
    end
  end

  def down
    CHANGES.each do |(new, old)|
      apply_change(old, new)
    end
  end

  def apply_change(old, new)
    Account.where(default_locale: old).update_all(default_locale: new)
    Course.where(locale: old).update_all(locale: new)
    User.where(locale: old).update_all(locale: new)
  end
end
