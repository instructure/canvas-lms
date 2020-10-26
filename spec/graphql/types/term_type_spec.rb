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

describe Types::TermType do

  before(:once) do
    course_with_student(active_all: true)
    @term = @course.enrollment_term
    @term_type = GraphQLTypeTester.new(@term, current_user: @teacher)
    @admin = account_admin_user
  end

  it "works" do
    expect(@term_type.resolve("_id", current_user: @teacher)).to eq @term.id.to_s
    expect(@term_type.resolve("name", current_user: @teacher)).to eq @term.name
  end

  it "requires read permission" do
    expect(@term_type.resolve("_id", current_user: @student)).to be_nil
  end

  it 'should have coursesConnection' do
    expect(@term_type.resolve("coursesConnection { nodes { _id } }", current_user: @admin)).to eq [@course.id.to_s]
  end

  it 'should require admin privilege' do
    expect(@term_type.resolve("coursesConnection { nodes { _id } }", current_user: @student)).to be_nil
  end

  context "sis field" do
    before(:once) do
      @term.update!(sis_source_id: "sisTerm")
    end

    let(:manage_admin) { account_admin_user_with_role_changes(role_changes: { read_sis: false })}
    let(:read_admin) { account_admin_user_with_role_changes(role_changes: { manage_sis: false })}

    it "returns sis_id if you have read_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: read_admin}).dig("data", "term", "sisId")
          query { term(id: "#{@term.id}") { sisId } }
        GQL
      ).to eq("sisTerm")
    end

    it "returns sis_id if you have manage_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: manage_admin}).dig("data", "term", "sisId")
          query { term(id: "#{@term.id}") { sisId } }
        GQL
      ).to eq("sisTerm")
    end

    it "doesn't return sis_id if you don't have read_sis or management_sis permissions" do
      expect(
        CanvasSchema.execute(<<~GQL, context: { current_user: @teacher}).dig("data", "term", "sisId")
          query { term(id: "#{@term.id}") { sisId } }
        GQL
      ).to be_nil
    end
  end

end
