require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe "Api::V1::CustomGradebookColumn" do
  let(:controller) { CustomGradebookColumnsApiController.new }

  before do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @col = @course.custom_gradebook_columns.create! title: "blah", position: 2
    @datum = @col.custom_gradebook_column_data.build(content: "asdf").tap { |d|
      d.user_id = @student.id
    }
  end

  describe "custom_gradebook_column_json" do
    it "works" do
      controller.custom_gradebook_column_json(@col, @teacher, nil).should ==
        @col.attributes.slice(*%w(id title position))
    end
  end

  describe "custom_gradebook_column_json" do
    it "works" do
      controller.custom_gradebook_column_datum_json(@datum, @teacher, nil)
      .should == @datum.attributes.slice(*%w(user_id content))
    end
  end
end
