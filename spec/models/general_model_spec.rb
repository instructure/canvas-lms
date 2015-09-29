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
    !(@target.accessible_attributes.empty? && @target.protected_attributes.empty?)
  end

  def failure_message
    "expected #{@target} to protect attributes"
  end
#  alias_method :failure_message_for_should, :failure_message
end

def protect_attributes
  ProtectAttributes.new
end

describe 'Models' do
  it "should use attr_accessible or attr_protected" do
    ignore_classes = [
        ActiveRecord::Base,
        Delayed::Backend::ActiveRecord::Job,
        Delayed::Backend::ActiveRecord::Job::Failed,
        Version,
      ]
    if Object.const_defined?('ActiveRecord::SessionStore::Session')
      ignore_classes << ActiveRecord::SessionStore::Session
    end
    ignore_classes << AddThumbnailUuid::Thumbnail if Object.const_defined?('AddThumbnailUuid::Thumbnail')
    ignore_classes << Story if Object.const_defined?('Story')
    ignore_classes << CustomField if Object.const_defined?('CustomField')
    ignore_classes << CustomFieldValue if Object.const_defined?('CustomFieldValue')
    ignore_classes << RemoveQuizDataIds::QuizQuestion if Object.const_defined?('RemoveQuizDataIds::QuizQuestion')
    ignore_classes << Woozel if Object.const_defined?('Woozel')
    ActiveRecord::Base.all_models.each do |subclass|
      next unless subclass.name # unnamed class, probably from specs
      expect(subclass).to protect_attributes unless ignore_classes.include?(subclass)
    end
  end

  it "raises when you forget to use strong_params with a strong_params model" do

    expect { AccountAuthorizationConfig.new(WeakParameters.new(secret: 'ldap')) }.to(
      raise_error(ActiveModel::ForbiddenAttributesError)
    )
  end
end
