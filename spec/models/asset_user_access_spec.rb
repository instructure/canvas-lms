#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe AssetUserAccess do
  before :once do
    @course = Account.default.courses.create!(:name => 'My Course')
    @assignment = @course.assignments.create!(:title => 'My Assignment')
    @user = User.create!

    @asset = factory_with_protected_attributes(AssetUserAccess, :user => @user, :context => @course, :asset_code => @assignment.asset_string)
    @asset.display_name = @assignment.asset_string
    @asset.save!
  end

  it "should update existing records that have bad display names" do
    @asset.display_name.should == "My Assignment"
  end

  it "should update existing records that have changed display names" do
    @assignment.title = 'My changed Assignment'
    @assignment.save!
    @asset.log @course, { :level => 'view' }
    @asset.display_name.should == 'My changed Assignment'
  end

  describe "for_user" do
    it "should work with a User object" do
      AssetUserAccess.for_user(@user).should == [@asset]
    end

    it "should work with a list of User objects" do
      AssetUserAccess.for_user([@user]).should == [@asset]
    end

    it "should work with a User id" do
      AssetUserAccess.for_user(@user.id).should == [@asset]
    end

    it "should work with a list of User ids" do
      AssetUserAccess.for_user([@user.id]).should == [@asset]
    end

    it "should with with an empty list" do
      AssetUserAccess.for_user([]).should == []
    end

    it "should not find unrelated accesses" do
      AssetUserAccess.for_user(User.create!).should == []
      AssetUserAccess.for_user(@user.id + 1).should == []
    end
  end

  describe '#log_action' do
    let(:scores) { Hash.new }
    let(:asset) { AssetUserAccess.new(scores) }

    subject { asset }

    describe 'when action level is nil' do
      describe 'with nil scores' do
        describe 'view level' do
          before { asset.log_action 'view' }
          its(:view_score) { should == 1 }
          its(:participate_score) { should be_nil }
          its(:action_level) { should == 'view' }
        end

        describe 'participate level' do
          before { asset.log_action 'participate' }
          its(:view_score) { should == 1 }
          its(:participate_score) { should == 1 }
          its(:action_level) { should == 'participate' }
        end

        describe 'submit level' do
          before { asset.log_action 'submit' }
          its(:view_score) { should be_nil }
          its(:participate_score) { should == 1 }
          its(:action_level) { should == 'participate' }
        end
      end

      describe 'with existing scores' do
        before { asset.view_score = asset.participate_score = 3 }

        describe 'view level' do
          before { asset.log_action 'view' }
          its(:view_score) { should == 4 }
          its(:participate_score) { should == 3 }
          its(:action_level) { should == 'view' }
        end

        describe 'participate level' do
          before { asset.log_action 'participate' }
          its(:view_score) { should == 4 }
          its(:participate_score) { should == 4 }
          its(:action_level) { should == 'participate' }
        end

        describe 'submit level' do
          before { asset.log_action 'submit' }
          its(:view_score) { should == 3 }
          its(:participate_score) { should == 4 }
          its(:action_level) { should == 'participate' }
        end
      end
    end

    describe 'when action level is view' do
      before { asset.action_level = 'view' }

      it 'gets overridden by participate' do
        asset.log_action 'participate'
        asset.action_level.should == 'participate'
      end

      it 'gets overridden by submit' do
        asset.log_action 'submit'
        asset.action_level.should == 'participate'
      end
    end

    it 'does not overwrite the participate level with view' do
      asset.action_level = 'participate'
      asset.log_action 'view'
      asset.action_level.should == 'participate'
    end
  end

  describe '#log' do
    let(:access) { AssetUserAccess.new }
    let(:context) { User.new }
    subject { access }

    before { access.stubs :save }

    describe 'attribute values directly from hash' do
      def it_sets_if_nil( attribute, hash_key = nil)
        hash_key ||= attribute
        access.log(context, { hash_key => 'value' })
        access.send(attribute).should == 'value'
        access.send("#{attribute}=", 'other')
        access.log(context, { hash_key => 'value' })
        access.send(attribute).should == 'other'
      end

      specify { it_sets_if_nil( :asset_category, :category ) }
      specify { it_sets_if_nil( :asset_group_code, :group_code ) }
      specify { it_sets_if_nil( :membership_type ) }
    end

    describe 'interally set or calculated attribute values' do
      before { access.log context, { :level => 'view' } }
      its(:context) { should == context }
      its(:summarized_at) { should be_nil }
      its(:last_access) { should_not be_nil }
      its(:view_score) { should == 1 }
      its(:participate_score) { should be_nil }
      its(:action_level) { should == 'view' }
    end

  end

  describe '#corrected_view_score' do
    it 'should deduct the participation score from the view score for a quiz' do
      subject.view_score = 10
      subject.participate_score = 4
      subject.asset_group_code = 'quizzes'

      subject.corrected_view_score.should == 6
    end

    it 'should return the normal view score for anything but a quiz' do
      subject.view_score = 10
      subject.participate_score = 4

      subject.corrected_view_score.should == 10
    end

    it 'should not complain if there is no current score' do
      subject.view_score = nil
      subject.participate_score = 4
      subject.stubs(:asset_group_code).returns('quizzes')

      subject.corrected_view_score.should == -4
    end
  end
end
