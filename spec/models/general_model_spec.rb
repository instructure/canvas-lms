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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

class ProtectAttributes
  def matches?(target)
    @target = target
    !(@target.accessible_attributes.nil? && @target.protected_attributes.nil?)
  end
  def failure_message_for_should
    "expected #{@target} to protect attributes"
  end
end

def protect_attributes
  ProtectAttributes.new
end

describe 'Models' do

  context "config/initializers/active_record.rb" do

    it "should return the first descendant of ActiveRecord::Base when calling base_ar_class" do
      Account.base_ar_class.should == Account
      Group.base_ar_class.should == Group
      TeacherEnrollment.base_ar_class.should == Enrollment
    end
  end

  it "should use attr_accessible or attr_protected" do
    ignore_classes = [
        ActiveRecord::Base,
        ActiveRecord::SessionStore::Session,
        Delayed::Backend::ActiveRecord::Job,
        Delayed::Backend::ActiveRecord::Job::Failed,
        Version,
      ]
    (ignore_classes << AddThumbnailUuid::Thumbnail) rescue nil
    (ignore_classes << Story) rescue nil
    (ignore_classes << CustomField) rescue nil
    (ignore_classes << CustomFieldValue) rescue nil
    (ignore_classes << RemoveQuizDataIds::QuizQuestion) rescue nil
    (ignore_classes << Woozel) rescue nil
    ActiveRecord::Base.send(:subclasses).each do |subclass|
      next unless subclass.name # unnamed class, probably from specs
      subclass.should protect_attributes unless ignore_classes.include?(subclass)
    end
  end
end
