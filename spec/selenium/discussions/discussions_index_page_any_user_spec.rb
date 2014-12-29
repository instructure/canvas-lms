require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_examples "in-process server selenium tests"

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:somebody) { student_in_course(course: course, name: 'somebody', active_all: true).user }
  let(:somebody_topic) { course.discussion_topics.create!(user: somebody, title: 'somebody topic title', message: 'somebody topic message') }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: 'teacher entry') }

  context "on the index page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/" }

    context "as anyone" do # we actually use a student, but the idea is that it would work the same for a teacher or anyone else
      before(:each) do
        user_session(somebody)
      end

      let(:topic) { somebody_topic }

      it "should start a new topic" do
        get url
        expect_new_page_load { f('.btn-primary').click }
        edit('new topic title', 'new topic')
      end

      context "with blank pages fetched from server" do
        it "should display empty version of view if there are no topics" do
          get url
          wait_for_ajaximations
          ff('.no-content').each { |div| expect(div).to be_displayed }
        end

        it "should display topics even if first page is blank but later pages have data" do
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
          wait_for_ajaximations
          expect(f('.btn-large')).to be_nil
        end
      end

      describe "subscription icon" do
        it "should allow subscribing to a topic" do
          topic.unsubscribe(somebody)
          get(url)
          wait_for_ajaximations
          expect(f('.icon-discussion')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          expect(f('.icon-discussion')).to be_nil
          expect(f('.icon-discussion-check')).to be_displayed
          topic.reload
          expect(topic.subscribed?(somebody)).to be_truthy
        end

        it "should allow unsubscribing from a topic" do
          topic.subscribe(somebody)
          get(url)
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          expect(f('.icon-discussion-check')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          expect(f('.icon-discussion-check')).to be_nil
          expect(f('.icon-discussion')).to be_displayed
          topic.reload
          expect(topic.subscribed?(somebody)).to be_falsey
        end
      end

      it "should validate the discussion reply counter" do
        topic.reply_from(user: somebody, text: 'entry')

        get url
        expect(f('.total-items').text).to eq '1'
      end

      it "should exclude deleted entries from unread and total reply count" do
        # Add two replies, delete one
        topic.reply_from(:user => teacher, :text => "entry")
        entry = topic.reply_from(:user => teacher, :text => "another entry")
        entry.destroy

        get url
        expect(f('.new-items').text).to eq '1'
        expect(f('.total-items').text).to eq '1'
      end

      describe 'filtering' do
        before(:each) do
          @graded_unread_topic = topic_for_filtering(read: false, graded: true)
          @unread_topic = topic_for_filtering(read: false, graded: false)
          @graded_read_topic = topic_for_filtering(read: true, graded: true)
          @read_topic = topic_for_filtering(read: true, graded: false)
          get url
        end

        it "should filter by assignments" do
          filter(only_graded: true)
          expect(index_is_showing?(@graded_unread_topic, @graded_read_topic)).to be_truthy
        end

        it "should filter by unread" do
          filter(only_unread: true)
          expect(index_is_showing?(@graded_unread_topic, @unread_topic)).to be_truthy
        end

        it "should filter by unread and assignments" do
          filter(only_unread: true, only_graded: true)
          expect(index_is_showing?(@graded_unread_topic)).to be_truthy
        end

        it "should search by title" do
          filter(term: 'ungraded unread topic title')
          expect(index_is_showing?(@unread_topic)).to be_truthy
        end

        it "should search by body" do
          filter(term: 'ungraded read topic message')
          expect(index_is_showing?(@read_topic)).to be_truthy
        end

        it "should search by author" do
          filter(term: 'student')
          expect(index_is_showing?(@read_topic, @unread_topic)).to be_truthy
        end

        it "should return multiple items in the search" do
          filter(term: ' read')
          expect(index_is_showing?(@read_topic, @graded_read_topic)).to be_truthy
        end
      end
    end
  end
end
