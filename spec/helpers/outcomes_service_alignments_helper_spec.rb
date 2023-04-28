# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../spec_helper"
require "webmock/rspec"

describe OutcomesServiceAlignmentsHelper do
  subject { Object.new.extend OutcomesServiceAlignmentsHelper }

  before(:once) do
    course_model
    @outcome1 = outcome_model(context: @course, title: "outcome 1 aligned in OS")
    @outcome2 = outcome_model(context: @course, title: "outcome 2 aligned in OS")
    @new_quiz1 = @course.assignments.create!(title: "new quiz 1 - aligned in OS", submission_types: "external_tool")
    @new_quiz2 = @course.assignments.create!(title: "new quiz 2 - aligned in OS", submission_types: "external_tool")
  end

  let(:account) { @course.account }
  let(:response_with_outcomes) { mock_aligned_outcomes_response([@outcome1, @outcome2], [@new_quiz1, @new_quiz2]) }
  let(:response_no_outcomes) { mock_aligned_outcomes_response([], []) }
  let(:minified_response_with_outcomes) { mock_minified_aligned_outcomes_response(response_with_outcomes) }
  let(:minified_response_no_outcomes) { mock_minified_aligned_outcomes_response(response_no_outcomes) }
  let(:cache_key) { [:os_aligned_outcomes, :account_uuid, account.uuid, :context_uuid, @course.uuid, :context_id, @course.id] }
  let(:minified_response_with_active_outcomes) { mock_minified_aligned_outcomes_response(mock_aligned_outcomes_response([@outcome1], [@new_quiz1, @new_quiz2])) }
  let(:minified_response_with_active_quizzes) { mock_minified_aligned_outcomes_response(mock_aligned_outcomes_response([@outcome1, @outcome2], [@new_quiz1])) }

  def stub_get_aligned_outcomes(context)
    stub_request(:get, "http://domain/api/alignments?context_uuid=#{context.uuid}&context_id=#{context.id}")
      .with({
              headers: {
                Authorization: /\+*/,
                Accept: "*/*",
                "Accept-Encoding": /\+*/,
                "User-Agent": "Ruby"
              }
            })
  end

  def mock_aligned_outcomes_response(outcomes, quizzes)
    [[:outcomes,
      (outcomes || [])
        .map
        .with_index do |o, idx|
        {
          id: idx + 1,
          external_id: o.id.to_s,
          title: o.short_description,
          alignments: (quizzes || []).map.with_index do |q, ind|
                        {
                          artifact_type: "quizzes.quiz",
                          artifact_id: (ind + 1).to_s,
                          associated_asset_type: "canvas.assignment.quizzes",
                          associated_asset_id: q.id.to_s
                        }
                      end
        }
      end]].to_h
  end

  def mock_minified_aligned_outcomes_response(response)
    (response[:outcomes] || []).to_h { |o| [o[:external_id], o[:alignments]] }
  end

  around do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.enable_net_connect!
  end

  describe "#get_os_aligned_outcomes" do
    before do
      settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
      account.settings[:provision] = { "outcomes" => settings }
      account.save!
    end

    context "without context" do
      it "returns nil when context is nil" do
        expect(subject.get_os_aligned_outcomes(nil)).to be_nil
      end

      it "returns nil when context is empty" do
        expect(subject.get_os_aligned_outcomes("")).to be_nil
      end
    end

    context "with context" do
      it "returns outcomes" do
        stub_get_aligned_outcomes(@course).to_return(status: 200, body: response_with_outcomes.to_json)
        expect(subject.get_os_aligned_outcomes(@course)).to eq minified_response_with_outcomes
      end

      it "returns empty response if no outcomes" do
        stub_get_aligned_outcomes(@course).to_return(status: 200, body: response_no_outcomes.to_json)
        expect(subject.get_os_aligned_outcomes(@course)).to eq minified_response_no_outcomes
      end

      it "raises error on non 2xx response" do
        stub_get_aligned_outcomes(@course).to_return(status: 401, body: '{"valid_jwt":false}')
        expect { subject.get_os_aligned_outcomes(@course) }.to raise_error(CanvasOutcomesHelper::OSFetchError)
      end
    end

    context "caching" do
      before do
        stub_get_aligned_outcomes(@course).to_return(status: 200, body: response_with_outcomes.to_json)
      end

      it "scopes cache key per account uuid, course uuid and course id" do
        enable_cache do
          subject.get_os_aligned_outcomes(@course)
          expect(Rails.cache.exist?(cache_key)).to be_truthy
        end
      end

      it "minifies response before caching" do
        enable_cache do
          subject.get_os_aligned_outcomes(@course)
          expect(Rails.cache.fetch(cache_key)).to eq minified_response_with_outcomes
        end
      end
    end
  end

  describe "#get_active_os_alignments" do
    before do
      allow_any_instance_of(OutcomesServiceAlignmentsHelper)
        .to receive(:get_os_aligned_outcomes)
        .and_return(minified_response_with_outcomes)
    end

    it "calls #get_os_aligned_outcomes with context" do
      expect(subject).to receive(:get_os_aligned_outcomes).with(@course)
      subject.get_active_os_alignments(@course)
    end

    context "when outcome is deleted in Canvas but not synched to Outcomes-Service" do
      it "returns only active outcomes in Canvas with alingments to new quizzes" do
        @outcome2.destroy
        expect(subject.get_active_os_alignments(@course)).to eq minified_response_with_active_outcomes
      end
    end

    context "when new quiz is deleted in Canvas but not synched to Outcomes-Service" do
      it "returns only outcomes with alignments to new quizzes that are active in Canvas" do
        @new_quiz2.destroy
        expect(subject.get_active_os_alignments(@course)).to eq minified_response_with_active_quizzes
      end
    end
  end
end
