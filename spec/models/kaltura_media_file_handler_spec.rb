# frozen_string_literal: true

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
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for mor
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

describe KalturaMediaFileHandler do
  describe "#add_media_files" do
    let(:kaltura_config) { {} }
    let(:kaltura_client) { double("CanvasKaltura::ClientV3") }
    let(:files_sent_to_kaltura) { [] }
    let(:uploading_user) { user_factory }
    let(:attachment_context) { uploading_user }
    let(:attachment) { attachment_obj_with_context(attachment_context, user: uploading_user) }
    let(:wait_for_completion) { false }
    let(:bulk_upload_add_response) { { id: "someBulkUploadId", ready: false } }

    before do
      allow(CanvasKaltura::ClientV3).to receive_messages(config: kaltura_config, new: kaltura_client)
      allow(kaltura_client).to receive(:startSession)
    end

    context "with successful upload" do
      before do
        allow(kaltura_client).to receive(:bulkUploadAdd) do |files|
          files_sent_to_kaltura.concat(files)
          bulk_upload_add_response
        end
      end

      it "works for user context" do
        KalturaMediaFileHandler.new.add_media_files(attachment, wait_for_completion)
      end

      it "queues a job to check on the bulk upload later" do
        expect(MediaObject).to receive(:delay).and_return(MediaObject)
        expect(MediaObject).to receive(:refresh_media_files).with("someBulkUploadId", [attachment.id], attachment.root_account_id)

        KalturaMediaFileHandler.new.add_media_files(attachment, wait_for_completion)
      end

      context "when wait_for_completion is true" do
        let(:wait_for_completion) { true }

        it "polls until the bulk upload completes, then calls build_media_objects with the result" do
          media_file_handler = KalturaMediaFileHandler.new
          unfinished_bulk_upload_get = { ready: false }
          successful_bulk_upload_get = { ready: true, entries: [:some_details] }

          expect(media_file_handler).to receive(:sleep).with(60).twice
          expect(kaltura_client).to receive(:bulkUploadGet).with("someBulkUploadId").twice
                                                           .and_return(unfinished_bulk_upload_get, successful_bulk_upload_get)

          expect(MediaObject).to receive(:build_media_objects).with(successful_bulk_upload_get, attachment.root_account_id)

          media_file_handler.add_media_files(attachment, wait_for_completion)
        end

        it "times out after media_bulk_upload_timeout, queuing a job to check in later" do
          media_file_handler = KalturaMediaFileHandler.new

          Setting.set("media_bulk_upload_timeout", 0)

          expect(MediaObject).to receive(:delay).and_return(MediaObject)
          expect(MediaObject).to receive(:refresh_media_files).with("someBulkUploadId", [attachment.id], attachment.root_account_id)

          media_file_handler.add_media_files(attachment, wait_for_completion)
        end
      end

      context "partner_data" do
        specs_require_sharding

        it "always includes basic info about attachment and context" do
          KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

          partner_data = Rack::Utils.parse_nested_query(files_sent_to_kaltura.first[:partner_data])
          expect(partner_data).to eq({
                                       "attachment_id" => attachment.id.to_s,
                                       "context_source" => "file_upload",
                                       "root_account_id" => Shard.global_id_for(attachment.root_account_id).to_s,
                                     })
        end

        context "when the kaltura settings for the account include 'Write SIS data to Kaltura'" do
          let(:kaltura_config) { { "kaltura_sis" => "1" } }

          it "adds a context_code to the partner_data" do
            KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

            partner_data = Rack::Utils.parse_nested_query(files_sent_to_kaltura.first[:partner_data])
            expect(partner_data["context_code"]).to eq "user_#{attachment_context.id}"
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

                partner_data = Rack::Utils.parse_nested_query(files_sent_to_kaltura.first[:partner_data])
                expect(partner_data["sis_user_id"]).to eq "some_id_from_sis"
              end
            end

            context "and the context has a sis_source_id attached" do
              before do
                attachment_context.sis_source_id = "gooboo"
                attachment_context.save!
              end

              it "adds sis_source_id to partner_data" do
                KalturaMediaFileHandler.new.add_media_files([attachment], wait_for_completion)

                partner_data = Rack::Utils.parse_nested_query(files_sent_to_kaltura.first[:partner_data])
                expect(partner_data["sis_source_id"]).to eq "gooboo"
              end
            end
          end
        end
      end
    end
  end
end
