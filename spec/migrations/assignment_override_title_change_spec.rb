require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "title" do
  before :once do
    @override = assignment_override_model
  end

  it "should set ADHOC's title to reflect students (with few)" do
    @override.title = "test"
    @override.set_type = "ADHOC"
    override_student = @override.assignment_override_students.build
    override_student.user = student_in_course(course: @override.assignment.context, name: 'Edgar Jones').user
    override_student.save!
    @override.valid? # trigger bookkeeping
    expect(@override.title).to eq 'test'
    DataFixup::AssignmentOverrideTitleChange.run
    @override.reload
    expect(@override.title).to eq '1 student'
  end

  it "should set ADHOC's name to reflect students (with many)" do
    @override.title = "test"
    @override.set_type = "ADHOC"
    ["A Student","B Student","C Student","D Student"].each do |student_name|
      override_student = @override.assignment_override_students.build
      override_student.user = student_in_course(course: @override.assignment.context, name: student_name).user
      override_student.save!
    end
    @override.valid? # trigger bookkeeping
    expect(@override.title).to eq 'test'
    DataFixup::AssignmentOverrideTitleChange.run
    @override.reload
    expect(@override.title).to eq '4 students'
  end
  it "should set ADHOC's title of deleted assignments to reflect students" do
    @override.title = "test"
    @override.set_type = "ADHOC"
    override_student = @override.assignment_override_students.build
    override_student.user = student_in_course(course: @override.assignment.context, name: 'Edgar Jones').user
    @override.workflow_state = "deleted"
    override_student.save!
    @override.valid? # trigger bookkeeping
    expect(@override.title).to eq 'test'
    DataFixup::AssignmentOverrideTitleChange.run
    @override.reload
    expect(@override.title).to eq '1 student'
  end
end
