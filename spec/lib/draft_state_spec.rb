# Copyright (C) 2014 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "Draft State Feature Flag Weirdness" do
  let(:t_site_admin) { Account.site_admin }
  let(:t_account_manager) { account_admin_user account: t_site_admin, membership_type: 'AccountMembership' }
  let(:t_root_account) { account_model }
  let(:t_root_admin) { account_admin_user account: t_root_account }
  let(:t_course) { course(account: t_root_account, draft_state: true, active_all: true) }

  context "Course" do
    it "should give a warning for 'off'" do
      t = Feature.transitions(:draft_state, t_root_admin, t_course, 'on')
      t.keys.should eql ['off']
      t['off']['locked'].should be_false
      t['off']['message'].should =~ /will publish/
    end

    it "should kick off a publish job in state change callback" do
      quiz = t_course.quizzes.create! title: 'a quiz'
      quiz.workflow_state = 'unpublished'
      quiz.save!

      page = t_course.wiki.wiki_pages.create title: 'some page'
      page.workflow_state = 'unpublished'
      page.save!

      topic = t_course.discussion_topics.create title: 'a topic'
      topic.workflow_state = 'unpublished'
      topic.save!

      assignment = t_course.assignments.create name: 'do this'
      assignment.workflow_state = 'unpublished'
      assignment.save!

      mod = t_course.context_modules.create name: 'blargh'
      mod.workflow_state = 'unpublished'
      mod.save!

      item = mod.add_item type: 'wiki_page', id: page.id
      item.workflow_state = 'unpublished'
      item.save!

      t_course.disable_feature!(:draft_state)
      expect {
        Feature.definitions['draft_state'].after_state_change_proc.call(t_course, 'on', 'off')
      }.to change(Delayed::Job, :count).by(1)

      run_jobs

      quiz.reload.should be_edited
      page.reload.hide_from_students.should be_true
      topic.reload.should be_active
      assignment.reload.should be_published
      mod.reload.should be_active
      item.reload.should be_active
    end
  end

  context "Account" do
    context "as root admin" do
      it "from 'off', should allow 'allowed' and 'on'" do
        t = Feature.transitions(:draft_state, t_root_admin, t_root_account, 'off')
        t.keys.sort.should eql ['allowed', 'on']
        t['allowed']['locked'].should be_false
        t['on']['locked'].should be_false
      end

      it "from 'allowed', should forbid 'off' but allow 'on'" do
        t = Feature.transitions(:draft_state, t_root_admin, t_root_account, 'allowed')
        t.keys.sort.should eql ['off', 'on']
        t['off']['locked'].should be_true
        t['off']['message'].should =~ /impact existing courses/
        t['on']['locked'].should be_false
      end

      it "from 'on', should forbid both 'off' and 'allowed'" do
        t = Feature.transitions(:draft_state, t_root_admin, t_root_account, 'on')
        t.keys.sort.should eql ['allowed', 'off']
        t['off']['locked'].should be_true
        t['off']['message'].should =~ /impact existing courses/
        t['allowed']['locked'].should be_true
        t['allowed']['message'].should =~ /impact existing courses/
      end
    end

    context "as account manager" do
      it "from 'allowed', should allow 'off' and 'on', but warn for 'off'" do
        t = Feature.transitions(:draft_state, t_account_manager, t_root_account, 'allowed')
        t.keys.sort.should eql ['off', 'on']
        t['off']['locked'].should be_false
        t['off']['message'].should =~ /impact existing courses/
        t['on']['locked'].should be_false
      end

      it "from 'on', should allow 'off' and 'allowed', but warn for both" do
        t = Feature.transitions(:draft_state, t_account_manager, t_root_account, 'on')
        t.keys.sort.should eql ['allowed', 'off']
        t['off']['locked'].should be_false
        t['off']['message'].should =~ /impact existing courses/
        t['allowed']['locked'].should be_false
        t['allowed']['message'].should =~ /impact existing courses/
      end
    end
  end
end
