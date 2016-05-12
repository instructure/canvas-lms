class CreateContentTagSectionRestrictions < ActiveRecord::Migration
  tag :postdeploy
  def change
    create_table :content_tag_section_restrictions do |t|
      t.integer :content_tag_id
      t.integer :section_id

      t.timestamps
    end
  end
end
