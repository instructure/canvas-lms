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

describe CanvasSecurity::JWTWorkflow do
  before do
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

  describe "workflows" do
    describe ":rich_content" do
      before do
        allow(@c).to receive(:respond_to?).with(:usage_rights_required?).and_return(true)
        allow(@c).to receive(:grants_right?)
        allow(@c).to receive(:feature_enabled?)
        @wiki = Wiki.new
        allow(@c).to receive(:wiki).and_return(@wiki)
        allow(@c).to receive(:respond_to?).with(:wiki).and_return(true)
        allow(@wiki).to receive(:grants_right?)
        allow(@g).to receive(:can_participate).and_return(true)
      end

      it "sets can_upload_files to false" do
        expect(@c).to receive(:grants_right?).with(@u, :manage_files_add).and_return(false)
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:can_upload_files]).to be false
      end

      it "sets can_upload_files to true" do
        expect(@c).to receive(:grants_right?).with(@u, :manage_files_add).and_return(true)
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:can_upload_files]).to be true
      end

      it "sets usage_rights_required to false" do
        @c.usage_rights_required = false
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:usage_rights_required]).to be false
      end

      it "sets usage_rights_required to true" do
        @c.usage_rights_required = true
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:usage_rights_required]).to be true
      end

      it "sets group usage_rights_required to false if false on its course" do
        @c.usage_rights_required = false
        state = described_class.state_for(%i[rich_content], @g, @u)
        expect(state[:usage_rights_required]).to be false
      end

      it "sets group usage_rights_required to true if true on its course" do
        @c.usage_rights_required = true
        state = described_class.state_for(%i[rich_content], @g, @u)
        expect(state[:usage_rights_required]).to be true
      end

      it "sets can_create_pages to false if context does not have a wiki" do
        expect(@c).to receive(:respond_to?).with(:wiki).and_return(false)
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:can_create_pages]).to be false
        expect(@c).to receive(:wiki_id).and_return(nil)
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:can_create_pages]).to be false
      end

      it "sets can_create_pages to false if user does not have create_page rights" do
        @c.wiki_id = 1
        expect(@wiki).to receive(:grants_right?).with(@u, :create_page).and_return(false)
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:can_create_pages]).to be false
      end

      it "sets can_create_pages to true if user has create_page rights" do
        @c.wiki_id = 1
        expect(@wiki).to receive(:grants_right?).with(@u, :create_page).and_return(true)
        state = described_class.state_for(%i[rich_content], @c, @u)
        expect(state[:can_create_pages]).to be true
      end
    end

    describe ":ui" do
      before { allow(@u).to receive(:prefers_high_contrast?) }

      it "sets use_high_contrast to true" do
        expect(@u).to receive(:prefers_high_contrast?).and_return(true)
        state = described_class.state_for(%i[ui], @c, @u)
        expect(state[:use_high_contrast]).to be true
      end

      it "sets use_high_contrast to false" do
        expect(@u).to receive(:prefers_high_contrast?).and_return(false)
        state = described_class.state_for(%i[ui], @c, @u)
        expect(state[:use_high_contrast]).to be false
      end
    end
  end
end
