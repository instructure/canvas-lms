# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency 'canvas/jwt_workflow'

module Canvas
  describe JWTWorkflow do
    before(:each) do
      @c = Course.new
      @a = Account.new
      @c.account = @a
      @c.root_account = @a
      @u = User.new
      @a.save!
      @u.save!
      @c.save!
      @g = Group.new
      @g.context = @c
      @g.save!
      @g.add_user(@u)
    end

    describe 'register/state_for' do
      it 'uses block registerd with workflow to build state' do
        JWTWorkflow.register(:foo) { |c, u| { c: c, u: u } }
        state = JWTWorkflow.state_for(%i[foo], @c, @u)
        expect(state[:c]).to be(@c)
        expect(state[:u]).to be(@u)
      end

      it 'returns an empty hash if if workflow is not registered' do
        state = JWTWorkflow.state_for(%i[not_defined], @c, @u)
        expect(state).to be_empty
      end

      it 'merges state of muliple workflows in order of array' do
        JWTWorkflow.register(:foo) {{ a: 1, b: 2 }}
        JWTWorkflow.register(:bar) {{ b: 3, c: 4 }}
        expect(JWTWorkflow.state_for(%i[foo bar], nil, nil)).to include({ a: 1, b: 3, c: 4 })
        expect(JWTWorkflow.state_for(%i[bar foo], nil, nil)).to include({ a: 1, b: 2, c: 4 })
      end
    end

    describe 'workflows' do
      describe ':rich_content' do
        before(:each) do
          allow(@c).to receive(:respond_to?).with(:usage_rights_required?).and_return(true)
          allow(@c).to receive(:grants_any_right?)
          allow(@c).to receive(:feature_enabled?)
          @wiki = Wiki.new
          allow(@c).to receive(:wiki).and_return(@wiki)
          allow(@c).to receive(:respond_to?).with(:wiki).and_return(true)
          allow(@wiki).to receive(:grants_right?)
          allow(@g).to receive(:can_participate).and_return(true)

          # ensure disabled by default
          Account.default.root_account.disable_feature!(:granular_permissions_course_sections)
        end

        it 'sets can_upload_files to false' do
          expect(@c).to receive(:grants_any_right?).with(
            @u, :manage_files, :manage_files_add
          ).and_return(false)
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:can_upload_files]).to be false
        end

        it 'sets can_upload_files to true' do
          expect(@c).to receive(:grants_any_right?).with(
            @u, :manage_files, :manage_files_add
          ).and_return(true)
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:can_upload_files]).to be true
        end

        context 'with granular permissions enabled' do
          before :each do
            Account.default.root_account.enable_feature!(:granular_permissions_course_sections)
          end

          it 'sets can_upload_files to false' do
            expect(@c).to receive(:grants_any_right?).with(
              @u, :manage_files, :manage_files_add
            ).and_return(false)
            state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
            expect(state[:can_upload_files]).to be false
          end

          it 'sets can_upload_files to true' do
            expect(@c).to receive(:grants_any_right?).with(
              @u, :manage_files, :manage_files_add
            ).and_return(true)
            state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
            expect(state[:can_upload_files]).to be true
          end
        end

        it 'sets usage_rights_required to false' do
          @c.usage_rights_required = false
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:usage_rights_required]).to be false
        end

        it 'sets usage_rights_required to true' do
          @c.usage_rights_required = true
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:usage_rights_required]).to be true
        end

        it 'sets group usage_rights_required to false if false on its course' do
          @c.usage_rights_required = false
          state = JWTWorkflow.state_for(%i[rich_content], @g, @u)
          expect(state[:usage_rights_required]).to be false
        end

        it 'sets group usage_rights_required to true if true on its course' do
          @c.usage_rights_required = true
          state = JWTWorkflow.state_for(%i[rich_content], @g, @u)
          expect(state[:usage_rights_required]).to be true
        end

        it 'sets can_create_pages to false if context does not have a wiki' do
          expect(@c).to receive(:respond_to?).with(:wiki).and_return(false)
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:can_create_pages]).to be false
          expect(@c).to receive(:wiki_id).and_return(nil)
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:can_create_pages]).to be false
        end

        it 'sets can_create_pages to false if user does not have create_page rights' do
          @c.wiki_id = 1
          expect(@wiki).to receive(:grants_right?).with(@u, :create_page).and_return(false)
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:can_create_pages]).to be false
        end

        it 'sets can_create_pages to true if user has create_page rights' do
          @c.wiki_id = 1
          expect(@wiki).to receive(:grants_right?).with(@u, :create_page).and_return(true)
          state = JWTWorkflow.state_for(%i[rich_content], @c, @u)
          expect(state[:can_create_pages]).to be true
        end
      end

      describe ':ui' do
        before(:each) { allow(@u).to receive(:prefers_high_contrast?) }

        it 'sets use_high_contrast to true' do
          expect(@u).to receive(:prefers_high_contrast?).and_return(true)
          state = JWTWorkflow.state_for(%i[ui], @c, @u)
          expect(state[:use_high_contrast]).to be true
        end

        it 'sets use_high_contrast to false' do
          expect(@u).to receive(:prefers_high_contrast?).and_return(false)
          state = JWTWorkflow.state_for(%i[ui], @c, @u)
          expect(state[:use_high_contrast]).to be false
        end
      end
    end
  end
end
