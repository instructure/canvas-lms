require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

require 'nokogiri'

describe "discussions" do
  include_examples "in-process server selenium tests"

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:somebody) { student_in_course(course: course, name: 'somebody', active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: 'student topic title', message: 'student topic message') }
  let(:somebody_topic) { course.discussion_topics.create!(user: somebody, title: 'somebody topic title', message: 'somebody topic message') }
  let(:side_comment_topic) do
    t = course.discussion_topics.create!(user: somebody, title: 'side comment topic title', message: 'side comment topic message')
    t.discussion_entries.create!(user: somebody, message: 'side comment topic entry message')
    t
  end
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: 'teacher entry') }

  context "on the show page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/" }

    context "as anyone"  do
      let(:topic) { somebody_topic }

      before(:each) do
        user_session(somebody)
      end

      context "marking as read" do
        # TODO: trim this
        it "should automatically mark things as read" do
          resize_screen_to_default

          reply_count = 2
          reply_count.times { topic.discussion_entries.create!(:message => 'Lorem ipsum dolor sit amet', :user => student) }
          topic.create_materialized_view

          # make sure everything looks unread
          get url
          expect(ff('.discussion_entry.unread').length).to eq reply_count
          expect(f('.new-and-total-badge .new-items').text).to eq reply_count.to_s

          #wait for the discussionEntryReadMarker to run, make sure it marks everything as .just_read
          driver.execute_script("$('.entry-content').last().get(0).scrollIntoView()")
          keep_trying_until { expect(ff('.discussion_entry.unread')).to be_empty }
          expect(ff('.discussion_entry.read').length).to eq reply_count + 1 # +1 because the topic also has the .discussion_entry class

          # refresh page and make sure nothing is unread and everthing is .read
          get url
          expect(ff(".discussion_entry.unread")).to be_empty
          expect(f('.new-and-total-badge .new-items').text).to eq ''

          # Mark one as unread manually, and create a new reply. The new reply
          # should be automarked as read, but the manual one should not.
          f('.discussion-read-state-btn').click
          wait_for_ajaximations
          topic.discussion_entries.create!(:message => 'new lorem ipsum', :user => student)
          topic.create_materialized_view

          get url
          expect(ff(".discussion_entry.unread").size).to eq 2
          expect(f('.new-and-total-badge .new-items').text).to eq '2'

          driver.execute_script("$('.entry-content').last().get(0).scrollIntoView()")
          keep_trying_until { ff('.discussion_entry.unread').size < 2 }
          wait_for_ajaximations
          expect(ff(".discussion_entry.unread").size).to eq 1
        end

        it "should mark all as read" do
          reply_count = 8
          (reply_count / 2).times do |n|
            entry = topic.reply_from(:user => student, :text => "entry #{n}")
            entry.reply_from(:user => student, :text => "sub reply #{n}")
          end
          topic.create_materialized_view

          # so auto mark as read won't mess up this test
          somebody.preferences[:manual_mark_as_read] = true
          somebody.save!

          get url

          expect(ff('.discussion-entries .unread').length).to eq reply_count
          expect(ff('.discussion-entries .read').length).to eq 0

          f("#discussion-managebar .al-trigger").click
          f('.mark_all_as_read').click
          wait_for_ajaximations
          expect(ff('.discussion-entries .unread').length).to eq 0
          expect(ff('.discussion-entries .read').length).to eq reply_count
        end
      end

      context "topic subscription" do
        it "should load with the correct status represented" do
          topic.subscribe(somebody)
          topic.create_materialized_view

          get url
          expect(f('.topic-unsubscribe-button')).to be_displayed
          expect(f('.topic-subscribe-button')).not_to be_displayed

          topic.unsubscribe(somebody)
          topic.update_materialized_view
          get url
          wait_for_ajaximations
          expect(f('.topic-unsubscribe-button')).not_to be_displayed
          expect(f('.topic-subscribe-button')).to be_displayed
        end

        it "should unsubscribe from topic" do
          topic.subscribe(somebody)
          topic.create_materialized_view

          get url
          f('.topic-unsubscribe-button').click
          wait_for_ajaximations
          topic.reload
          expect(topic.subscribed?(somebody)).to eq false
        end

        it "should subscribe to topic" do
          topic.unsubscribe(somebody)
          topic.create_materialized_view

          get url
          f('.topic-subscribe-button').click
          wait_for_ajaximations
          topic.reload
          expect(topic.subscribed?(somebody)).to eq true
        end

        it "should prevent subscribing when a student post is required first" do
          new_student_entry_text = 'new student entry'
          topic.require_initial_post = true
          topic.save
          get url
          # shouldn't see subscribe button until after posting
          expect(f('.topic-subscribe-button')).not_to be_displayed
          add_reply new_student_entry_text
          # now the subscribe button should be available.
          get url
          wait_for_ajax_requests
          # already subscribed because they posted
          expect(f('.topic-unsubscribe-button')).to be_displayed
        end

        context "someone else's topic" do
          let(:topic) { student_topic }

          it "should update subscribed button when user posts to a topic" do
            get url
            expect(f('.topic-subscribe-button')).to be_displayed
            add_reply "student posting"
            expect(f('.topic-unsubscribe-button')).to be_displayed
          end
        end
      end

      it "should embed user content in an iframe" do
        message = %{<p><object width="425" height="350" data="http://www.example.com/swf/software/flash/about/flash_animation.swf" type="application/x-shockwave-flash</object></p>"}
        topic.discussion_entries.create!(:user => nil, :message => message)
        get url
        expect(f('#content object')).not_to be_present
        iframe = f('#content iframe.user_content_iframe')
        expect(iframe).to be_present
        # the sizing isn't exact due to browser differences
        expect(iframe.size.width).to be_between(405, 445)
        expect(iframe.size.height).to be_between(330, 370)
        form = f('form.user_content_post_form')
        expect(form).to be_present
        expect(form['target']).to eq iframe['name']
        in_frame(iframe) do
          keep_trying_until do
            src = driver.page_source
            doc = Nokogiri::HTML::DocumentFragment.parse(src)
            obj = doc.at_css('body object')
            expect(obj.name).to eq 'object'
            expect(obj['data']).to eq "http://www.example.com/swf/software/flash/about/flash_animation.swf"
          end
        end
      end

      it "should strip embed tags inside user content object tags" do
        # this avoids the js translation of user content trying to embed the same content twice
        message = %{<object width="560" height="315"><param name="movie" value="http://www.youtube.com/v/VHRKdpR1E6Q?version=3&amp;hl=en_US"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/VHRKdpR1E6Q?version=3&amp;hl=en_US" type="application/x-shockwave-flash" width="560" height="315" allowscriptaccess="always" allowfullscreen="true"></embed></object>}
        topic.discussion_entries.create!(:user => nil, :message => message)
        get url
        expect(f('#content object')).not_to be_present
        expect(f('#content embed')).not_to be_present
        iframe = f('#content iframe.user_content_iframe')
        expect(iframe).to be_present
        forms = ff('form.user_content_post_form')
        expect(forms.size).to eq 1
        form = forms.first
        expect(form['target']).to eq iframe['name']
      end

      it "should still show entries without users" do
        topic.discussion_entries.create!(:user => nil, :message => 'new entry from nobody')
        get url
        wait_for_ajax_requests
        expect(f('#content')).to include_text('new entry from nobody')
      end

      it "should display the current username when adding a reply" do
        get url
        expect(get_all_replies.count).to eq 0
        add_reply
        expect(get_all_replies.count).to eq 1
        expect(@last_entry.find_element(:css, '.author').text).to eq somebody.name
      end

      it "should not show discussion creation time" do
        get url
        expect(f("#discussion_topic time")).to be_nil
      end

      it "should show attachments after showing hidden replies" do
        entry = topic.discussion_entries.create!(:user => somebody, :message => 'blah')
        replies = []
        11.times do
          attachment = course.attachments.create!(:context => course, :filename => "text.txt", :user => somebody, :uploaded_data => StringIO.new("testing"))
          reply = entry.discussion_subentries.create!(
              :user => somebody, :message => 'i haz attachments', :discussion_topic => topic, :attachment => attachment)
          replies << reply
        end
        topic.create_materialized_view
        get url
        expect(ffj('.comment_attachments').count).to eq 10
        fj('.showMore').click
        wait_for_ajaximations
        expect(ffj('.comment_attachments').count).to eq replies.count
      end

      context "side comments" do
        let(:topic) { side_comment_topic }

        it "should add a side comment" do
          side_comment_text = 'new side comment'
          get url

          f('.discussion-entries .discussion-reply-action').click
          wait_for_ajaximations
          type_in_tiny 'textarea', side_comment_text
          submit_form('.discussion-entries .discussion-reply-form')
          wait_for_ajaximations

          last_entry = DiscussionEntry.last
          expect(last_entry.depth).to eq 2
          expect(last_entry.message).to include_text(side_comment_text)
          keep_trying_until do
            expect(f("#entry-#{last_entry.id}")).to include_text(side_comment_text)
          end
        end

        it "should create multiple side comments but only show 10 and expand the rest" do
          side_comment_number = 11
          side_comment_number.times { |i| topic.discussion_entries.create!(:user => student, :message => "new side comment #{i} from student", :parent_entry => entry) }
          get url
          expect(DiscussionEntry.last.depth).to eq 2
          keep_trying_until do
            expect(ff('.discussion-entries .entry').count).to eq 12 # +1 because of the initial entry
          end
          f('.showMore').click
          expect(ff('.discussion-entries .entry').count).to eq(side_comment_number + 2) # +1 because of the initial entry, +1 because of the parent entry
        end

        it "should delete a side comment" do
          entry = topic.discussion_entries.create!(:user => somebody, :message => "new side comment from somebody", :parent_entry => entry)
          get url
          delete_entry(entry)
        end

        it "should edit a side comment" do
          edit_text = 'this has been edited '
          text = "new side comment from somebody"
          entry = topic.discussion_entries.create!(:user => somebody, :message => text, :parent_entry => entry)
          expect(topic.discussion_entries.last.message).to eq text
          get url
          keep_trying_until do
            validate_entry_text(entry, text)
          end
          edit_entry(entry, edit_text)
        end

        it "should put order by date, descending"
        it "should flatten threaded replies into their root entries"
        it "should show the latest three entries"
        it "should deep link to an entry rendered on the first page"
        it "should deep link to an entry rendered on a different page"
        it "should deep link to a non-rendered child entry of a rendered parent"
        it "should deep link to a child entry of a non-rendered parent"
      end
    end
  end
end
