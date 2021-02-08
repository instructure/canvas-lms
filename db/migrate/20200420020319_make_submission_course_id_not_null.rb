class MakeSubmissionCourseIdNotNull < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    if Submission.where(course_id: nil).exists?
      Submission.find_ids_in_ranges(:batch_size => 100_000) do |start_at, end_at|
        next unless GuardRail.activate(:secondary) { Submission.where(:id => start_at..end_at, :course_id => nil).exists? }
        DataFixup::PopulateCourseIdOnSubmissions.run(start_at, end_at)
      end
    end
    change_column_null(:submissions, :course_id, false)
  end

  def down
    change_column_null(:submissions, :course_id, true)
  end
end
