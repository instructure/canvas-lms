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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe OutcomeProficiencyApiController, type: :request do
  before :once do
    @user = user_with_pseudonym :active_all => true
    @account = Account.default
    @account_user = @account.account_users.create!(user: @user)
  end

  describe '.create' do
    let(:ratings) { [{ description: '1', points: 1, mastery: true, color: '000000' }] }
    let(:revoke_permissions) { false }

    def revoke_manage_outcomes
      RoleOverride.manage_role_override(@account, @account_user.role, 'manage_outcomes', :override => false)
    end

    before do
      revoke_manage_outcomes if revoke_permissions
      @json = api_call(:post,
       "/api/v1/accounts/#{@account.id}/outcome_proficiency",
       {
         controller: 'outcome_proficiency_api',
         action: 'create',
         format: 'json',
         account_id: @account.id.to_s
       },
       {
         ratings: ratings
       })
    end

    context 'missing permissions' do
      let(:revoke_permissions) { true }

      it 'returns 401 status' do
        assert_status(401)
      end

      it 'returns unauthorized message' do
        expect(@json.dig('errors', 0, 'message')).to eq 'user not authorized to perform that action'
      end
    end

    context 'invalid proficiencies' do
      shared_examples 'bad mastery ratings' do
        it 'returns 422 status' do
          assert_status(422)
        end

        it 'returns mastery error' do
          expect(@json.dig('errors', 0, 'message')).to eq 'Exactly one rating can have mastery'
        end
      end

      context 'empty ratings' do
        let(:ratings) { [] }

        it 'returns 422 status' do
          assert_status(422)
        end

        it 'returns missing required ratings error' do
          expect(@json.dig('errors', 0, 'message')).to eq 'Missing required ratings'
        end
      end

      context 'missing mastery rating' do
        let(:ratings) { [{ description: '1', points: 1, mastery: false, color: '000000' }] }

        include_examples 'bad mastery ratings'
      end

      context 'two mastery ratings' do
        let(:ratings) do
          [ { description: '1', points: 1, mastery: true, color: 'ff0000' },
            { description: '2', points: 2, mastery: true, color: '00ff00' } ]
        end

        include_examples 'bad mastery ratings'
      end
    end

    context 'valid proficiencies' do
      let(:ratings) { [{ description: '1', points: 1, mastery: true, color: '000000' }] }

      it 'returns 200 status' do
        assert_status(200)
      end

      it 'returns proficiency json' do
        expect(@json).to eq(@account.reload.outcome_proficiency.as_json)
      end

      it 'creates proficiency on account' do
        expect(@account.reload.outcome_proficiency).not_to be_nil
      end
    end

    context 'update proficiencies' do
      before do
        @proficiency = @account.outcome_proficiency
        api_call(:post,
          "/api/v1/accounts/#{@account.id}/outcome_proficiency",
          {
           controller: 'outcome_proficiency_api',
           action: 'create',
           format: 'json',
           account_id: @account.id.to_s
          },
          {
            ratings: updated_ratings
          })
        @proficiency.reload
      end

      shared_examples 'update ratings' do
        it 'returns 200 status' do
          assert_status(200)
        end

        it 'updates ratings' do
          expect(@proficiency.outcome_proficiency_ratings.count).to eq updated_ratings.length
          updated_ratings.each_with_index do |val, idx|
            expect(@proficiency.outcome_proficiency_ratings[idx].as_json.symbolize_keys).to eq val
          end
        end
      end

      context 'maintain same number of ratings' do
        let(:updated_ratings) do
          [ { description: '2', points: 2, mastery: true, color: '00ff00' },
            { description: '1', points: 1, mastery: false, color: 'ff0000' } ]
        end

        include_examples 'update ratings'
      end

      context 'increase number of ratings' do
        let(:updated_ratings) do
          [ { description: '2', points: 2, mastery: true, color: '00ff00' },
            { description: '1', points: 1, mastery: false, color: '0000ff' },
            { description: '0', points: 0, mastery: false, color: 'ff0000' } ]
        end

        include_examples 'update ratings'
      end

      context 'decrease number of ratings' do
        let(:updated_ratings) do
          [ { description: '2', points: 2, mastery: true, color: '000000' } ]
        end

        include_examples 'update ratings'
      end

      context 'empty ratings' do
        let(:updated_ratings) { [] }

        it 'does not delete previous ratings' do
          expect(@proficiency.outcome_proficiency_ratings.length).to eq 1
        end
      end
    end
  end

  describe '.show' do
    context 'no outcome proficiency' do
      it 'returns 404 status' do
        raw_api_call(:get,
          "/api/v1/accounts/#{@account.id}/outcome_proficiency",
          { :controller => 'outcome_proficiency_api', :action => 'show',
            :format => 'json', :account_id => @account.id.to_s })
        assert_status(404)
      end
    end

    context 'account outcome proficiency' do
      before :once do
        @proficiency = outcome_proficiency_model(@account)
      end

      it 'returns proficiency' do
        json = api_call(:get,
          "/api/v1/accounts/#{@account.id}/outcome_proficiency",
          { :controller => 'outcome_proficiency_api', :action => 'show',
            :format => 'json', :account_id => @account.id.to_s })
        expect(json).to eq(@proficiency.as_json)
      end

      it "returns 200 status" do
        raw_api_call(:get,
          "/api/v1/accounts/#{@account.id}/outcome_proficiency",
          { :controller => 'outcome_proficiency_api', :action => 'show',
            :format => 'json', :account_id => @account.id.to_s })
        assert_status(200)
      end
    end
  end
end
