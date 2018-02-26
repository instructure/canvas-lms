class RetainedData < ActiveRecord::Base
  belongs_to :user
  attr_accessible :name, :value

  # FIXME: give separate answer per course, but somehow fallback
  def self.get_for_course(course_id, user_id, name)
    res = RetainedData.where(:user_id => user_id, :name => name)
    if res.empty?
      return nil
    else
      return res.first
    end
  end
end
