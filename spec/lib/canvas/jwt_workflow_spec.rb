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
require_dependency "canvas/jwt_workflow"

module Canvas
  describe JWTWorkflow do
    before(:each) do
      @c = Course.new
      @u = User.new
    end

    describe 'register/state_for' do
      it 'uses block registerd with workflow to build state' do
        JWTWorkflow.register(:foo) do |c, u|
          {c: c, u: u}
        end
        state = JWTWorkflow.state_for([:foo], @c, @u)
        expect(state[:c]).to be(@c)
        expect(state[:u]).to be(@u)
      end

      it 'returns an empty hash if if workflow is not registered' do
        state = JWTWorkflow.state_for([:not_defined], @c, @u)
        expect(state).to be_empty
      end

      it 'merges state of muliple workflows in order of array' do
        JWTWorkflow.register(:foo) do |c, u|
          {a: 1, b:2}
        end
        JWTWorkflow.register(:bar) do |c, u|
          {b: 3, c: 4}
        end
        expect(JWTWorkflow.state_for([:foo, :bar], nil, nil)).to include(
          {a: 1, b: 3, c: 4}
        )
        expect(JWTWorkflow.state_for([:bar, :foo], nil, nil)).to include(
          {a: 1, b: 2, c: 4}
        )
      end
    end

    describe 'workflows' do
      describe ':rich_content' do
        before(:each) do
          @c.stubs(:grants_right?)
          @c.stubs(:feature_enabled?)
          @wiki = Wiki.new
          @c.stubs(:wiki).returns(@wiki)
          @c.stubs(:respond_to?).with(:wiki).returns(true)
          @wiki.stubs(:grants_right?)
        end

        it 'sets can_upload_files to false' do
          @c.expects(:grants_right?).with(@u, :manage_files).returns(false)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:can_upload_files]).to be false
        end

        it 'sets can_upload_files to true' do
          @c.expects(:grants_right?).with(@u, :manage_files).returns(true)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:can_upload_files]).to be true
        end

        it 'sets usage_rights_required to false' do
          @c.expects(:feature_enabled?).with(:usage_rights_required).returns(false)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:usage_rights_required]).to be false
        end

        it 'sets usage_rights_required to true' do
          @c.expects(:feature_enabled?).with(:usage_rights_required).returns(true)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:usage_rights_required]).to be true
        end

        it 'sets can_create_pages to false if context does not have a wiki' do
          @c.expects(:respond_to?).with(:wiki).returns(false)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:can_create_pages]).to be false
          @c.expects(:wiki_id).returns(nil)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:can_create_pages]).to be false
        end

        it 'sets can_create_pages to false if user does not have create_page rights' do
          @c.wiki_id = 1
          @wiki.expects(:grants_right?).with(@u, :create_page).returns(false)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:can_create_pages]).to be false
        end

        it 'sets can_create_pages to true if user has create_page rights' do
          @c.wiki_id = 1
          @wiki.expects(:grants_right?).with(@u, :create_page).returns(true)
          state = JWTWorkflow.state_for([:rich_content], @c, @u)
          expect(state[:can_create_pages]).to be true
        end
      end

      describe ':ui' do
        before(:each) do
          @u.stubs(:prefers_high_contrast?)
        end

        it 'sets use_high_contrast to true' do
          @u.expects(:prefers_high_contrast?).returns(true)
          state = JWTWorkflow.state_for([:ui], @c, @u)
          expect(state[:use_high_contrast]).to be true
        end

        it 'sets use_high_contrast to false' do
          @u.expects(:prefers_high_contrast?).returns(false)
          state = JWTWorkflow.state_for([:ui], @c, @u)
          expect(state[:use_high_contrast]).to be false
        end
      end
    end
  end
end
