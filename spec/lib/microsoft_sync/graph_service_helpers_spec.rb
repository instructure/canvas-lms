# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe MicrosoftSync::GraphServiceHelpers do
  subject { described_class.new("mytenant123", extra_tag: "abc") }

  let(:graph_service) do
    instance_double(
      MicrosoftSync::GraphService,
      education_classes: instance_double(MicrosoftSync::GraphService::EducationClassesEndpoints),
      users: instance_double(MicrosoftSync::GraphService::UsersEndpoints),
      groups: instance_double(MicrosoftSync::GraphService::GroupsEndpoints)
    )
  end

  before do
    allow(MicrosoftSync::GraphService).to receive(:new)
      .with("mytenant123", { extra_tag: "abc" })
      .and_return(graph_service)
  end

  describe "#list_education_classes_for_course" do
    it "filters by externalId=course.uuid" do
      course_model
      expect(graph_service.education_classes).to receive(:list)
        .with(filter: { externalId: @course.uuid })
        .and_return([{ abc: 123 }])
      expect(subject.list_education_classes_for_course(@course)).to eq([{ abc: 123 }])
    end
  end

  describe "#create_education_class" do
    let(:course) { @course }

    it "maps course fields to Microsoft education class fields" do
      course_model(public_description: "great class", name: "math 101")
      expect(graph_service.education_classes).to receive(:create).with(
        description: "great class",
        displayName: "math 101",
        externalId: @course.uuid,
        externalName: "math 101",
        externalSource: "manual",
        mailNickname: "Course_math_101-#{@course.uuid.first(13)}"
      ).and_return("foo")

      expect(subject.create_education_class(@course)).to eq("foo")
    end

    context "when the course has a empty string for a description" do
      # Microsoft API seems to have a problem with description being an empty
      # string
      it "sends nil instead of the empty string" do
        course_model(public_description: "", name: "math 101")
        expect(graph_service.education_classes).to receive(:create).with(
          hash_including(description: nil)
        ).and_return("foo")
        subject.create_education_class(@course)
      end
    end

    context "when the course code contains special characters" do
      let(:course_code) { "{{math🔥一241!&?" }

      before do
        course_model(public_description: "great class", name: "Linear Algebra", course_code:)
      end

      it "removes the special characters" do
        expect(graph_service.education_classes).to receive(:create).with(
          description: "great class",
          displayName: course.name,
          externalId: course.uuid,
          externalName: course.name,
          externalSource: "manual",
          mailNickname: "Course_math_241-#{course.uuid.first(13)}"
        ).and_return("foo")

        subject.create_education_class(course)
      end
    end

    context "when the course code contains invalid characters" do
      let(:course_code) { '@Math<>()\[];:"帆布' }

      before do
        course_model(public_description: "great class", name: "Linear Algebra", course_code:)
      end

      it "removes the invalid characters" do
        expect(graph_service.education_classes).to receive(:create).with(
          {
            description: "great class",
            displayName: course.name,
            externalId: course.uuid,
            externalName: course.name,
            externalSource: "manual",
            mailNickname: "Course_math-#{course.uuid.first(13)}"
          }
        ).and_return("foo")

        subject.create_education_class(course)
      end
    end

    context "when the course name begins or ends with whitespace" do
      let(:course_code) { " math 101    \n\n" }

      before do
        course_model(public_description: "great class", name: "Linear Algebra", course_code:)
      end

      it "removes the whitespace" do
        expect(graph_service.education_classes).to receive(:create).with(
          {
            description: "great class",
            displayName: course.name,
            externalId: course.uuid,
            externalName: course.name,
            externalSource: "manual",
            mailNickname: "Course_math_101-#{course.uuid.first(13)}"
          }
        ).and_return("foo")

        subject.create_education_class(course)
      end
    end

    context "when the course name is too long" do
      let(:name) { "c" * 128 }

      before { course_model(public_description: "great class", name:) }

      it "shortens the mailNickname" do
        expect(graph_service.education_classes).to receive(:create).with(
          {
            description: "great class",
            displayName: name,
            externalId: @course.uuid,
            externalName: name,
            externalSource: "manual",
            mailNickname: "Course_#{@course.name.first(43)}-#{@course.uuid.first(13)}"
          }
        ).and_return("foo")

        subject.create_education_class(@course)
      end
    end

    context "when the course description is >= 1025 characters long" do
      before { course_model(public_description: "a" * 1025) }

      it "truncates the description" do
        expect(graph_service.education_classes).to receive(:create)
          .with(hash_including(description: ("a" * 1021) + "..."))
        subject.create_education_class(@course)
      end
    end

    context "when the course description is 1024 characters long" do
      before { course_model(public_description: "a" * 1024) }

      it "does not truncate the description" do
        expect(graph_service.education_classes).to receive(:create)
          .with(hash_including(description: "a" * 1024))
        subject.create_education_class(@course)
      end
    end
  end

  describe "#update_group_with_course_data" do
    let(:update_group) { subject.update_group_with_course_data("msgroupid", @course) }

    it "maps course fields to Microsoft fields" do
      course_model(public_description: "classic", name: "algebra", sis_source_id: "ALG-101")
      # force generation of lti context id (normally done lazily)
      lti_context_id = Lti::Asset.opaque_identifier_for(@course)
      expect(lti_context_id).to_not be_nil
      expect(graph_service.groups).to receive(:update).with(
        "msgroupid",
        microsoft_EducationClassLmsExt: {
          ltiContextId: lti_context_id,
          lmsCourseId: @course.uuid,
          lmsCourseName: "algebra",
          lmsCourseDescription: "classic",
        },
        microsoft_EducationClassSisExt: {
          sisCourseId: "ALG-101",
        }
      )

      update_group
    end

    def expect_lms_ext_properties(props)
      expect(graph_service.groups).to receive(:update).with(
        "msgroupid",
        hash_including(
          microsoft_EducationClassLmsExt: hash_including(props)
        )
      )
    end

    it "forces generation of lti_context_id if needed" do
      course_model
      expect(Lti::Asset).to receive(:opaque_identifier_for).with(@course).and_return("abcdef")
      expect_lms_ext_properties(ltiContextId: "abcdef")
      update_group
    end

    it "truncates course descriptions longer than 256 characters" do
      course_model(public_description: "a" * 257)
      expect_lms_ext_properties(lmsCourseDescription: ("a" * 253) + "...")
      update_group
    end

    it "does not truncate course descriptions of 256 characters" do
      course_model(public_description: "a" * 256)
      expect_lms_ext_properties(lmsCourseDescription: "a" * 256)
      update_group
    end
  end

  describe "#users_uluvs_to_aads" do
    let(:requested) { %w[a b c d] }
    let(:expected_remote_attr) { "mailNickname" }

    before do
      allow(subject.graph_service.users).to receive(:list)
        .with(select: ["id", expected_remote_attr], filter: { expected_remote_attr => requested })
        .and_return([
                      { "id" => "789", expected_remote_attr => "D" },
                      { "id" => "123", expected_remote_attr => "a" },
                      { "id" => "456", expected_remote_attr => "b" },
                    ])
    end

    context "when the graph service sends a ULUV back that differs in case" do
      it "maps the response back to case of the ULUV in the input array" do
        expect(subject.users_uluvs_to_aads(expected_remote_attr, %w[a b c d])).to eq(
          "a" => "123",
          "b" => "456",
          "d" => "789"
        )
      end
    end

    context "when the graph service sends a uluv back that it didn't ask for" do
      let(:requested) { %w[c d] }

      it "raises an error" do
        expect { subject.users_uluvs_to_aads(expected_remote_attr, %w[c D]) }.to raise_error do |err|
          expect(err.message).to eq(
            '/users returned users with unexpected mailNickname values ["a", "b"], ' \
            'asked for ["c", "d"]'
          )
          expect(err).to be_a_microsoft_sync_public_error(
            "Unexpected response from Microsoft API. This is likely a bug. Please contact support."
          )
        end
      end
    end

    context "when given different-case duplicates of the same ULUV" do
      it "only requests one and copies the AAD on all matching ULUVs" do
        expect(subject.users_uluvs_to_aads(expected_remote_attr, %w[a b c A C D])).to eq(
          "a" => "123",
          "A" => "123",
          "b" => "456",
          "D" => "789"
        )
      end
    end

    context "when passed in more than 15" do
      it "raises ArgumentError" do
        expect { subject.users_uluvs_to_aads(expected_remote_attr, (1..16).map(&:to_s)) }
          .to raise_error(ArgumentError, "Can't look up 16 ULUVs at once")
      end
    end

    context "when nil is passed in for remote_attribute" do
      let(:expected_remote_attr) { "userPrincipalName" }

      it "defaults to userPrincipalName" do
        expect(subject.users_uluvs_to_aads(nil, %w[a b c d]))
          .to eq("a" => "123", "b" => "456", "d" => "789")
      end
    end
  end

  describe "#get_group_users_aad_ids" do
    it "returns ids of all pages of members" do
      expect(subject.graph_service.groups).to receive(:list_members)
        .once
        .with("mygroupid", { select: ["id"], top: 999 })
        .and_yield([{ "id" => "a" }, { "id" => "b" }])
        .and_yield([{ "id" => "c" }])
      expect(subject.get_group_users_aad_ids("mygroupid")).to eq(%w[a b c])
    end

    context "when owners: true is passed in" do
      it "returns owners" do
        expect(subject.graph_service.groups).to receive(:list_owners)
          .once
          .with("mygroupid", { select: ["id"], top: 999 })
          .and_yield([{ "id" => "a" }, { "id" => "b" }])
          .and_yield([{ "id" => "c" }])
        expect(subject.get_group_users_aad_ids("mygroupid", owners: true)).to eq(%w[a b c])
      end
    end
  end
end
