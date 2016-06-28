require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

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

      it "should display 100 discussions", priority: "1", test_id: 272278 do
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

      it "should allow teachers to edit discussions settings", priority: "1", test_id: 270950 do
        get url
        f('#edit_discussions_settings').click
        wait_for_ajax_requests
        f('#allow_student_discussion_topics').click
        submit_form('.dialogFormView')
        wait_for_ajax_requests
        course.reload
        expect(course.allow_student_discussion_topics).to eq false
      end

      it "should allow discussions to be dragged around sections", priority: "1", test_id: 150500 do
        teacher_topic
        get url
        expect(f('#open-discussions .discussion-title').text).to include('teacher topic title')
        drag_and_drop_element(fln('teacher topic title'), f('#pinned-discussions'))
        wait_for_ajaximations
        expect(f('#pinned-discussions .discussion-title').text).to include('teacher topic title')
        drag_and_drop_element(fln('teacher topic title'), f('#locked-discussions'))
        wait_for_ajaximations
        expect(f('#locked-discussions .discussion-title').text).to include('teacher topic title')
        expect_new_page_load{fln('teacher topic title').click}
        expect(f('.discussion-fyi').text).to include('This topic is closed for comments')

        # Assert that the teacher can still reply to a closed discussion
        expect(f('.discussion-reply-action')).to be_present

        # Student cannot reply to a closed discussion
        user_session(student)
        get "/courses/#{course.id}/discussion_topics/#{teacher_topic.id}"
        expect(f("#content")).not_to contain_css('.discussion-reply-action')
      end


      describe "publish icon" do
        before(:each) do
        end

        it "should allow publishing a discussion", priority: "1", test_id: 150497 do
          topic.unpublish!
          click_publish_icon topic
          expect(topic.reload.published?).to be_truthy
        end

        it "should allow unpublishing a discussion without replies", priority: "1", test_id: 270952 do
          topic.publish!
          click_publish_icon topic
          expect(topic.reload.published?).to be_falsey
        end

        it "should not allow unpublishing a discussion with replies", priority: "1", test_id: 150498 do
          topic.publish!
          topic.reply_from(user: student, text: 'student reply')
          click_publish_icon topic
          expect(topic.reload.published?).to be_truthy
        end

        it "should not allow unpublishing a graded discussion with a submission", priority: "1", test_id: 270953 do
          assignment_topic.publish!
          assignment_topic.reply_from(user: student, text: 'student reply submission')
          click_publish_icon assignment_topic
          expect(assignment_topic.reload.published?).to be_truthy
        end
      end

      describe "gear menu" do

        it "should give the teacher delete/lock permissions on all topics", priority: "1", test_id: 150499 do
          student_topic
          check_permissions(DiscussionTopic.count)
        end

        it "should allow a teacher to pin a topic", priority: "1", test_id: 150501 do
          topic
          get(url)

          f('.open.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          expect(topic.reload).to be_pinned
          expect(topic.position).not_to be_nil
          expect(ffj('.pinned.discussion-list li.discussion:visible').length).to eq 1
        end

        it "should allow a teacher to unpin a topic", priority: "1", test_id: 270954 do
          assignment_topic.pinned = true
          assignment_topic.save!
          get(url)

          f('.pinned.discussion-list .al-trigger').click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          expect(assignment_topic.reload).not_to be_pinned
          expect(ffj('.open.discussion-list li.discussion:visible').length).to eq 1
        end

        it "should allow pinning of all pages of topics", priority: "1", test_id: 270955 do
          100.times do |n|
            DiscussionTopic.create!(context: course, user: teacher,
                                    title: "Discussion Topic #{n+1}")
          end
          topic = DiscussionTopic.where(context_id: course.id).order('id DESC').last
          expect(topic).not_to be_pinned
          get(url)
          fj("[data-id=#{topic.id}] .al-trigger").click
          fj('.icon-pin:visible').click
          wait_for_ajaximations
          expect(topic.reload).to be_pinned
        end

        it "should allow locking a pinned topic", priority: "1", test_id: 270956 do
          topic.pinned = true
          topic.save!
          get(url)

          f('.pinned.discussion-list .al-trigger').click
          fj('.icon-lock:visible').click
          wait_for_ajaximations
          f('.locked.discussion-list .al-trigger').click
          expect(fj('.icon-pin:visible')).to include_text('Pin')
        end

        it "should allow pinning a locked topic", priority: "1", test_id: 270957 do
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

        it "should delete a topic", priority: "1", test_id: 150502 do
          topic
          get url

          f('.al-trigger').click
          fj('.icon-trash:visible').click
          driver.switch_to.alert.accept
          wait_for_ajaximations
          expect(topic.reload.workflow_state).to eq 'deleted'
          expect(f("#content")).not_to contain_css('.discussion-list li.discussion')
        end

        it "should restore a deleted topic with replies", priority: "2", test_id: 927756 do
          topic.reply_from(user: student, text: 'student reply')
          topic.workflow_state = "deleted"
          topic.save!
          get "/courses/#{@course.id}/undelete"
          expect(f('#deleted_items_list').text).to include('teacher topic title')
          hover_and_click('.restore_link')
          driver.switch_to.alert.accept
          wait_for_ajaximations
          get url
          expect(f('#open-discussions .discussion-title').text).to include('teacher topic title')
          fln('teacher topic title').click
          expect(ff('.discussion-entries .entry').count).to eq(1)
        end

        it "should sort the discussions", priority: "1", test_id: 150509 do
          topics = 4.times.map do |n|
            DiscussionTopic.create!(context: course, user: teacher,
                                    title: "Discussion Topic #{n+1}", pinned: true)
          end
          expect(topics.map(&:position)).to eq [1, 2, 3, 4]
          get url

          3.times do |n|
            topic = topics[2-n]
            fj("[data-id=#{topic.id}] .al-trigger").click
            fj('.icon-updown:visible').click
            click_option '.ui-dialog:visible select', "-- At the bottom --"
            fj('.ui-dialog:visible .btn-primary').click
            wait_for_ajaximations
            topics.each(&:reload)
          end
          expect(topics.map(&:position)).to eq [4, 3, 2, 1]
        end

        it "should allow moving a topic", priority: "1", test_id: 270958 do
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
