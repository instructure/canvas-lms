require_relative "../spec_helper"

describe DataFixup::MoveMasterImportResults do
  it "should move import results over" do
    course_factory
    topic = @course.discussion_topics.create!(:title => "some title")
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    account_admin_user(:active_all => true)

    @copy_to = course_factory
    @sub = @template.add_child_course!(@copy_to)

    @migration = MasterCourses::MasterMigration.start_new_migration!(@template, @admin)
    run_jobs
    result = @migration.reload.migration_results.first
    result.update_attribute(:results, {:skipped => ['blah']})

    import_results = {result.content_migration_id => {
      :state => result.state, :import_type => result.import_type.to_sym, :subscription_id => result.child_subscription_id, :skipped => result.results[:skipped]
    }}
    @migration.update_attribute(:import_results, import_results)
    MasterCourses::MigrationResult.where(:master_migration_id => @migration).delete_all # make sure they're gone

    DataFixup::MoveMasterImportResults.run

    expect(@migration.reload.import_results).to be_blank
    new_result = @migration.migration_results.first
    expect(new_result.attributes.except('id')).to eq result.attributes.except('id')
  end
end
