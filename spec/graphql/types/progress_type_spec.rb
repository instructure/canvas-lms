# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative "../graphql_spec_helper"

describe Types::ProgressType do
  before(:once) do
    course_with_teacher(active_all: true)
    @progress = Progress.create!(context: @course, tag: "gradebook_upload")
  end

  let(:progress_type) { GraphQLTypeTester.new(@progress, current_user: @teacher) }

  context "top-level permissions" do
    it "needs read permission on the context" do
      rando = user_factory(active_all: true)
      expect(progress_type.resolve("_id", current_user: rando)).to be_nil
    end
  end

  it "works" do
    expect(progress_type.resolve("_id")).to eql @progress.id.to_s
    expect(progress_type.resolve("tag")).to eql @progress.tag
    expect(progress_type.resolve("completion")).to be_nil
    expect(progress_type.resolve("state")).to eql "queued"
    expect(progress_type.resolve("context { ... on Course { _id } }")).to eql @progress.context.id.to_s
  end
end
