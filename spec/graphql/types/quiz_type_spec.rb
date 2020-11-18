# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe Types::QuizType do
  let_once(:quiz) { quiz_model }
  let(:quiz_type) { GraphQLTypeTester.new(quiz, current_user: @teacher) }

  it "works" do
    expect(quiz_type.resolve("_id")).to eq quiz.id.to_s
  end

  it "has modules" do
    module1 = quiz.context.context_modules.create!(name: 'Module 1')
    module2 = quiz.context.context_modules.create!(name: 'Module 2')
    quiz.context_module_tags.create!(context_module: module1, context: quiz.context, tag_type: 'context_module')
    quiz.context_module_tags.create!(context_module: module2, context: quiz.context, tag_type: 'context_module')
    expect(quiz_type.resolve("modules { _id }")).to match_array([module1.id.to_s, module2.id.to_s])
  end
end
