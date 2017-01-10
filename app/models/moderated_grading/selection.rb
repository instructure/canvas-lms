class ModeratedGrading::Selection < ActiveRecord::Base
  belongs_to :provisional_grade,
    foreign_key: :selected_provisional_grade_id,
    class_name: 'ModeratedGrading::ProvisionalGrade'
  belongs_to :assignment
  belongs_to :student, class_name: 'User'

  validates :student_id, uniqueness: { scope: :assignment_id }

end
