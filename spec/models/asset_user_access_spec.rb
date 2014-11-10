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
    expect(@asset.display_name).to eq "My Assignment"
  end

  it "should update existing records that have changed display names" do
    @assignment.title = 'My changed Assignment'
    @assignment.save!
    @asset.log @course, { :level => 'view' }
    expect(@asset.display_name).to eq 'My changed Assignment'
  end

  describe "for_user" do
    it "should work with a User object" do
      expect(AssetUserAccess.for_user(@user)).to eq [@asset]
    end

    it "should work with a list of User objects" do
      expect(AssetUserAccess.for_user([@user])).to eq [@asset]
    end

    it "should work with a User id" do
      expect(AssetUserAccess.for_user(@user.id)).to eq [@asset]
    end

    it "should work with a list of User ids" do
      expect(AssetUserAccess.for_user([@user.id])).to eq [@asset]
    end

    it "should with with an empty list" do
      expect(AssetUserAccess.for_user([])).to eq []
    end

    it "should not find unrelated accesses" do
      expect(AssetUserAccess.for_user(User.create!)).to eq []
      expect(AssetUserAccess.for_user(@user.id + 1)).to eq []
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

          describe '#view_score' do
            subject { super().view_score }
            it { is_expected.to eq 1 }
          end

          describe '#participate_score' do
            subject { super().participate_score }
            it { is_expected.to be_nil }
          end

          describe '#action_level' do
            subject { super().action_level }
            it { is_expected.to eq 'view' }
          end
        end

        describe 'participate level' do
          before { asset.log_action 'participate' }

          describe '#view_score' do
            subject { super().view_score }
            it { is_expected.to eq 1 }
          end

          describe '#participate_score' do
            subject { super().participate_score }
            it { is_expected.to eq 1 }
          end

          describe '#action_level' do
            subject { super().action_level }
            it { is_expected.to eq 'participate' }
          end
        end

        describe 'submit level' do
          before { asset.log_action 'submit' }

          describe '#view_score' do
            subject { super().view_score }
            it { is_expected.to be_nil }
          end

          describe '#participate_score' do
            subject { super().participate_score }
            it { is_expected.to eq 1 }
          end

          describe '#action_level' do
            subject { super().action_level }
            it { is_expected.to eq 'participate' }
          end
        end
      end

      describe 'with existing scores' do
        before { asset.view_score = asset.participate_score = 3 }

        describe 'view level' do
          before { asset.log_action 'view' }

          describe '#view_score' do
            subject { super().view_score }
            it { is_expected.to eq 4 }
          end

          describe '#participate_score' do
            subject { super().participate_score }
            it { is_expected.to eq 3 }
          end

          describe '#action_level' do
            subject { super().action_level }
            it { is_expected.to eq 'view' }
          end
        end

        describe 'participate level' do
          before { asset.log_action 'participate' }

          describe '#view_score' do
            subject { super().view_score }
            it { is_expected.to eq 4 }
          end

          describe '#participate_score' do
            subject { super().participate_score }
            it { is_expected.to eq 4 }
          end

          describe '#action_level' do
            subject { super().action_level }
            it { is_expected.to eq 'participate' }
          end
        end

        describe 'submit level' do
          before { asset.log_action 'submit' }

          describe '#view_score' do
            subject { super().view_score }
            it { is_expected.to eq 3 }
          end

          describe '#participate_score' do
            subject { super().participate_score }
            it { is_expected.to eq 4 }
          end

          describe '#action_level' do
            subject { super().action_level }
            it { is_expected.to eq 'participate' }
          end
        end
      end
    end

    describe 'when action level is view' do
      before { asset.action_level = 'view' }

      it 'gets overridden by participate' do
        asset.log_action 'participate'
        expect(asset.action_level).to eq 'participate'
      end

      it 'gets overridden by submit' do
        asset.log_action 'submit'
        expect(asset.action_level).to eq 'participate'
      end
    end

    it 'does not overwrite the participate level with view' do
      asset.action_level = 'participate'
      asset.log_action 'view'
      expect(asset.action_level).to eq 'participate'
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
        expect(access.send(attribute)).to eq 'value'
        access.send("#{attribute}=", 'other')
        access.log(context, { hash_key => 'value' })
        expect(access.send(attribute)).to eq 'other'
      end

      specify { it_sets_if_nil( :asset_category, :category ) }
      specify { it_sets_if_nil( :asset_group_code, :group_code ) }
      specify { it_sets_if_nil( :membership_type ) }
    end

    describe 'interally set or calculated attribute values' do
      before { access.log context, { :level => 'view' } }

      describe '#context' do
        subject { super().context }
        it { is_expected.to eq context }
      end

      describe '#summarized_at' do
        subject { super().summarized_at }
        it { is_expected.to be_nil }
      end

      describe '#last_access' do
        subject { super().last_access }
        it { is_expected.not_to be_nil }
      end

      describe '#view_score' do
        subject { super().view_score }
        it { is_expected.to eq 1 }
      end

      describe '#participate_score' do
        subject { super().participate_score }
        it { is_expected.to be_nil }
      end

      describe '#action_level' do
        subject { super().action_level }
        it { is_expected.to eq 'view' }
      end
    end

  end

  describe '#corrected_view_score' do
    it 'should deduct the participation score from the view score for a quiz' do
      subject.view_score = 10
      subject.participate_score = 4
      subject.asset_group_code = 'quizzes'

      expect(subject.corrected_view_score).to eq 6
    end

    it 'should return the normal view score for anything but a quiz' do
      subject.view_score = 10
      subject.participate_score = 4

      expect(subject.corrected_view_score).to eq 10
    end

    it 'should not complain if there is no current score' do
      subject.view_score = nil
      subject.participate_score = 4
      subject.stubs(:asset_group_code).returns('quizzes')

      expect(subject.corrected_view_score).to eq -4
    end
  end
end
