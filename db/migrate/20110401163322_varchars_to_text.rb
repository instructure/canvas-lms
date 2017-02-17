class VarcharsToText < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :assessment_question_banks, :title, :text
    change_column :assessment_questions, :name, :text
    change_column :asset_user_accesses, :display_name, :text
    change_column :attachments, :display_name, :text
    change_column :attachments, :filename, :text
    change_column :content_tags, :title, :text
    change_column :context_modules, :name, :text
    change_column :delayed_messages, :name_of_topic, :text
    change_column :messages, :from_name, :text
    change_column :messages, :subject, :text
    change_column :notifications, :sms_body, :text
    change_column :page_views, :url, :text
    change_column :users, :features_used, :text
    change_column :wiki_pages, :url, :text
  end

  def self.down
    change_column :assessment_question_banks, :title, :string
    change_column :assessment_questions, :name, :string
    change_column :asset_user_accesses, :display_name, :string
    change_column :attachments, :display_name, :string
    change_column :attachments, :filename, :string
    change_column :content_tags, :title, :string
    change_column :context_modules, :name, :string
    change_column :delayed_messages, :name_of_topic, :string
    change_column :messages, :from_name, :string
    change_column :messages, :subject, :string
    change_column :notifications, :sms_body, :string
    change_column :page_views, :url, :string
    change_column :users, :features_used, :string
    change_column :wiki_pages, :url, :string
  end
end
