require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples 'Arrange By dropdown' do |context|
  before :each do
    enroll_context(context)
    get "/courses/#{@course.id}/grades/#{@student.id}"
  end

  let(:due_date_order) {[@assignment0.title, @quiz.title, @discussion.title, @assignment1.title]}
  let(:title_order) {[@quiz.title, @assignment1.title, @assignment0.title, @discussion.title]}
  let(:module_order) {[@quiz.title, @assignment0.title, @assignment1.title, @discussion.title]}
  let(:assign_group_order) {[@assignment0.title, @discussion.title, @quiz.title, @assignment1.title]}

  it 'should persist', test_id: pick_test_id(context, "591860", "592108", "592119", "592130"), priority: pick_priority(context, "1", "2") do
    click_option('#assignment_order', 'Title')
    get "/courses/#{@course.id}"
    get "/courses/#{@course.id}/grades/#{@student.id}"

    table_rows = ff('#grades_summary tr')
    title_order.each_with_index do |assign_name, index|
      expect(table_rows[3 * index + 1].find_element(:css, 'th').text).to eq assign_name
    end
  end

  it 'should exist with one course', test_id: pick_test_id(context, "591850", "592109", "592120", "592131"), priority: pick_priority(context, "1", "2") do
    expect(f('#assignment_order')).to be_present
  end

  it 'should exist with more than one course', test_id: pick_test_id(context, "591851", "592110", "592121", "592132"), priority: pick_priority(context, "1", "2") do
    course2 = Course.create!(name: 'Second Course')
    course2.offer!
    course2.enroll_student(@student).accept!

    get "/courses/#{@course.id}/grades/#{@student.id}"

    expect(f('#assignment_order')).to be_present
  end

  it 'should contain Title', test_id: pick_test_id(context, "591852", "592111", "592122", "592133"), priority: pick_priority(context, "1", "2") do
    f('#assignment_order').click
    expect(f("#assignment_order option[value=\"title\"]")).to be_present
  end

  it 'should contain Due Date', test_id: pick_test_id(context, "591853", "592112", "592123", "592134"), priority: pick_priority(context, "1", "2") do
    f('#assignment_order').click
    expect(f("#assignment_order option[value=\"due_at\"]")).to be_present
  end

  it 'should contain Module', test_id: pick_test_id(context, "591854", "592113", "592124", "592135"), priority: pick_priority(context, "1", "2") do
    f('#assignment_order').click
    expect(f("#assignment_order option[value=\"module\"]")).to be_present
  end

  it 'should contain Assignment Group', test_id: pick_test_id(context, "591855", "592114", "592125", "592136"), priority: pick_priority(context, "1", "2") do
    f('#assignment_order').click
    expect(f("#assignment_order option[value=\"assignment_group\"]")).to be_present
  end

  it 'should sort by Title', test_id: pick_test_id(context, "591856", "592115", "592126", "592137"), priority: pick_priority(context, "1", "2") do
    click_option('#assignment_order', 'Title')

    table_rows = ff('#grades_summary tr')
    title_order.each_with_index do |assign_name, index|
      expect(table_rows[3 * index + 1].find_element(:css, 'th').text).to eq assign_name
    end
  end

  it 'should sort by Due Date', test_id: pick_test_id(context, "591857", "592116", "592127", "592138"), priority: pick_priority(context, "1", "2") do
    click_option('#assignment_order', 'Due Date')

    table_rows = ff('#grades_summary tr')
    due_date_order.each_with_index do |assign_name, index|
      expect(table_rows[3 * index + 1].find_element(:css, 'th').text).to eq assign_name
    end
  end

  it 'should sort by Module', test_id: pick_test_id(context, "591858", "592117", "592128", "592139"), priority: pick_priority(context, "1", "2") do
    click_option('#assignment_order', 'Module')

    table_rows = ff('#grades_summary tr')
    module_order.each_with_index do |assign_name, index|
      expect(table_rows[3 * index + 1].find_element(:css, 'th').text).to eq assign_name
    end
  end

  it 'should sort by Assignment Group', test_id: pick_test_id(context, "591859", "591859", "592129", "592140"), priority: pick_priority(context, "1", "2") do
    click_option('#assignment_order', 'Assignment Group')
    table_rows = ff('#grades_summary tr')

    assign_group_order.each_with_index do |assign_name, index|
      expect(table_rows[3 * index + 1].find_element(:css, 'th').text).to eq assign_name
    end
  end
end

def pick_test_id(context, id1, id2, id3, id4)
  case context
  when 'student'
    id1
  when 'teacher'
    id2
  when 'admin'
    id3
  when 'ta'
    id4
  else
    raise('Error: Invalid context')
  end
end

def pick_priority(context, pri1, pri2)
  case context
  when 'student', 'teacher'
    pri1
  when 'admin', 'ta'
    pri2
  else
    raise('Error: Invalid context')
  end
end

def enroll_context(context)
  case context
  when 'student'
    user_session(@student)

  when 'teacher'
    @teacher = User.create!(name: "Teacher")
    @course.enroll_teacher(@teacher).accept!
    user_session(@teacher)

  when 'admin'
    admin_logged_in

  when 'ta'
    @ta = User.create!(name: "TA")
    @course.enroll_ta(@ta).accept!
    user_session(@ta)

  else
    raise('Error: Invalid context')
  end
end
