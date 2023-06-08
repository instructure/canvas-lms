# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../helpers/discussions_common"

require "nokogiri"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap(&:offer!) }
  let(:student) { student_in_course(course:, name: "student", active_all: true).user }
  let(:teacher) { teacher_in_course(course:, name: "teacher", active_all: true).user }
  let(:somebody) { student_in_course(course:, name: "somebody", active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: "student topic title", message: "student topic message") }
  let(:somebody_topic) { course.discussion_topics.create!(user: somebody, title: "somebody topic title", message: "somebody topic message") }
  let(:side_comment_topic) do
    t = course.discussion_topics.create!(user: somebody, title: "side comment topic title", message: "side comment topic message")
    t.discussion_entries.create!(user: somebody, message: "side comment topic entry message")
    t
  end
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: "teacher entry") }

  context "on the show page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/" }

    context "as anyone" do
      let(:topic) { somebody_topic }
      let(:topic_participant) { topic.discussion_topic_participants.find_by(user: somebody) }

      before do
        user_session(somebody)
        stub_rcs_config
      end

      context "topic subscription" do
        context "someone else's topic" do
          let(:topic) { student_topic }

          it "updates subscribed button when user posts to a topic", priority: "2" do
            get url
            expect(f(".topic-subscribe-button")).to be_displayed
            add_reply "student posting"
            expect(f(".topic-unsubscribe-button")).to be_displayed
          end
        end
      end

      it "displays the current username when adding a reply", priority: "1" do
        get url
        expect(f("#content")).not_to contain_css("#discussion_subentries .discussion_entry")
        add_reply
        expect(get_all_replies.count).to eq 1
        expect(@last_entry.find_element(:css, ".author").text).to eq somebody.name
      end

      context "side comments" do
        let(:topic) { side_comment_topic }

        it "adds a side comment", priority: "1" do
          side_comment_text = "new side comment"
          get url

          f(".discussion-entries .discussion-reply-action").click
          wait_for_ajaximations
          type_in_tiny "textarea", side_comment_text
          submit_form(".discussion-entries .discussion-reply-form")
          wait_for_ajaximations

          last_entry = DiscussionEntry.last
          expect(last_entry.depth).to eq 2
          expect(last_entry.message).to include(side_comment_text)
          expect(f("#entry-#{last_entry.id}")).to include_text(side_comment_text)
        end

        it "edits a side comment", priority: "1" do
          edit_text = "this has been edited"
          text = "new side comment from somebody"
          entry = topic.discussion_entries.create!(user: somebody, message: text, parent_entry: entry)
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
