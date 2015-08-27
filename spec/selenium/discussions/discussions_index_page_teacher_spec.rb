require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_examples "in-process server selenium tests"

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: 'student topic title', message: 'student topic message') }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: 'teacher topic title', message: 'teacher topic message') }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:assignment) { course.assignments.create!(
      name: 'assignment',
      #submission_types: 'discussion_topic',
      assignment_group: assignment_group
  ) }
  let(:assignment_topic) do
    course.discussion_topics.create!(user: teacher,
                                     title: 'assignment topic title',
                                     message: 'assignment topic message',
                                     assignment: assignment)
  end

  context "on the index page" do
  let(:url) { "/courses/#{course.id}/discussion_topics/" }

    context "as a teacher" do
      let(:topic) {teacher_topic}

      before(:each) do
        user_session(teacher)
      end

      it "should display 100 discussions" do
        #Setup: Creates 100 discussion topics
        1.upto(100) do |n|
          DiscussionTopic.create!(context: course, user: teacher,
                                  title: "Discussion Topic #{n}")
        end

        get url

        #Validate: Makes sure each topic is listed.
        #Since topics are displayed in reverse order from creation (i.e. 100 is listed first), we use the topic index [100-n]
        # to get the correct title
        discussions_topics = ff('.title')
        100.times do |n|
          topic_index = 100-n
          expect(discussions_topics[n]).to include_text("Discussion Topic #{topic_index}")
        end
      end

      it "should allow teachers to edit discussions settings" do
        get url
        f('#edit_discussions_settings').click
        wait_for_ajax_requests
        f('#allow_student_discussion_topics').click
        submit_form('.dialogFormView')
        wait_for_ajax_requests
        course.reload
        expect(course.allow_student_discussion_topics).to eq false
      end

      describe "publish icon" do
        before(:each) do
        end

        it "should allow publishing a discussion" do
          topic.unpublish!
          click_publish_icon topic
          expect(topic.reload.published?).to be_truthy
        end

        it "should allow unpublishing a discussion without replies" do
          topic.publish!
          click_publish_icon topic
          expect(topic.reload.published?).to be_falsey
        end

        it "should not allow unpublishing a discussion with replies" do
          topic.publish!
          topic.reply_from(user: student, text: 'student reply')
          click_publish_icon topic
          expect(topic.reload.published?).to be_truthy
        end

        it "should not allow unpublishing a graded discussion with a submission" do
          assignment_topic.publish!
          assignment_topic.reply_from(user: student, text: 'student reply submission')
          click_publish_icon assignment_topic
          expect(assignment_topic.reload.published?).to be_truthy
        end
      end

      describe "gear menu" do

        it "should give the teacher delete/lock permissions on all topics" do
          student_topic
          check_permissions(DiscussionTopic.count)
        end

        it "should allow a teacher to pin a topic" do
          topic
          get(url)

          f('.open.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          expect(topic.reload).to be_pinned
          expect(topic.position).not_to be_nil
          expect(ffj('.pinned.discussion-list li.discussion:visible').length).to eq 1
        end

        it "should allow a teacher to unpin a topic" do
          assignment_topic.pinned = true
          assignment_topic.save!
          get(url)

          f('.pinned.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          expect(assignment_topic.reload).not_to be_pinned
          expect(ffj('.open.discussion-list li.discussion:visible').length).to eq 1
        end

        it "should allow pinning of all pages of topics" do
          100.times do |n|
            DiscussionTopic.create!(context: course, user: teacher,
                                    title: "Discussion Topic #{n+1}")
          end
          topic = DiscussionTopic.where(context_id: course.id).order('id DESC').last
          expect(topic).not_to be_pinned
          get(url)
          keep_trying_until { fj(".al-trigger") }
          fj("[data-id=#{topic.id}] .al-trigger").click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          expect(topic.reload).to be_pinned
        end



        it "should allow locking a pinned topic" do
          topic.pinned = true
          topic.save!
          get(url)

          f('.pinned.discussion-list .al-trigger').click
          fj('.icon-lock:visible').click
          wait_for_ajaximations
          f('.locked.discussion-list .al-trigger').click
          expect(fj('.icon-pin:visible')).to include_text('Pin')
        end

        it "should allow pinning a locked topic" do
          topic.lock!
          get(url)

          f('.locked.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          f('.pinned.discussion-list .al-trigger').click
          expect(fj('.icon-lock:visible')).to include_text('Open')
          fj('.icon-lock:visible').click
          wait_for_ajaximations
          f('.pinned.discussion-list .al-trigger').click
          expect(fj('.icon-lock:visible')).to include_text('Close')
        end

        it "should delete a topic" do
          topic
          get url

          f('.al-trigger').click
          fj('.icon-trash:visible').click
          driver.switch_to.alert.accept
          wait_for_ajaximations
          expect(topic.reload.workflow_state).to eq 'deleted'
          expect(f('.discussion-list li.discussion')).to be_nil
        end

        it "should allow moving a topic" do
          topics = 3.times.map do |n|
            DiscussionTopic.create!(context: course, user: teacher,
                                    title: "Discussion Topic #{n+1}", pinned: true)
          end
          expect(topics.map(&:position)).to eq [1, 2, 3]
          topic = topics[0]
          get url

          fj("[data-id=#{topic.id}] .al-trigger").click
          fj('.icon-updown:visible').click
          click_option '.ui-dialog:visible select', topics[2].title
          fj('.ui-dialog:visible .btn-primary').click
          wait_for_ajaximations
          topics.each &:reload
          expect(topics.map(&:position)).to eq [2, 1, 3]
        end
      end
    end
  end
end
