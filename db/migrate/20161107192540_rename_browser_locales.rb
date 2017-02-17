class RenameBrowserLocales < ActiveRecord::Migration[4.2]
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
    User.where(browser_locale: old).update_all(browser_locale: new)
  end
end
