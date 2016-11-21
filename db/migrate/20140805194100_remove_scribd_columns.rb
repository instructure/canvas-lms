class RemoveScribdColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    change_table :attachments do |t|
      t.remove :scribd_mime_type_id
      t.remove :submitted_to_scribd_at
      t.remove :scribd_doc
      t.remove :scribd_attempts
      t.remove :cached_scribd_thumbnail
    end
  end

  def down
    change_table :attachments do |t|
      t.integer  "scribd_mime_type_id",       :limit => 8
      t.datetime "submitted_to_scribd_at"
      t.text     "scribd_doc"
      t.integer  "scribd_attempts"
      t.string   "cached_scribd_thumbnail"
    end
    add_index "attachments", ["scribd_attempts"]
    add_index "attachments", ["scribd_mime_type_id"]
  end
end
