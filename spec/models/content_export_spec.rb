#
# Copyright (C) 2011 Instructure, Inc.
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

describe ContentExport do

  context "export_object?" do
    before :once do
      course = Account.default.courses.create!
      @ce = course.content_exports.create!
    end

    it "should return true for everything if there are no copy options" do
      expect(@ce.export_object?(@ce)).to eq true
    end

    it "should return true for everything if 'everything' is selected" do
      @ce.selected_content = {:everything => "1"}
      expect(@ce.export_object?(@ce)).to eq true
    end

    it "should return false for nil objects" do
      expect(@ce.export_object?(nil)).to eq false
    end

    it "should return true for all object types if the all_ option is true" do
      @ce.selected_content = {:all_content_exports => "1"}
      expect(@ce.export_object?(@ce)).to eq true
    end

    it "should return false for objects not selected" do
      @ce.save!
      @ce.selected_content = {:all_content_exports => "0"}
      expect(@ce.export_object?(@ce)).to eq false
      @ce.selected_content = {:content_exports => {}}
      expect(@ce.export_object?(@ce)).to eq false
      @ce.selected_content = {:content_exports => {CC::CCHelper.create_key(@ce) => "0"}}
      expect(@ce.export_object?(@ce)).to eq false
    end

    it "should return true for selected objects" do
      @ce.save!
      @ce.selected_content = {:content_exports => {CC::CCHelper.create_key(@ce) => "1"}}
      expect(@ce.export_object?(@ce)).to eq true
    end
  end

  context "Quizzes2 Export" do
    before :once do
      course = Account.default.courses.create!
      quiz = course.quizzes.create!(:title => 'quiz1')
      Account.default.context_external_tools.create!(
        name: 'Quizzes.Next',
        consumer_key: 'test_key',
        shared_secret: 'test_secret',
        tool_id: 'Quizzes 2',
        url: 'http://example.com/launch'
      )
      @ce = course.content_exports.create!(
        :export_type => ContentExport::QUIZZES2,
        :selected_content => quiz.id
      )
    end

    it "changes the workflow_state when :quizzes2_exporter is enabled" do
      Account.default.enable_feature!(:quizzes2_exporter)
      expect { @ce.export_without_send_later }.to change { @ce.workflow_state }
      expect(@ce.workflow_state).to eq "exported"
    end

    it "fails the content export when :quizzes2_exporter is disabled" do
      Account.default.disable_feature!(:quizzes2_exporter)
      @ce.export_without_send_later
      expect(@ce.workflow_state).to eq "created"
    end
  end

  context "add_item_to_export" do
    before :once do
      course = Account.default.courses.create!
      @ce = course.content_exports.create!
    end

    it "should not add nil" do
      @ce.add_item_to_export(nil)
      expect(@ce.selected_content).to be_empty
    end

    it "should only add data model objects" do
      @ce.add_item_to_export("hi")
      expect(@ce.selected_content).to be_empty

      @ce.selected_content = { :assignments => nil }
      @ce.save!

      assignment_model
      @ce.add_item_to_export(@assignment)
      expect(@ce.selected_content[:assignments]).not_to be_empty
    end

    it "should not add objects if everything is already set" do
      assignment_model
      @ce.add_item_to_export(@assignment)
      expect(@ce.selected_content).to be_empty

      @ce.selected_content = { :everything => 1 }
      @ce.save!

      @ce.add_item_to_export(@assignment)
      expect(@ce.selected_content.keys.map(&:to_s)).to eq ["everything"]
    end
  end

  context "notifications" do
    before :once do
      course_with_teacher(:active_all => true)
      @ce = @course.content_exports.create! { |ce| ce.user = @user }

      Notification.create!(:name => 'Content Export Finished', :category => 'Migration')
      Notification.create!(:name => 'Content Export Failed', :category => 'Migration')
    end

    it "should send notifications immediately" do
      communication_channel_model.confirm!

      ['created', 'exporting', 'exported_for_course_copy', 'deleted'].each do |workflow|
        @ce.workflow_state = workflow 
        expect { @ce.save! }.to change(DelayedMessage, :count).by 0
        expect(@ce.messages_sent['Content Export Finished']).to be_blank
        expect(@ce.messages_sent['Content Export Failed']).to be_blank
      end

      @ce.workflow_state = 'exported'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      expect(@ce.messages_sent['Content Export Finished']).not_to be_blank

      @ce.workflow_state = 'failed'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      expect(@ce.messages_sent['Content Export Failed']).not_to be_blank
    end

    it "should not send emails as part of a content migration (course copy)" do
      @cm = ContentMigration.new(:user => @user, :copy_options => {:everything => "1"}, :context => @course)
      @ce.content_migration = @cm
      @ce.save!

      @ce.workflow_state = 'exported'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      expect(@ce.messages_sent['Content Export Finished']).to be_blank

      @ce.workflow_state = 'failed'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      expect(@ce.messages_sent['Content Export Failed']).to be_blank
    end
  end
end
