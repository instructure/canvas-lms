#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

require 'nokogiri'

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

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
      let(:topic_participant) { topic.discussion_topic_participants.find_by(user: somebody) }

      before(:each) do
        user_session(somebody)
      end

      context "marking as read" do
        # TODO: trim this
        it "should automatically mark things as read", priority: "2", test_id: 345027 do
          resize_screen_to_default

          reply_count = 2
          reply_count.times { topic.discussion_entries.create!(:message => 'Lorem ipsum dolor sit amet', :user => student) }
          topic.update_materialized_view

          # make sure everything looks unread
          get url
          expect(ff('.discussion_entry.unread').length).to eq reply_count
          expect(f('.new-and-total-badge .new-items').text).to eq reply_count.to_s

          #wait for the discussionEntryReadMarker to run, make sure it marks everything as .just_read
          scroll_into_view ".entry-content:last"
          expect(f("#content")).not_to contain_css('.discussion_entry.unread')
          expect(ff('.discussion_entry.read')).to have_size reply_count + 1 # +1 because the topic also has the .discussion_entry class
          expect { topic_participant.reload.unread_entry_count }.to become(0) # ajax requests are kicked off after UI changes; make sure they complete

          # refresh page and make sure nothing is unread and everthing is .read
          get url
          expect(f("#content")).not_to contain_css('.discussion_entry.unread')
          expect(f('.new-and-total-badge .new-items').text).to eq ''

          # Mark one as unread manually, and create a new reply. The new reply
          # should be automarked as read, but the manual one should not.
          f('.discussion-read-state-btn').click
          wait_for_ajaximations
          topic.discussion_entries.create!(:message => 'new lorem ipsum', :user => student)
          topic.update_materialized_view

          get url
          expect(ff(".discussion_entry.unread")).to have_size(2)
          expect(f('.new-and-total-badge .new-items')).to include_text('2')

          scroll_into_view '.entry-content:last'
          expect(ff('.discussion_entry.unread')).to have_size(1)
        end

        it "should mark all as read", priority: "1", test_id: 150488 do
          reply_count = 8
          (reply_count / 2).times do |n|
            entry = topic.reply_from(:user => student, :text => "entry #{n}")
            entry.reply_from(:user => student, :text => "sub reply #{n}")
          end
          topic.update_materialized_view

          # so auto mark as read won't mess up this test
          somebody.preferences[:manual_mark_as_read] = true
          somebody.save!

          get url

          expect(ff('.discussion-entries .unread').length).to eq reply_count
          expect(f("#content")).not_to contain_css('.discussion-entries .read')

          f("#discussion-managebar .al-trigger").click
          f('.mark_all_as_read').click
          wait_for_ajaximations
          expect(f('.discussion-entries')).not_to contain_css('.unread')
          expect(ff('.discussion-entries .read').length).to eq reply_count
        end

        it "should manually mark reply as read", priority: "1", test_id: 150483 do
          topic.discussion_entries.create!(message: 'Lorem ipsum dolor sit amet', user: student)
          topic.update_materialized_view
          get url
          expect(f('.new-and-total-badge .new-items').text).to eq('1')
          f('.discussion-read-state').click
          refresh_page
          expect(f('.new-and-total-badge .new-items').text).to eq('')
          expect(f('.new-and-total-badge .total-items').text).to eq('1')
        end
      end

      context "topic subscription" do
        it "should load with the correct status represented", priority: "2", test_id: 345028 do
          topic.subscribe(somebody)
          topic.update_materialized_view

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

        it "should unsubscribe from topic", priority: "1", test_id: 345482 do
          topic.subscribe(somebody)
          topic.update_materialized_view

          get url
          f('.topic-unsubscribe-button').click
          wait_for_ajaximations
          topic.reload
          expect(topic.subscribed?(somebody)).to eq false
        end

        it "should subscribe to topic", priority: "1", test_id: 150474 do
          topic.unsubscribe(somebody)
          topic.update_materialized_view

          get url
          f('.topic-subscribe-button').click
          wait_for_ajaximations
          topic.reload
          expect(topic.subscribed?(somebody)).to eq true
        end

        context "someone else's topic" do
          let(:topic) { student_topic }

          it "should update subscribed button when user posts to a topic", priority: "2", test_id: 345483 do
            get url
            expect(f('.topic-subscribe-button')).to be_displayed
            add_reply "student posting"
            expect(f('.topic-unsubscribe-button')).to be_displayed
          end
        end
      end

      context "collapse and filter replies" do
        before :each do
          @entry1 = topic.discussion_entries.create!(message: 'Lorem ipsum dolor sit amet', user: somebody)
          @entry2 = topic.discussion_entries.create!(message: 'Reply by teacher', user: teacher)
          topic.update_materialized_view
          get url
        end

        it "should collapse and expand reply", priority: "1", test_id: 150486 do
          f('.entry-content .entry-header .collapse-discussion').click
          wait_for_ajaximations
          expect(f("#content")).not_to contain_jqcss("#entry-#{@entry1.id} .discussion-entry-reply-area .discussion-reply-action:visible")
          f('.entry-content .entry-header .collapse-discussion').click
          wait_for_ajaximations
          expect(fj("#entry-#{@entry1.id} .discussion-entry-reply-area .discussion-reply-action:visible")).to be_present
        end

        it "should show the appropriate replies from the search by option", priority: "1", test_id: 150487 do
          expect(ffj('.discussion-entries .entry:visible').count).to eq(2)
          expect(f('#discussion-search')).to be_present

          replace_content(f('#discussion-search'), 'somebody')
          expect(f("#filterResults .discussion-title")).to include_text('somebody')
          expect(ffj('.discussion-entries .entry:visible')).to have_size(1)

          replace_content(f('#discussion-search'), 'Reply by')
          expect(f("#filterResults .discussion-title")).to include_text('teacher')
          expect(ffj('.discussion-entries .entry:visible')).to have_size(1)
        end

        it "should show unread replies on clicking the unread button", priority: "1", test_id: 150489 do
          expect(f('.new-and-total-badge .new-items')).to include_text('1')
          expect(ffj('.discussion-entries .entry:visible')).to have_size(2)

          # click unread button
          f('.ui-button').click
          wait_for_ajaximations
          expect(f("#filterResults .discussion-title")).to include_text('teacher')
          expect(ffj('.discussion-entries .entry:visible')).to have_size(1)

          # click unread button again
          f('.ui-button').click
          expect(ffj('.discussion-entries .entry:visible')).to have_size(2)
        end

        it "should collapse and expand multiple replies", priority: "1", test_id: 150490 do
          f('#collapseAll').click
          wait_for_ajaximations
          expect(f("#content")).not_to contain_jqcss("#entry-#{@entry1.id} .discussion-entry-reply-area .discussion-reply-action:visible")
          expect(f("#content")).not_to contain_jqcss("#entry-#{@entry2.id} .discussion-entry-reply-area .discussion-reply-action:visible")
          f('#expandAll').click
          wait_for_ajaximations
          expect(fj("#entry-#{@entry1.id} .discussion-entry-reply-area .discussion-reply-action:visible")).to be_present
          expect(fj("#entry-#{@entry2.id} .discussion-entry-reply-area .discussion-reply-action:visible")).to be_present
        end
      end

      it "should embed user content in an iframe", priority: "2", test_id: 345484 do
        message = %{<p><object width="425" height="350" data="http://www.example.com/swf/software/flash/about/flash_animation.swf" type="application/x-shockwave-flash</object></p>"}
        topic.discussion_entries.create!(:user => nil, :message => message)
        get url
        expect(f("#content")).not_to contain_css("object")
        iframe = f('#content iframe.user_content_iframe')
        expect(iframe).to be_present
        # the sizing isn't exact due to browser differences
        expect(iframe.size.width).to be_between(405, 445)
        expect(iframe.size.height).to be_between(330, 370)
        form = f('form.user_content_post_form')
        expect(form).to be_present
        expect(form['target']).to eq iframe['name']
        in_frame(iframe[:name]) do
          keep_trying_until do
            src = driver.page_source
            doc = Nokogiri::HTML::DocumentFragment.parse(src)
            obj = doc.at_css('body object')
            expect(obj.name).to eq 'object'
            expect(obj['data']).to eq "http://www.example.com/swf/software/flash/about/flash_animation.swf"
          end
        end
      end

      it "should not show keyboard shortcut modal during html editing", priority: "2", test_id: 846539 do
        get url
        f('.discussion-reply-action').click
        wait_for_tiny(fj('.discussion-reply-form:visible textarea'))
        fln('HTML Editor').click
        fj('.reply-textarea:visible').send_keys("< , > , ?, /")
        expect(f('.ui-dialog')).not_to be_displayed
      end

      it "should strip embed tags inside user content object tags", priority: "2", test_id: 345485 do
        # this avoids the js translation of user content trying to embed the same content twice
        message = %{<object width="560" height="315"><param name="movie" value="http://www.youtube.com/v/VHRKdpR1E6Q?version=3&amp;hl=en_US"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/VHRKdpR1E6Q?version=3&amp;hl=en_US" type="application/x-shockwave-flash" width="560" height="315" allowscriptaccess="always" allowfullscreen="true"></embed></object>}
        topic.discussion_entries.create!(:user => nil, :message => message)
        get url
        expect(f("#content")).not_to contain_css("object")
        expect(f("#content")).not_to contain_css("embed")
        iframe = f('#content iframe.user_content_iframe')
        expect(iframe).to be_present
        forms = ff('form.user_content_post_form')
        expect(forms.size).to eq 1
        form = forms.first
        expect(form['target']).to eq iframe['name']
      end

      it "should still show entries without users", priority: "1", test_id: 345486 do
        topic.discussion_entries.create!(:user => nil, :message => 'new entry from nobody')
        get url
        wait_for_ajax_requests
        expect(f('#content')).to include_text('new entry from nobody')
      end

      it "should display the current username when adding a reply", priority: "1", test_id: 150485 do
        get url
        expect(f("#content")).not_to contain_css("#discussion_subentries .discussion_entry")
        add_reply
        expect(get_all_replies.count).to eq 1
        expect(@last_entry.find_element(:css, '.author').text).to eq somebody.name
      end

      it "should show attachments after showing hidden replies", priority: "1", test_id: 345487 do
        entry = topic.discussion_entries.create!(:user => somebody, :message => 'blah')
        replies = []
        11.times do
          attachment = course.attachments.create!(:context => course, :filename => "text.txt", :user => somebody, :uploaded_data => StringIO.new("testing"))
          reply = entry.discussion_subentries.create!(
              :user => somebody, :message => 'i haz attachments', :discussion_topic => topic, :attachment => attachment)
          replies << reply
        end
        topic.update_materialized_view
        get url
        wait_for_ajaximations
        expect(ffj('.comment_attachments').count).to eq 10
        fj('.showMore').click
        wait_for_ajaximations
        expect(ffj('.comment_attachments').count).to eq replies.count
      end

      context "side comments" do
        let(:topic) { side_comment_topic }

        it "should add a side comment", priority: "1", test_id: 345488 do
          side_comment_text = 'new side comment'
          get url

          f('.discussion-entries .discussion-reply-action').click
          wait_for_ajaximations
          type_in_tiny 'textarea', side_comment_text
          submit_form('.discussion-entries .discussion-reply-form')
          wait_for_ajaximations

          last_entry = DiscussionEntry.last
          expect(last_entry.depth).to eq 2
          expect(last_entry.message).to include(side_comment_text)
          expect(f("#entry-#{last_entry.id}")).to include_text(side_comment_text)
        end

        it "should create multiple side comments but only show 10 and expand the rest", priority: "1", test_id: 345489 do
          side_comment_number = 11
          side_comment_number.times { |i| topic.discussion_entries.create!(:user => student, :message => "new side comment #{i} from student", :parent_entry => entry) }
          get url
          expect(DiscussionEntry.last.depth).to eq 2
          expect(ff('.discussion-entries .entry')).to have_size(12) # +1 because of the initial entry
          scroll_to(fj(".entry-content:contains('teacher')")) # scroll to the button to preserve chrome functionality
          f('.showMore').click
          expect(ff('.discussion-entries .entry')).to have_size(side_comment_number + 2) # +1 because of the initial entry, +1 because of the parent entry
        end

        it "should delete a side comment", priority: "1", test_id: 345490 do
          skip_if_safari(:alert)
          entry = topic.discussion_entries.create!(:user => somebody, :message => "new side comment from somebody", :parent_entry => entry)
          get url
          delete_entry(entry)
        end

        it "should edit a side comment", priority: "1", test_id: 345491 do
          edit_text = 'this has been edited'
          text = "new side comment from somebody"
          entry = topic.discussion_entries.create!(:user => somebody, :message => text, :parent_entry => entry)
          expect(topic.discussion_entries.last.message).to eq text
          get url
          validate_entry_text(entry, text)
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
