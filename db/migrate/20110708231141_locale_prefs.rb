class LocalePrefs < ActiveRecord::Migration
  def self.up
    add_column :users, :locale, :string
    add_column :users, :browser_locale, :string
    add_column :courses, :locale, :string
    add_column :accounts, :default_locale, :string
  end

  def self.down
    remove_column :users, :locale
    remove_column :users, :browser_locale
    remove_column :courses, :locale
    remove_column :accounts, :default_locale
  end
end
