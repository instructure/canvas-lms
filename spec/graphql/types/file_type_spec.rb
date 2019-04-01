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

describe Types::FileType do
  let_once(:course) { course_with_teacher(active_all: true); @course }
  let_once(:student) { student_in_course(course: @course) }
  let_once(:file) { attachment_with_context(course) }
  let(:file_type) { GraphQLTypeTester.new(file, current_user: @teacher) }

  it 'works' do
    expect(file_type.resolve('displayName')).to eq file.display_name
  end

  it 'has modules' do
    module1 = course.context_modules.create!(name: 'Module 1')
    module2 = course.context_modules.create!(name: 'Module 2')
    file.context_module_tags.create!(context_module: module1, context: course, tag_type: 'context_module')
    file.context_module_tags.create!(context_module: module2, context: course, tag_type: 'context_module')
    expect(file_type.resolve('modules { _id }').sort).to eq [module1.id.to_s, module2.id.to_s]
  end

  it 'requires read permission' do
    other_course_student = student_in_course(course: course_factory).user
    resolver = GraphQLTypeTester.new(file, current_user: other_course_student)
    expect(resolver.resolve("_id")).to be_nil
  end

  it 'requires the file to not be deleted' do
    file.destroy
    expect(file_type.resolve('displayName')).to be_nil
  end

  it 'return the url if the file is not locked' do
    expect(
      file_type.resolve('url', request: ActionDispatch::TestRequest.create, current_user: @student)
    ).to eq "http://test.host/files/#{file.id}/download?download_frd=1"
  end

  it 'returns nil for the url if the file is locked' do
    file.locked = true
    file.save!
    expect(
      file_type.resolve('url', request: ActionDispatch::TestRequest.create, current_user: @student)
    ).to be_nil
  end
end
