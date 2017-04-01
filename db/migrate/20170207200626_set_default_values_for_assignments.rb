class SetDefaultValuesForAssignments < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    fields = [
      :all_day, :could_be_locked, :grade_group_students_individually,
      :anonymous_peer_reviews, :turnitin_enabled, :vericite_enabled,
      :moderated_grading, :omit_from_final_grade, :freeze_on_copy,
      :copied, :only_visible_to_overrides, :post_to_sis
    ]
    fields.each { |field| change_column_default(:assignments, field, false) }
    fields += [:peer_reviews_assigned, :peer_reviews, :automatic_peer_reviews, :muted, :intra_group_peer_reviews]
    DataFixup::BackfillNulls.run(Assignment, fields, default_value: false)
    fields.each { |field| change_column_null_with_less_locking(:assignments, field) }
  end

  def down
    fields_with_defaults = [
      :all_day, :could_be_locked, :grade_group_students_individually,
      :anonymous_peer_reviews, :turnitin_enabled, :vericite_enabled,
      :moderated_grading, :omit_from_final_grade, :freeze_on_copy,
      :copied, :only_visible_to_overrides, :post_to_sis
    ]
    fields_with_null_constraints = fields_with_defaults +
      [:peer_reviews_assigned, :peer_reviews, :automatic_peer_reviews, :muted, :intra_group_peer_reviews]
    fields_with_null_constraints.each { |field| change_column_null(:assignments, field, true) }
    fields_with_defaults.each { |field| change_column_default(:assignments, field, nil) }
  end
end
