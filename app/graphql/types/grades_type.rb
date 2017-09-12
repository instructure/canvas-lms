module Types
  GradesType = GraphQL::ObjectType.define do
    name "Grades"

    description "Contains grade information for a course or grading period"

    field :currentScore, types.Float, <<-DESC, property: :current_score
    The current score includes all graded assignments
    DESC
    field :currentGrade, types.String, property: :current_grade

    field :finalScore, types.Float, <<-DESC, property: :final_score
    The final score includes all assignments (ungraded assignments are counted as 0 points)
    DESC
    field :finalGrade, types.String, property: :final_grade
  end
end
