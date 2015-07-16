class AddForeignKeys6 < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    add_foreign_key_if_not_exists :quizzes, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :report_snapshots, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :role_overrides, :accounts, :column => :context_id, :delay_validation => true
    RubricAssessment.where("NOT EXISTS (?) AND rubric_association_id IS NOT NULL", RubricAssociation.where("rubric_associations.id=rubric_association_id")).update_all(rubric_association_id: nil)
    add_foreign_key_if_not_exists :rubric_assessments, :rubric_associations, :delay_validation => true
    add_foreign_key_if_not_exists :rubric_assessments, :rubrics, :delay_validation => true
    add_foreign_key_if_not_exists :rubric_associations, :rubrics, :delay_validation => true
    add_foreign_key_if_not_exists :rubrics, :rubrics, :delay_validation => true
    add_foreign_key_if_not_exists :session_persistence_tokens, :pseudonyms, :delay_validation => true
    add_foreign_key_if_not_exists :sis_batches, :enrollment_terms, :column => :batch_mode_term_id, :delay_validation => true
    add_foreign_key_if_not_exists :submissions, :groups, :delay_validation => true
    Submission.where("NOT EXISTS (?) AND media_object_id IS NOT NULL", MediaObject.where("media_objects.id=media_object_id")).update_all(media_object_id: nil)
    add_foreign_key_if_not_exists :submissions, :media_objects, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :submissions, :media_objects
    remove_foreign_key_if_exists :submissions, :groups
    remove_foreign_key_if_exists :sis_batches, :column => :batch_mode_term_id
    remove_foreign_key_if_exists :session_persistence_tokens, :pseudonyms
    remove_foreign_key_if_exists :rubrics, :rubrics
    remove_foreign_key_if_exists :rubric_associations, :rubrics
    remove_foreign_key_if_exists :rubric_assessments, :rubrics
    remove_foreign_key_if_exists :rubric_assessments, :rubric_associations
    remove_foreign_key_if_exists :role_overrides, :column => :context_id
    remove_foreign_key_if_exists :report_snapshots, :accounts
    remove_foreign_key_if_exists :quizzes, :cloned_items
  end
end
