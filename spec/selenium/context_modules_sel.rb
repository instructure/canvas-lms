require File.expand_path(File.dirname(__FILE__) + "/common")

describe "context_modules selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should only display 'out-of' on an assignment min score restriction when the assignment has a total" do

    username = "nobody@example.com"
    password = "asdfasdf"

    u = user_with_pseudonym :active_user => true, :username => username, :password => password
    u.save!

    e = course_with_teacher :active_course => true, :user => u, :active_enrollment => true
    e.save!

    course = e.course
    ag = course.assignment_groups.create!
    a1 = ag.assignments.create!(:context => course)
    a1.points_possible = 10
    a1.save
    a2 = ag.assignments.create!(:context => course)
    m = course.context_modules.create!
    
    make_content_tag = lambda do |assignment|
      ct = ContentTag.new
      ct.content_id = assignment.id
      ct.content_type = 'Assignment'
      ct.context_id = course.id
      ct.context_type = 'Course'
      ct.title = "Assignment #{assignment.id}"
      ct.tag_type = "context_module"
      ct.context_module_id = m.id
      ct.context_code = "course_#{course.id}"
      ct.save!
      ct
    end
    content_tag_1 = make_content_tag.call a1
    content_tag_2 = make_content_tag.call a2

    login_as(username, password)

    get "/courses/#{e.course_id}/modules"
    driver.execute_script("
      $('#context_module_#{m.id}').find('.edit_module_link').click();
      $('.add_completion_criterion_link:visible').click();
      $('.assignment_picker').val(#{content_tag_1.id});
      $('.assignment_requirement_picker').val('min_score').change();
      return $('.points_possible_parent:visible').length; ").should > 0
    driver.execute_script("
      $('.assignment_picker').val(#{content_tag_2.id});
      $('.assignment_requirement_picker').val('min_score').change();
      return $('.points_possible_parent:visible').length; ").should == 0

  end
end
