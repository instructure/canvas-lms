#
# Copyright (C) 2012 - present Instructure, Inc.
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
  before :once do
    course_with_teacher(:active_all => true)
    @ce = @course.content_exports.create!
  end

  context "export_object?" do

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
      quiz = @course.quizzes.create!(:title => 'quiz1')
      Account.default.context_external_tools.create!(
        name: 'Quizzes.Next',
        consumer_key: 'test_key',
        shared_secret: 'test_secret',
        tool_id: 'Quizzes 2',
        url: 'http://example.com/launch'
      )
      @ce = @course.content_exports.create!(
        :export_type => ContentExport::QUIZZES2,
        :selected_content => quiz.id,
        :user => @user
      )
      @course.root_account.settings[:provision] = {'lti' => 'lti url'}
      @course.root_account.save!
    end

    it "changes the workflow_state when :quizzes_next is enabled" do
      @course.enable_feature!(:quizzes_next)
      expect { @ce.export_without_send_later }.to change { @ce.workflow_state }
      expect(@ce.workflow_state).to eq "exported"
    end

    it "fails the content export when :quizzes_next is disabled" do
      @course.disable_feature!(:quizzes_next)
      @ce.export_without_send_later
      expect(@ce.workflow_state).to eq "created"
    end

    it "composes the payload with assignment details" do
      @course.enable_feature!(:quizzes_next)
      @ce.export_without_send_later
      expect(@ce.settings[:quizzes2][:assignment]).not_to be_empty
    end

    it "composes the payload with course UUID" do
      @course.enable_feature!(:quizzes_next)
      @ce.export_without_send_later
      expect(@ce.settings[:quizzes2][:assignment][:course_uuid]).to eq(@course.uuid)
    end

    it "composes the payload with qti details" do
      @course.enable_feature!(:quizzes_next)
      @ce.export_without_send_later
      expect(@ce.settings[:quizzes2][:qti_export][:url]).to eq(@ce.attachment.public_download_url)
    end

    it "completes with export_type of 'quizzes2'" do
      @course.enable_feature!(:quizzes_next)
      @ce.export_without_send_later
      expect(@ce.export_type).to eq('quizzes2')
    end

    context 'failure cases' do
      it "fails if the quiz exporter fails" do
        @course.enable_feature!(:quizzes_next)
        allow_any_instance_of(Exporters::Quizzes2Exporter).to receive(:export).and_return(false)
        @ce.export_without_send_later
        expect(@ce.workflow_state).to eq "failed"
      end

      it "fails if the qti exporter fails" do
        @course.enable_feature!(:quizzes_next)
        allow_any_instance_of(CC::CCExporter).to receive(:export).and_return(false)
        @ce.export_without_send_later
        expect(@ce.workflow_state).to eq "failed"
      end
    end
  end

  context "add_item_to_export" do
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
      @ce.update_attribute(:user_id, @user.id)
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

  describe "#expired?" do
    it "marks as expired after X days" do
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(@ce.reload).to be_expired
    end

    it "does not mark new exports as expired" do
      expect(@ce.reload).not_to be_expired
    end

    it "does not mark as expired if setting is 0" do
      Setting.set('content_exports_expire_after_days', '0')
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(@ce.reload).not_to be_expired
    end
  end

  describe "#expired" do
    it "marks as expired after X days" do
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(ContentExport.expired.pluck(:id)).to eq [@ce.id]
    end

    it "does not mark new exports as expired" do
      expect(ContentExport.expired.pluck(:id)).to be_empty
    end

    it "does not mark as expired if setting is 0" do
      Setting.set('content_exports_expire_after_days', '0')
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(ContentExport.expired.pluck(:id)).to be_empty
    end
  end
end
