require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_context "in-process server selenium tests"
  
  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end 

  context 'submission comment stream items' do
    before do
      @course1 = @course
      @course2 = course(active_course: true)
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
    end

    describe 'view filter' do
      it 'shows submission comments', priority: "2", test_id: 197517 do
        get_conversations
        select_view('submission_comments')
        expect(conversation_elements.size).to eq 2
      end

      it 'filters by course', priority: "2", test_id: 197518 do
        get_conversations
        select_view('submission_comments')
        select_course(@course1.id)
        expect(conversation_elements.size).to eq 1
      end

      it 'filters by submitter', priority: "2", test_id: 197519 do
        get_conversations
        select_view('submission_comments')
        name = @s2.name
        f('[role=main] header [role=search] input').send_keys(name)
        keep_trying_until { fj(".ac-result:contains('#{name}')") }.click
        expect(conversation_elements.length).to eq 1
      end
    end

    it 'adds new messages to the view', priority: "2", test_id: 197520 do
      get_conversations
      select_view('submission_comments')
      initial_message_count = @submission.submission_comments.count
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#submission-reply-btn').click
      fj('.reply_body').send_keys('c3')
      fj('.submission-comment-reply-dialog .send-message').click
      wait_for_ajaximations
      expect(ffj('.message-item-view').length).to eq (initial_message_count + 1)
      expect(@submission.reload.submission_comments.count).to eq (initial_message_count + 1)
    end

    it 'marks unread on click', priority: "2", test_id: 197521 do
      expect(@submission.read?(@teacher)).to be_falsey
      get_conversations
      select_view('submission_comments')
      conversation_elements[0].click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_truthy
    end

    it 'marks an read/unread', priority: "2", test_id: 197522 do
      expect(@submission.read?(@teacher)).to be_falsey
      get_conversations
      select_view('submission_comments')
      toggle = fj('.read-state', conversation_elements[0])
      toggle.click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_truthy
      toggle.click
      wait_for_ajaximations
      expect(@submission.read?(@teacher)).to be_falsey
    end
  end
end