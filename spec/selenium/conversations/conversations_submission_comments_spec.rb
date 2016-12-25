require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')
require_relative '../helpers/shared_examples_common'
include SharedExamplesCommon

describe "conversations new" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  context 'submission comment stream items' do
    before do
      @course1 = @course
      @course2 = course_factory(active_course: true)
      teacher_in_course(user: @teacher, course: @course2, active_all: true)
      student_in_course(user: @s1, active_all: true, course: @course1)
      student_in_course(user: @s2, active_all: true, course: @course2)

      def assignment_with_submission_comments(title, student, course)
        assignment = course.assignments.create!(:title => title, :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
        sub = assignment.grade_student(student, { :grade => '12', :grader => @teacher}).first
        sub.workflow_state = 'submitted'
        sub.submission_comments.create!(:comment => 'c1', :author => @teacher, :recipient_id => student.id)
        sub.submission_comments.create!(:comment => 'c2', :author => student, :recipient_id => @teacher.id)
        sub.save!
        sub
      end

      assignment_with_submission_comments('assignment 1', @s1, @course1)
      @submission = assignment_with_submission_comments('assignment 2', @s2, @course2)
      conversations
      select_view('submission_comments')
    end

    describe 'view filter' do
      it 'shows submission comments', priority: "2", test_id: 197517 do
        expect(conversation_elements.size).to eq 2
      end

      it 'filters by course', priority: "2", test_id: 197518 do
        select_course(@course1.id)
        expect(conversation_elements.size).to eq 1
      end

      it 'filters by submitter', priority: "2", test_id: 197519 do
        name = @s2.name
        f('[role=main] header [role=search] input').send_keys(name)
        fj(".ac-result:contains('#{name}')").click
        expect(conversation_elements.length).to eq 1
      end
    end

    it 'adds new messages to the view', priority: "2", test_id: 197520 do
      initial_message_count = @submission.submission_comments.count
      conversation_elements[0].click
      wait_for_ajaximations
      reply_to_submission_comment
      expect(ffj('.message-item-view').length).to eq (initial_message_count + 1)
      expect(@submission.reload.submission_comments.count).to eq (initial_message_count + 1)
    end

    it 'marks unread on click', priority: "2", test_id: 197521 do
      expect(@submission.read?(@teacher)).to be_falsey
      conversation_elements[0].click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_truthy
    end

    it 'marks an read/unread', priority: "2", test_id: 197522 do
      expect(@submission.read?(@teacher)).to be_falsey
      toggle = fj('.read-state', conversation_elements[0])
      toggle.click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_truthy
      toggle.click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_falsey
    end

    shared_examples 'shows submission comments' do |context|
      before :each do
        case context
        when :student
          user_session(@s2)
        when :teacher
          user_session(@teacher)
        end

        conversation_elements[0].click
      end

      it "shows submission comments in submissions page and inbox", priority: "2", test_id: pick_test_id(context, student: "122983", teacher: "2634986") do
        expect(@submission.submission_comments.count).to eq(2)
        expect(ff('.message-content > li').size).to eq(2)
      end

      it 'shows only the reply button', priority: "2", test_id: pick_test_id(context, student: "2642300", teacher: "2642302")  do
        # make sure there is no cog menu
        expect(f('.message-detail-actions')).not_to contain_css('.inline-block')
        expect(f('#submission-reply-btn')).to be_present
      end

      it 'should show replies in the submission comments', priority: "2", test_id: pick_test_id(context, student: "2642301", teacher: "2642303") do
        reply_to_submission_comment
        expect(ffj('.message-item-view').length).to eq (3)
        expect(@submission.submission_comments.count).to eq(3)
      end
    end

    it_behaves_like 'shows submission comments', :student
    it_behaves_like 'shows submission comments', :teacher
  end
end
