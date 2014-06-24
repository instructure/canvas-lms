require_dependency 'sfu_course_form'

# Should run with each request
config.to_prepare do
  SFU::CourseForm::initialize
end
