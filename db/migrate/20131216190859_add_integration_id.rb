class AddIntegrationId < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :pseudonyms,       :integration_id, :string
    add_column :course_sections,  :integration_id, :string
    add_column :courses,          :integration_id, :string
    add_column :enrollment_terms, :integration_id, :string
    add_column :accounts,         :integration_id, :string

    add_index :pseudonyms,        [:integration_id, :account_id],
              unique: true, algorithm: :concurrently,
              name: "index_pseudonyms_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :course_sections,   [:integration_id, :root_account_id],
              unique: true, algorithm: :concurrently,
              name: "index_sections_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :courses,           [:integration_id, :root_account_id],
              unique: true, algorithm: :concurrently,
              name: "index_courses_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :enrollment_terms,  [:integration_id, :root_account_id],
              unique: true, algorithm: :concurrently,
              name: "index_terms_on_integration_id",
              where: "integration_id IS NOT NULL"
    add_index :accounts,          [:integration_id, :root_account_id],
              unique: true, algorithm: :concurrently,
              name: "index_accounts_on_integration_id",
              where: "integration_id IS NOT NULL"

  end

  def self.down
    remove_index :pseudonyms,       name: "index_pseudonyms_on_integration_id"
    remove_index :course_sections,  name: "index_sections_on_integration_id"
    remove_index :courses,          name: "index_courses_on_integration_id"
    remove_index :enrollment_terms, name: "index_terms_on_integration_id"
    remove_index :accounts,         name: "index_accounts_on_integration_id"

    remove_column :pseudonyms,       :integration_id
    remove_column :course_sections,  :integration_id
    remove_column :courses,          :integration_id
    remove_column :enrollment_terms, :integration_id
    remove_column :accounts,         :integration_id
  end
end
