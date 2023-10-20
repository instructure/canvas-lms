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
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe ProgressSerializer do
  subject do
    ProgressSerializer.new(progress, {
                             controller:,
                             scope: User.new
                           })
  end

  let(:context) { Account.default }

  let :progress do
    p = context.progresses.build
    p.id = 1
    p.completion = 10
    p.workflow_state = "running"
    p.save
    p
  end

  let(:host_name) { "example.com" }

  let :controller do
    options = {
      accepts_jsonapi: true,
      stringify_json_ids: true
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      allow(controller).to receive_messages(session: Object.new, context: Object.new)
    end
  end

  let :json do
    @json ||= subject.as_json[:progress].stringify_keys
  end

  %i[
    context_type
    user_id
    tag
    completion
    workflow_state
    created_at
    updated_at
    message
  ].map(&:to_s).each do |key|
    it "serializes #{key}" do
      expect(json[key]).to eq progress.send(key)
    end
  end

  it "serializes id" do
    expect(json["id"]).to eq "1"
  end

  it "serializes url" do
    expect(json["url"]).to eq "http://example.com/api/v1/progress/1"
  end
end
