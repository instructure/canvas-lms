# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require "webmock/rspec"

describe OutcomesService::MigrationService do
  around do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.enable_net_connect!
  end

  let(:root_account) { account_model }
  let(:course) { course_model(root_account:) }

  context "without settings" do
    describe ".applies_to_course?" do
      it "returns false" do
        expect(described_class.applies_to_course?(course)).to be false
      end
    end
  end

  context "with settings" do
    before do
      root_account.settings[:provision] = { "outcomes" => {
        domain: "canvas.test",
        consumer_key: "blah",
        jwt_secret: "woo"
      } }
      root_account.save!
    end

    context "with feature flag disabled" do
      before do
        root_account.disable_feature!(:outcome_alignments_course_migration)
      end

      describe ".applies_to_course?" do
        it "returns false" do
          expect(described_class.applies_to_course?(course)).to be false
        end
      end
    end

    context "with feature flag enabled" do
      before do
        root_account.enable_feature!(:outcome_alignments_course_migration)
      end

      describe ".applies_to_course?" do
        it "returns true" do
          expect(described_class.applies_to_course?(course)).to be true
        end
      end

      describe ".begin_export" do
        before do
          course.wiki_pages.create(
            title: "Some random wiki page",
            body: "wiki page content"
          )
        end

        def stub_post_content_export(external_ids = [course.wiki_pages.first.id])
          stub_request(:post, "http://canvas.test/api/content_exports").with({
                                                                               body: {
                                                                                 context_type: "course",
                                                                                 context_id: course.id.to_s,
                                                                                 export_settings: {
                                                                                   format: "canvas",
                                                                                   artifacts: [{
                                                                                     external_type: "canvas.page",
                                                                                     external_id: external_ids
                                                                                   }]
                                                                                 }
                                                                               },
                                                                               headers: {
                                                                                 Authorization: /.+/
                                                                               }
                                                                             })
        end

        it "requests course wiki page" do
          stub_post_content_export.to_return(status: 200, body: '{"id":123}')
          expect(described_class.begin_export(course, {})).to eq({
                                                                   export_id: 123,
                                                                   course:
                                                                 })
        end

        it "raises error on non 2xx response" do
          stub_post_content_export.to_return(status: 401, body: '{"valid_jwt":false}')
          expect { described_class.begin_export(course, {}) }.to raise_error(/Error queueing export for Outcomes Service/)
        end

        it "requests selective course wiki page" do
          stub_post_content_export(["2"]).to_return(status: 200, body: '{"id":123}')
          expect(described_class.begin_export(course, {
                                                selective: true,
                                                exported_assets: ["wiki_page_2"]
                                              })).to eq({
                                                          export_id: 123,
                                                          course:
                                                        })
        end

        it "returns no export if no artifacts requested" do
          expect(described_class.begin_export(course, {
                                                selective: true,
                                                exported_assets: []
                                              })).to be_nil
        end
      end

      describe ".export_completed?" do
        let(:export_data) do
          {
            course:,
            export_id: 1
          }
        end

        def stub_get_content_export
          stub_request(:get, "http://canvas.test/api/content_exports/1").with({
                                                                                headers: {
                                                                                  Authorization: /\+*/
                                                                                }
                                                                              })
        end

        it "returns true on completed" do
          stub_get_content_export.to_return(status: 200, body: '{"state":"completed"}')
          expect(described_class.export_completed?(export_data)).to be true
        end

        it "returns false on pending" do
          stub_get_content_export.to_return(status: 200, body: '{"state":"in_progress"}')
          expect(described_class.export_completed?(export_data)).to be false
        end

        it "raises error on failed" do
          stub_get_content_export.to_return(status: 200, body: '{"state":"failed"}')
          expect { described_class.export_completed?(export_data) }.to raise_error("Content Export for Outcomes Service failed")
        end

        it "raises error on non 2xx response" do
          stub_request(:get, "http://canvas.test/api/content_exports/1").to_return(status: 401, body: '{"valid_jwt":false}')
          export_data = {
            course:,
            export_id: 1
          }
          expect { described_class.export_completed?(export_data) }.to raise_error('Error retrieving export state for Outcomes Service: {"valid_jwt":false}')
        end
      end

      describe ".retrieve_export" do
        let(:export_data) do
          {
            course:,
            export_id: 1
          }
        end

        def stub_get_content_export
          stub_request(:get, "http://canvas.test/api/content_exports/1").with({
                                                                                headers: {
                                                                                  Authorization: /\+*/
                                                                                }
                                                                              })
        end

        it "returns export data when complete" do
          stub_get_content_export.to_return(status: 200, body: '{"data":"stuff"}')
          expect(described_class.retrieve_export(export_data)).to eq "stuff"
        end

        it "raises error on non 2xx response" do
          stub_get_content_export.to_return(status: 401, body: '{"valid_jwt":false}')
          expect { described_class.retrieve_export(export_data) }.to raise_error('Error retrieving export for Outcomes Service: {"valid_jwt":false}')
        end
      end

      describe ".send_imported_content" do
        let(:content_migration) { ContentMigration.create!(context: course) }
        let(:imported_content) do
          {
            data: "stuff"
          }
        end

        def stub_post_content_import
          stub_request(:post, "http://canvas.test/api/content_imports").with(
            body: {
              context_type: "course",
              context_id: course.id.to_s,
              external_migration_id: content_migration.id,
              data: "stuff",
              outcomes: be_an_instance_of(Array),
              edges: be_an_instance_of(Array),
              groups: be_an_instance_of(Array)
            },
            headers: {
              Authorization: /\+*/
            }
          )
        end

        it "returns import id on import creation" do
          stub_post_content_import.to_return(status: 200, body: '{"id":123}')
          expect(described_class.send_imported_content(course, content_migration, imported_content)).to eq({
                                                                                                             import_id: 123,
                                                                                                             course:,
                                                                                                             content_migration:
                                                                                                           })
        end

        it "raises error on non 2xx response" do
          stub_post_content_import.to_return(status: 401, body: '{"valid_jwt":false}')
          expect { described_class.send_imported_content(course, content_migration, imported_content) }.to raise_error(
            'Error sending import for Outcomes Service: {"valid_jwt":false}'
          )
        end
      end

      describe ".import_completed?" do
        let(:content_migration) { ContentMigration.create!(context: course) }
        let(:import_data) do
          {
            course:,
            import_id: 1,
            content_migration:
          }
        end

        let!(:wiki_page) do
          wiki_page_model({ course: })
        end

        def stub_get_content_import
          stub_request(:get, "http://canvas.test/api/content_imports/1").with({
                                                                                headers: {
                                                                                  Authorization: /\+*/
                                                                                }
                                                                              })
        end

        it "returns true on completed" do
          stub_get_content_import.to_return(status: 200, body: '{"state":"completed"}')
          expect(described_class.import_completed?(import_data)).to be true
        end

        it "sets the content migrations warnings" do
          stub_get_content_import.to_return(status: 200, body: "{\"state\":\"completed\", \"missing_alignments\": [
{\"artifact_type\": \"canvas.page\", \"artifact_id\": \"#{wiki_page.id}\"}]}")
          expect(described_class.import_completed?(import_data)).to be true
          expect(content_migration.warnings).to eq ["Unable to align some outcomes to \"some page\""]
        end

        it "fails to find the outcome, but still sets the content migrations warning" do
          stub_get_content_import.to_return(status: 200, body: "{\"state\":\"completed\", \"missing_alignments\": [
{\"artifact_type\": \"canvas.page\", \"artifact_id\": 1}]}")
          expect(described_class.import_completed?(import_data)).to be true
          expect(content_migration.warnings).to eq ["Unable to align some outcomes to a page"]
        end

        it "adds multiple content migration warnings" do
          stub_get_content_import.to_return(status: 200, body: "{\"state\":\"completed\", \"missing_alignments\": [
{\"artifact_type\": \"canvas.page\", \"artifact_id\": 1},
{\"artifact_type\": \"canvas.page\", \"artifact_id\": #{wiki_page.id}}]}")
          expect(described_class.import_completed?(import_data)).to be true
          expect(content_migration.warnings).to include("Unable to align some outcomes to a page")
          expect(content_migration.warnings).to include('Unable to align some outcomes to "some page"')
        end

        it "returns false on pending" do
          stub_get_content_import.to_return(status: 200, body: '{"state":"in_progress"}')
          expect(described_class.import_completed?(import_data)).to be false
        end

        it "raises error on failed and adds a content_import warning" do
          failure_desc = "Content Import for Outcomes Service failed"
          stub_get_content_import.to_return(status: 200, body: '{"state":"failed"}')
          expect { described_class.import_completed?(import_data) }.to raise_error(RuntimeError,
                                                                                   "#{failure_desc}: {\"state\"=>\"failed\"}")
          expect(content_migration.warnings).to include("Content Import for Outcomes Service failed")
        end

        it "raises error on non 2xx response and adds a content_import warning" do
          outcomes_response = '{"valid_jwt":false}'
          failure_desc = "Error retrieving import state for Outcomes Service: #{outcomes_response}"
          stub_get_content_import.to_return(status: 401, body: outcomes_response)
          expect { described_class.import_completed?(import_data) }.to raise_error(RuntimeError, failure_desc)
          expect(content_migration.warnings).to include(failure_desc)
        end
      end
    end
  end
end
