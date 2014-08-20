#
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

describe KalturaMediaFileHandler do
  describe '#add_media_files' do
    let(:kaltura_config) { {} }
    let(:kaltura_client) { mock('CanvasKaltura::ClientV3') }
    let(:files_sent_to_kaltura) { [] }
    let(:uploading_user) { user }
    let(:attachment_context) { uploading_user }
    let(:attachment) { attachment_obj_with_context(attachment_context, user: uploading_user) }
    let(:wait_for_completion) { false }
    let(:bulk_upload_add_response) {{ id: "someBulkUploadId", ready: false }}

    before do
      CanvasKaltura::ClientV3.stubs(:config).returns(kaltura_config)
      CanvasKaltura::ClientV3.stubs(:new).returns(kaltura_client)
      kaltura_client.stubs(:startSession)
      kaltura_client.stubs(:bulkUploadAdd).with do |files|
        files_sent_to_kaltura.concat(files)
      end.returns(bulk_upload_add_response)
    end

    it "should work for user context" do
      KalturaMediaFileHandler.new.add_media_files(attachment, wait_for_completion)
    end

    it "queues a job to check on the bulk upload later" do
      MediaObject.expects(:send_later_enqueue_args).with do |method, config, *args|
        method.should == :refresh_media_files
        args.should == ['someBulkUploadId', [attachment.id], attachment.root_account_id]
      end

      KalturaMediaFileHandler.new.add_media_files(attachment, wait_for_completion)
    end

    context "when wait_for_completion is true" do
      let(:wait_for_completion) { true }

      it "polls until the bulk upload completes, then calls build_media_objects with the result" do
        media_file_handler = KalturaMediaFileHandler.new
        unfinished_bulk_upload_get = { ready: false }
        successful_bulk_upload_get = { ready: true, entries: [:some_details] }

        media_file_handler.expects(:sleep).with(60).twice
        kaltura_client.expects(:bulkUploadGet).with("someBulkUploadId").twice
          .returns(unfinished_bulk_upload_get).then
          .returns(successful_bulk_upload_get)

        MediaObject.expects(:build_media_objects).with(successful_bulk_upload_get, attachment.root_account_id)

        media_file_handler.add_media_files(attachment, wait_for_completion)
      end

      it "times out after media_bulk_upload_timeout, queuing a job to check in later" do
        media_file_handler = KalturaMediaFileHandler.new

        Setting.set('media_bulk_upload_timeout', 0)

        MediaObject.expects(:send_later_enqueue_args).with do |method, config, *args|
          method.should == :refresh_media_files
          args.should == ['someBulkUploadId', [attachment.id], attachment.root_account_id]
        end

        media_file_handler.add_media_files(attachment, wait_for_completion)
      end
    end

    context "partner_data" do
      specs_require_sharding

      it "always includes basic info about attachment and context" do
        KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

        partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
        partner_data_json.should == {
          "attachment_id" => attachment.id.to_s,
          "context_source" => "file_upload",
          "root_account_id" => Shard.global_id_for(attachment.root_account_id).to_s,
        }
      end

      context "when the kaltura settings for the account include 'Write SIS data to Kaltura'" do
        let(:kaltura_config) { { 'kaltura_sis' => '1' }}

        it "adds a context_code to the partner_data" do
          KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

          partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
          partner_data_json['context_code'].should == "user_#{attachment_context.id}"
        end

        context "and the context has a root_account attached" do
          let(:attachment_context) { course_with_teacher(user: uploading_user).course }

          context "and the user has a pseudonym with a user_sis_id attached" do
            let(:uploading_user) { user_with_pseudonym }

            before do
              uploading_user.pseudonym.sis_user_id = "some_id_from_sis"
              uploading_user.pseudonym.save
            end

            it "adds sis_user_id to partner_data" do
              KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

              partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
              partner_data_json["sis_user_id"].should == "some_id_from_sis"
            end
          end

          context 'and the context has a sis_source_id attached' do
            before do
              attachment_context.sis_source_id = "gooboo"
              attachment_context.save!
            end

            it "adds sis_source_id to partner_data" do
              KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

              partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
              partner_data_json["sis_source_id"].should == "gooboo"
            end
          end
        end
      end
    end
  end
end

