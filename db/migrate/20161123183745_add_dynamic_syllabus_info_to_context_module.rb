class AddDynamicSyllabusInfoToContextModule < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :context_modules, :intro_text, :text
    add_column :context_modules, :image_url, :string
    add_column :context_modules, :part_id, :integer, :limit => 8
  end
end
