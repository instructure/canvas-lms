class CourseProfile < Profile
  acts_as_list :scope => :root_account_id
end