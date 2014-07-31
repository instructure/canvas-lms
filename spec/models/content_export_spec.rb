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
      @ce = ContentExport.new(course: Account.default.courses.create!)
    end

    it "should return true for everything if there are no copy options" do
      @ce.export_object?(@ce).should == true
    end

    it "should return true for everything if 'everything' is selected" do
      @ce.selected_content = {:everything => "1"}
      @ce.export_object?(@ce).should == true
    end

    it "should return false for nil objects" do
      @ce.export_object?(nil).should == false
    end

    it "should return true for all object types if the all_ option is true" do
      @ce.selected_content = {:all_content_exports => "1"}
      @ce.export_object?(@ce).should == true
    end

    it "should return false for objects not selected" do
      @ce.save!
      @ce.selected_content = {:all_content_exports => "0"}
      @ce.export_object?(@ce).should == false
      @ce.selected_content = {:content_exports => {}}
      @ce.export_object?(@ce).should == false
      @ce.selected_content = {:content_exports => {CC::CCHelper.create_key(@ce) => "0"}}
      @ce.export_object?(@ce).should == false
    end

    it "should return true for selected objects" do
      @ce.save!
      @ce.selected_content = {:content_exports => {CC::CCHelper.create_key(@ce) => "1"}}
      @ce.export_object?(@ce).should == true
    end
  end

  context "add_item_to_export" do
    before :once do
      @ce = ContentExport.new(course: Account.default.courses.create!)
    end

    it "should not add nil" do
      @ce.add_item_to_export(nil)
      @ce.selected_content.should be_empty
    end

    it "should only add data model objects" do
      @ce.add_item_to_export("hi")
      @ce.selected_content.should be_empty

      @ce.selected_content = { :assignments => nil }
      @ce.save!

      assignment_model
      @ce.add_item_to_export(@assignment)
      @ce.selected_content[:assignments].should_not be_empty
    end

    it "should not add objects if everything is already set" do
      assignment_model
      @ce.add_item_to_export(@assignment)
      @ce.selected_content.should be_empty

      @ce.selected_content = { :everything => 1 }
      @ce.save!

      @ce.add_item_to_export(@assignment)
      @ce.selected_content.keys.map(&:to_s).should == ["everything"]
    end
  end

  context "notifications" do
    before :once do
      course_with_teacher(:active_all => true)
      @ce = ContentExport.create! { |ce| ce.user = @user; ce.course = @course }

      Notification.create!(:name => 'Content Export Finished', :category => 'Migration')
      Notification.create!(:name => 'Content Export Failed', :category => 'Migration')
    end

    it "should send notifications immediately" do
      communication_channel_model.confirm!

      ['created', 'exporting', 'exported_for_course_copy', 'deleted'].each do |workflow|
        @ce.workflow_state = workflow 
        expect { @ce.save! }.to change(DelayedMessage, :count).by 0
        @ce.messages_sent['Content Export Finished'].should be_blank
        @ce.messages_sent['Content Export Failed'].should be_blank
      end

      @ce.workflow_state = 'exported'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      @ce.messages_sent['Content Export Finished'].should_not be_blank

      @ce.workflow_state = 'failed'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      @ce.messages_sent['Content Export Failed'].should_not be_blank
    end

    it "should not send emails as part of a content migration (course copy)" do
      @cm = ContentMigration.new(:user => @user, :copy_options => {:everything => "1"}, :context => @course)
      @ce.content_migration = @cm
      @ce.save!

      @ce.workflow_state = 'exported'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      @ce.messages_sent['Content Export Finished'].should be_blank

      @ce.workflow_state = 'failed'
      expect { @ce.save! }.to change(DelayedMessage, :count).by 0
      @ce.messages_sent['Content Export Failed'].should be_blank
    end
  end
end
