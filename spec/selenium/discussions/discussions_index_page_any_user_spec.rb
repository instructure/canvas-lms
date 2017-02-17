require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:somebody) { student_in_course(course: course, name: 'somebody', active_all: true).user }
  let(:somebody_topic) { course.discussion_topics.create!(user: somebody, title: 'somebody topic title', message: 'somebody topic message') }
  let(:group_topic) { group_discussion_assignment }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: 'teacher entry') }

  context "on the index page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/" }

    context "as anyone" do # we actually use a student, but the idea is that it would work the same for a teacher or anyone else
      before(:each) do
        user_session(somebody)
      end

      let(:topic) { somebody_topic }

      it "should start a new topic", priority: "1", test_id: 140669 do
        get url
        expect_new_page_load { f('.btn-primary').click }
        edit('new topic title', 'new topic')
      end

      context "with blank pages fetched from server" do
        it "should display empty version of view if there are no topics", priority: "2", test_id: 270930 do
          get url
          ff('.no-content').each { |div| expect(div).to be_displayed }
        end

        it "should display topics even if first page is blank but later pages have data", priority: "2", test_id: 270931 do
          # topics that should be visible
          (1..5).each do |n|
            course.discussion_topics.create!({
                                                 :title => "general topic #{n}",
                                                 :discussion_type => 'side_comment',
                                             })
          end
          # a page worth of invisible topics
          (6..15).each do |n|
            course.discussion_topics.create!({
                                                 :title => "general topic #{n}",
                                                 :discussion_type => 'side_comment',
                                                 :delayed_post_at => 5.days.from_now,
                                             })
          end
          get url
          expect(f("#content")).not_to contain_css('.btn-large')
        end
      end

      describe "subscription icon" do

        it "should allow subscribing to a topic", priority: "1", test_id: 270931 do
          topic.unsubscribe(somebody)
          get(url)
          wait_for_subscription_icon_to_load("icon-discussion")
          expect(f('.icon-discussion')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          wait_for_subscription_icon_to_load("icon-discussion-check")
          expect(f("#content")).not_to contain_css('.icon-discussion')
          expect(f('.icon-discussion-check')).to be_displayed
          topic.reload
          expect(topic.subscribed?(somebody)).to be_truthy
        end

        it "should allow unsubscribing from a topic", priority: "1", test_id: 270932 do
          topic.subscribe(somebody)
          get(url)
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          wait_for_subscription_icon_to_load('icon-discussion-check')
          expect(f('.icon-discussion-check')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          wait_for_subscription_icon_to_load('icon-discussion')
          expect(f("#content")).not_to contain_css('.icon-discussion-check')
          expect(f('.icon-discussion')).to be_displayed
          topic.reload
          expect(topic.subscribed?(somebody)).to be_falsey
        end
      end

      it "should validate the discussion reply counter", priority: "1", test_id: 150504 do
        topic.reply_from(user: somebody, text: 'entry')

        get url
        expect(f('.total-items').text).to eq '1'
      end

      it "should exclude deleted entries from unread and total reply count", priority: "1", test_id: 270933 do
        # Add two replies, delete one
        topic.reply_from(:user => teacher, :text => "entry")
        entry = topic.reply_from(:user => teacher, :text => "another entry")
        entry.destroy

        get url
        expect(f('.new-items').text).to eq '1'
        expect(f('.total-items').text).to eq '1'
      end

      it "hides unread count for group discussions" do
        group_topic
        get url
        expect(f(".discussion-unread-status").text).to eq ''
      end

      describe 'filtering' do
        before(:each) do
          @graded_unread_topic = topic_for_filtering(read: false, graded: true)
          @unread_topic = topic_for_filtering(read: false, graded: false)
          @graded_read_topic = topic_for_filtering(read: true, graded: true)
          @read_topic = topic_for_filtering(read: true, graded: false)
          get url
        end

        it "should filter by assignments", priority: "1", test_id: 270934 do
          filter(only_graded: true)
          expect(index_is_showing?(@graded_unread_topic, @graded_read_topic)).to be_truthy
        end

        it "should filter by unread", priority: "1", test_id: 270935 do
          filter(only_unread: true)
          expect(index_is_showing?(@graded_unread_topic, @unread_topic)).to be_truthy
        end

        it "should filter by unread and assignments", priority: "1", test_id: 270936 do
          filter(only_unread: true, only_graded: true)
          expect(index_is_showing?(@graded_unread_topic)).to be_truthy
        end

        it "should search by title", priority: "1", test_id: 270937 do
          filter(term: 'ungraded unread topic title')
          expect(index_is_showing?(@unread_topic)).to be_truthy
        end

        it "should search by body", priority: "1", test_id: 270938 do
          filter(term: 'ungraded read topic message')
          expect(index_is_showing?(@read_topic)).to be_truthy
        end

        it "should search by author", priority: "1", test_id: 270939 do
          filter(term: 'student')
          expect(index_is_showing?(@read_topic, @unread_topic)).to be_truthy
        end

        it "should return multiple items in the search", priority: "1", test_id: 270940 do
          filter(term: ' read')
          expect(index_is_showing?(@read_topic, @graded_read_topic)).to be_truthy
        end
      end

      it "should have working unread button", priority: "1", test_id: 150506 do
        disc1 = @course.discussion_topics.create!(user: teacher, title: 'Philip', message: 'teacher topic message')
        disc2 = @course.discussion_topics.create!(user: teacher, title: 'Fry', message: 'teacher topic message')
        disc1.discussion_entries.create(message: "first entry", user: @user)
        get url

        # verify that both discussions are present as well as the other 2 empty sections
        expect(ffj('.discussion:visible').size).to eq 3

        # going to this page once will let it be filtered as unread
        get "/courses/#{course.id}/discussion_topics/#{disc2.id}"
        get url

        fj('label.ui-button.ui-widget.ui-state-default.ui-button-text-only.ui-corner-left').click
        expect(ffj('.discussion:visible').size).to eq 2
      end

      it "should have working unread button", priority: "1", test_id: 150505 do
        @course.discussion_topics.create!(user: teacher, title: 'Philip J. Fry', message: 'teacher topic message')
        assignment = @course.assignments.create(title: "discussion assignment", points_possible: 20)
        @course.discussion_topics.create!(user: teacher, title: 'Fry', message: 'teacher topic message', assignment: assignment)
        get url

        # verify that both discussions are present as well as the other empty section
        expect(ffj('.discussion:visible').size).to eq 3

        fj('label.ui-button.ui-widget.ui-state-default.ui-button-text-only.ui-corner-right:').click
        expect(ffj('.discussion:visible').size).to eq 2
      end
    end
  end
end
