require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

shared_examples_for "course copy" do
  before :once do
    course_with_teacher(:course_name => "from course", :active_all => true)
    @copy_from = @course

    course_with_teacher(:user => @user, :course_name => "tocourse", :course_code => "tocourse")
    @copy_to = @course

    @cm = ContentMigration.new(
      :context => @copy_to,
      :user => @user,
      :source_course => @copy_from,
      :migration_type => 'course_copy_importer',
      :copy_options => {:everything => "1"}
    )
    @cm.migration_settings[:import_immediately] = true
    @cm.save!
  end

  def run_course_copy(warnings=[])
    @cm.set_default_settings
    worker = Canvas::Migration::Worker::CourseCopyWorker.new
    worker.perform(@cm)
    @cm.reload
    if @cm.migration_settings[:last_error]
      er = ErrorReport.last
      "#{er.message} - #{er.backtrace}".should == ""
    end
    @cm.warnings.should == warnings
    @cm.workflow_state.should == 'imported'
    @copy_to.reload
  end

  def make_grading_standard(context, opts = {})
    gs = context.grading_standards.new
    gs.title = opts[:title] || "Standard eh"
    gs.data = [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
    gs.save!
    gs
  end

  def mig_id(obj)
    CC::CCHelper.create_key(obj)
  end

  def create_outcome(context, group=nil)
    lo = LearningOutcome.new
    lo.context = context
    lo.short_description = "haha_#{rand(10_000)}"
    lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}], :description=>"First outcome", :points_possible=>5}}
    lo.save!
    if group
      group.add_outcome(lo)
    elsif context
      context.root_outcome_group.add_outcome(lo)
    end

    lo
  end

  def create_rubric_asmnt
    @rubric = @copy_from.rubrics.new
    @rubric.title = "Rubric"
    @rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5.5, :description=>"Full Marks", :id=>"blank", :long_description=>""}, {:criterion_id=>"309_6312", :points=>0, :description=>"No Marks", :id=>"blank_2", :long_description=>""}], :points=>5.5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}]
    @rubric.save!

    @assignment = @copy_from.assignments.create!(:title => "some assignment", :points_possible => 12)
    @assoc = @rubric.associate_with(@assignment, @copy_from, :purpose => 'grading', :use_for_grading => true)
    @assoc.hide_score_total = true
    @assoc.use_for_grading = true
    @assoc.save!
  end
end
