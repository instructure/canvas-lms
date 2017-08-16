class CoursePart < ActiveRecord::Base
  belongs_to :course

  def migration_id=(i)
    @migration_id = i
  end

  def migration_id
    @migration_id
  end
end
