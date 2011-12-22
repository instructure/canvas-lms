#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')

describe "API", :type => :integration do
  describe "Api::V1::Json" do
    it "should merge user options with the default api behavior" do
      obj = Object.new
      obj.extend Api::V1::Json
      course_with_teacher
      session = mock()
      @course.expects(:as_json).with({ :include_root => false, :permissions => { :user => @user, :session => session, :include_permissions => false }, :only => [ :name, :sis_source_id ] })
      obj.api_json(@course, @user, session, :only => [:name, :sis_source_id])
    end
  end

  describe "as_json extensions" do
    it "should skip attribute filtering if obj doesn't respond" do
      course_with_teacher
      @course.respond_to?(:filter_attributes_for_user).should be_false
      @course.as_json(:include_root => false, :permissions => { :user => @user }, :only => %w(name sis_source_id)).keys.sort.should == %w(name permissions sis_source_id)
    end

    it "should do attribute filtering if obj responds" do
      course_with_teacher
      def @course.filter_attributes_for_user(hash, user, session)
        user.should == self.teachers.first
        session.should == nil
        hash.delete('sis_source_id')
      end
      @course.as_json(:include_root => false, :permissions => { :user => @user }, :only => %w(name sis_source_id)).keys.sort.should == %w(name permissions)
    end

    it "should not return the permissions list if include_permissions is false" do
      course_with_teacher
      @course.as_json(:include_root => false, :permissions => { :user => @user, :include_permissions => false }, :only => %w(name sis_source_id)).keys.sort.should == %w(name sis_source_id)
    end
  end
end
