# frozen_string_literal: true

module DataFixup::PopulateCourseIdOnSubmissions
  def self.run(start_at, end_at)
    Submission.find_ids_in_ranges(start_at: start_at, end_at: end_at) do |min_id, max_id|
      Submission.where(:id => min_id..max_id, :course_id => nil).joins(:assignment).update_all("course_id = assignments.context_id")
    end
  end
end
