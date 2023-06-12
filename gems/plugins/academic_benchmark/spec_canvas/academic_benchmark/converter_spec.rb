# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe AcademicBenchmark::Converter do
  def raw_standard
    { "attributes" =>
       { "status" => "active",
         "education_levels" => { "grades" => [{ "code" => "5" }] },
         "guid" => "e248c361-6dd7-40fe-9d3e-0a44e2710e93",
         "statement" =>
         { "descr" =>
           "Identify major events of the American Revolution, including the battles of Lexington and Concord, Bunker Hill, Saratoga, and Yorktown." },
         "number" => { "prefix_enhanced" => "SOC.5.8" },
         "label" => "Content Standard",
         "section" =>
         { "guid" => "b6a72362-7ca2-4f00-85ef-6ff44917460b",
           "descr" =>
           "Fifth Grade - United States Studies: Beginnings to the Industrial Revolution" },
         "level" => 1,
         "disciplines" => { "subjects" => [{ "code" => "SOC" }] },
         "document" =>
         { "guid" => "fe79c173-62e4-490b-ad02-a9ee8db932ad",
           "adopt_year" => "2010",
           "descr" => "Social Studies",
           "publication" =>
           { "authorities" =>
             [{ "guid" => "912A8036-F1B9-11E5-862E-0938DC287387",
                "descr" => "Alabama State Department of Education",
                "acronym" => "ALSDE" }],
             "guid" => "9935E84E-C0DA-11DA-844D-F1B58A7EE3C7",
             "descr" => "Course of Study" } } },
      "relationships" => { "parent" => { "data" => {} } },
      "type" => "standards",
      "id" => "e248c361-6dd7-40fe-9d3e-0a44e2710e93" }
  end

  def raw_standard2
    { "id" => "0003631b-ca53-4985-8963-b7907320f8d9",
      "attributes" =>
       { "document" =>
         { "adopt_year" => "2010",
           "descr" => "Social Studies",
           "publication" =>
           { "guid" => "9935E84E-C0DA-11DA-844D-F1B58A7EE3C7",
             "descr" => "Course of Study",
             "authorities" =>
             [{ "acronym" => "ALSDE",
                "guid" => "912A8036-F1B9-11E5-862E-0938DC287387",
                "descr" => "Alabama State Department of Education" }] },
           "guid" => "fe79c173-62e4-490b-ad02-a9ee8db932ad" },
         "number" => { "prefix_enhanced" => "SOC.5.8.5" },
         "guid" => "0003631b-ca53-4985-8963-b7907320f8d9",
         "level" => 2,
         "status" => "active",
         "education_levels" => { "grades" => [{ "code" => "5" }] },
         "section" =>
         { "descr" =>
           "Fifth Grade - United States Studies: Beginnings to the Industrial Revolution",
           "guid" => "b6a72362-7ca2-4f00-85ef-6ff44917460b" },
         "label" => nil,
         "statement" =>
         { "descr" =>
           "Locating on a map major battle sites of the American Revolution, " \
           "including the battles of Lexington and Concord, Bunker Hill, Saratoga, and Yorktown" },
         "disciplines" => { "subjects" => [{ "code" => "SOC" }] },
         "utilizations" => [{ "type" => "alignable" }] },
      "type" => "standards",
      "relationships" =>
       { "parent" =>
         { "links" =>
           { "related" =>
             "https://api.abconnect.certicaconnect.com/rest/v4.1/standards/0003631b-ca53-4985-8963-b7907320f8d9/parent" },
           "data" =>
           { "id" => "e248c361-6dd7-40fe-9d3e-0a44e2710e93",
             "type" => "standards" } } } }
  end

  subject(:converter) do
    AcademicBenchmark::Converter.new(converter_settings)
  end

  let(:raw_authority) do
    raw_standard.dig("attributes", "document", "publication", "authorities", 0)
  end
  let(:authority_instance) do
    AcademicBenchmarks::Standards::Authority.from_hash(raw_authority)
  end
  let(:standard_instance) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard)
  end
  let(:standard_instance2) do
    AcademicBenchmarks::Standards::Standard.new(raw_standard2)
  end
  let(:root_account) { Account.site_admin }
  let(:admin_user) { account_admin_user(account: root_account, active_all: true) }
  let(:regular_user) { user_factory(name: "regular user", short_name: "user") }
  let(:migration_settings) do
    {
      authority: @authority_guid,
      converter_class: "AcademicBenchmark::Converter",
      document: @document_guid,
      import_immediately: true,
      migration_type: "academic_benchmark_importer",
      no_archive_file: true,
      skip_import_notification: true,
      skip_job_progress: true
    }
  end
  let(:content_migration) do
    ContentMigration.create({
                              context: root_account,
                              migration_settings:,
                              user: @user
                            })
  end
  let(:converter_settings) do
    migration_settings.merge({
                               content_migration:,
                               content_migration_id: content_migration.id,
                               user_id: content_migration.user_id,
                               migration_options: { points_possible: 10,
                                                    mastery_points: 6,
                                                    ratings: [{ description: "Awesome", points: 10 },
                                                              { description: "Not awesome", points: 0 }] }
                             })
  end

  before do
    allow(AcademicBenchmark).to receive(:config).and_return({ partner_id: "instructure", partner_key: "key" })
    standards_mock = double("standards")
    allow(standards_mock).to receive(:authority_tree).and_return(
      AcademicBenchmarks::Standards::StandardsForest.new([standard_instance, standard_instance2]).consolidate_under_root(authority_instance)
    )
    allow(AcademicBenchmarks::Api::Standards).to receive(:new).and_return(standards_mock)
    @user = admin_user
  end

  describe "#export" do
    context "when content_migration settings are missing" do
      before do
        allow(converter).to receive(:content_migration).and_return(nil)
      end

      it "raises error missing content_migration settings" do
        expect { converter.export }.to raise_error(Canvas::Migration::Error,
                                                   "Missing required content_migration settings")
      end
    end

    context "when user does not have rights to :manage_global_outcomes" do
      before do
        @user = regular_user
      end

      it "raises error cannot manage global outcomes" do
        expect { converter.export }.to raise_error(Canvas::Migration::Error,
                                                   "User isn't allowed to edit global outcomes")
      end
    end

    context "when an authority guid is provided" do
      before do
        @authority_guid = raw_authority["guid"]
      end

      it "sets course outcomes based on authority guid data" do
        expect(course = converter.export).to be_truthy
        expect(course["learning_outcomes"].count).to be 1
        authority = course["learning_outcomes"].first
        expect(authority["type"]).to eql "learning_outcome_group"
        expect(authority["title"]).to eql "Alabama State Department of Education"
        expect(authority["outcomes"].count).to be 1
        publication = authority["outcomes"].first
        expect(publication["type"]).to eql "learning_outcome_group"
        expect(publication["title"]).to eql "Course of Study"
        expect(publication["outcomes"].count).to eq 1
        group1 = publication["outcomes"].first
        expect(group1["type"]).to eql "learning_outcome_group"
        expect(group1["title"]).to eql "Social Studies (2010)"
        expect(group1["outcomes"].count).to eq 1
        group11 = group1["outcomes"].first
        expect(group11["type"]).to eql "learning_outcome_group"
        expect(group11["title"]).to eql "Fifth Grade - United States Studies: Beginnings to the Industrial Revolution"
        expect(group11["outcomes"].count).to eq 1
        group111 = group11["outcomes"].first
        expect(group111["type"]).to eql "learning_outcome_group"
        expect(group111["title"]).to eql "SOC.5.8 - Identify major events of the American Revolution, "
        expect(group111["outcomes"].count).to eq 1
        outcome = group111["outcomes"].first
        expect(outcome["type"]).to eql "learning_outcome"
        expect(outcome["title"]).to eql "SOC.5.8.5"
        expect(outcome["mastery_points"]).to be 6
        expect(outcome["points_possible"]).to be 10
        expect(outcome["ratings"].length).to be 2
      end

      context "document without adoption year" do
        let(:standard_instance) do
          dup_hash = raw_standard.dup
          dup_hash["attributes"]["document"]["adopt_year"] = ""
          AcademicBenchmarks::Standards::Standard.new(dup_hash)
        end

        let(:standard_instance2) do
          dup_hash = raw_standard2.dup
          dup_hash["attributes"]["document"]["adopt_year"] = ""
          AcademicBenchmarks::Standards::Standard.new(dup_hash)
        end

        it "does not append adoption year" do
          expect(course = converter.export).to be_truthy
          expect(course["learning_outcomes"].count).to be 1
          authority = course["learning_outcomes"].first
          expect(authority["outcomes"].count).to be 1
          publication = authority["outcomes"][0]
          expect(publication["outcomes"].count).to eq 1
          expect(publication["outcomes"][0]["title"]).to eq "Social Studies"
        end
      end

      context "clarification standards" do
        let(:standard_instance2) do
          dup_hash = raw_standard2.dup
          dup_hash["attributes"]["utilizations"] = [{ "type" => "clarification" }]
          AcademicBenchmarks::Standards::Standard.new(dup_hash)
        end

        it "appends the description to the parent standard and treats the parent as an outcome" do
          expect(course = converter.export).to be_truthy
          authority = course["learning_outcomes"].first
          publication = authority["outcomes"].first
          group1 = publication["outcomes"].first
          group11 = group1["outcomes"].first
          group111 = group11["outcomes"].first
          expect(group111["type"]).to eq "learning_outcome"
          expect(group111["description"]).to match(/and Yorktown. Locating/)
        end
      end
    end
  end
end
