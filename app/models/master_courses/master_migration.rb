class MasterCourses::MasterMigration < ActiveRecord::Base
  belongs_to :master_template, :class_name => "MasterCourses::MasterTemplate"
  belongs_to :user

  strong_params

  include Workflow
  workflow do
    state :created
    state :queued # before the migration job has run
    state :exporting # while we're running the full and/or selective exports
    state :imports_queued # after we've queued up imports in all the child courses and finished the initial migration job

    state :completed # after all the imports have run (successfully hopefully)
    state :exports_failed # if we break during export
    state :imports_failed # if one or more of the imports failed
  end
end
