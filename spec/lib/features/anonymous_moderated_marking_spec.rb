#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../spec_helper.rb'

describe 'anonymous moderated marking' do
  let(:root_account) { account_model }
  let(:course) { course_factory(account: root_account, active_all: true) }
  let(:anonymous_grading_feature) { Feature.definitions['anonymous_marking'] }

  describe 'anonymous grading flag' do
    context 'when the base AMM flag is not enabled' do
      it 'is not allowed on the account level' do
        expect(root_account).not_to be_feature_allowed(:anonymous_marking)
      end

      it 'is not visible on the account level' do
        expect(anonymous_grading_feature.visible_on.call(root_account)).to be_falsey
      end

      it 'is not allowed on the course level' do
        expect(course).not_to be_feature_allowed(:anonymous_marking)
      end

      it 'is not visible on the course level' do
        expect(anonymous_grading_feature.visible_on.call(course)).to be_falsey
      end
    end

    context 'when the base AMM flag is enabled' do
      before(:each) do
        root_account.enable_feature!(:anonymous_moderated_marking)
      end

      it 'is visible on the account level' do
        expect(anonymous_grading_feature.visible_on.call(root_account)).to be_truthy
      end

      it 'is visible on the course level' do
        expect(anonymous_grading_feature.visible_on.call(course)).to be_truthy
      end

      it 'is allowed on the course level if allowed on the account level' do
        root_account.allow_feature!(:anonymous_marking)
        expect(course).to be_feature_allowed(:anonymous_marking)
      end

      it 'is enabled on the course level if enabled on the account level' do
        root_account.enable_feature!(:anonymous_marking)
        expect(course).to be_feature_enabled(:anonymous_marking)
      end
    end
  end
end
