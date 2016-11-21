class DropCommentsFromRubricAssessments < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    def up
      remove_column :rubric_assessments, :comments
    end

    def down
      add_column :rubric_assessments, :comments, :text
    end
  end
end
