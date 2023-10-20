# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Wiki do
  before :once do
    course_factory
    @wiki = @course.wiki
  end

  context "unset_front_page!" do
    it "unsets front page" do
      @course.default_view = "wiki"
      @wiki.unset_front_page!

      expect(@wiki.has_front_page?).to be false
      expect(@wiki.front_page_url).to be_nil
      expect(@wiki.course.default_view).to eq @wiki.course.default_home_page
    end
  end

  context "set_front_page_url!" do
    it "sets front_page_url" do
      @wiki.unset_front_page!
      new_url = "ponies4ever"
      expect(@wiki.set_front_page_url!(new_url)).to be true

      expect(@wiki.has_front_page?).to be true
      expect(@wiki.front_page_url).to eq new_url
    end
  end

  context "front_page" do
    it "builds a custom front page if not found" do
      new_url = "whyyyyy"
      @wiki.set_front_page_url!(new_url)

      page = @wiki.front_page
      expect(page.new_record?).to be true
      expect(page.url).to eq new_url
    end

    it "finds front_page by url" do
      page = @course.wiki_pages.create!(title: "stuff and stuff")

      @wiki.set_front_page_url!(page.url)
      expect(page).to eq @wiki.front_page
    end

    it "finds front_page by default url (legacy support)" do
      page = @course.wiki_pages.create!(title: "front page")
      page.update_attribute(:url, Wiki::DEFAULT_FRONT_PAGE_URL)
      @wiki.update_attribute(:has_no_front_page, false)

      expect(page).to eq @wiki.front_page
    end
  end

  context "set policy" do
    before :once do
      @course.offer!
      user_factory active_all: true
    end

    it "gives read rights to public courses" do
      @course.is_public = true
      @course.save!
      expect(@course.wiki.grants_right?(@user, :read)).to be_truthy
    end

    it "does not give read rights to unpublished public courses" do
      @course.workflow_state = "claimed"
      @course.is_public = true
      @course.save!
      expect(@course.wiki.grants_right?(@user, :read)).to be_falsey
    end

    context "default permissions" do
      %i[update create_page delete_page update_page view_unpublished_items].each do |perm|
        it "gives #{perm} rights to teachers" do
          course_with_teacher
          expect(@course.wiki.grants_right?(@teacher, perm)).to be_truthy
        end

        it "gives #{perm} rights to admins" do
          account_admin_user
          expect(@course.wiki.grants_right?(@admin, perm)).to be_truthy
        end
      end
    end

    it "gives publish page rights to admins" do
      account_admin_user
      expect(@course.wiki.grants_right?(@admin, :publish_page)).to be_truthy
    end

    it "does not give publish page rights to admins when the context is a group" do
      account_admin_user
      group
      expect(@group.wiki.grants_right?(@admin, :publish_page)).to be_falsey
    end

    context "allow student wiki edits" do
      before :once do
        course_with_student course: @course, user: @user, active_all: true
        @course.default_wiki_editing_roles = "teachers,students"
        @course.save!
      end

      it "does not give manage rights to students" do
        expect(@course.wiki.grants_right?(@user, :manage)).to be_falsey
      end

      it "does not give update rights to students" do
        expect(@course.wiki.grants_right?(@user, :update)).to be_falsey
      end

      it "gives read rights to students" do
        expect(@course.wiki.grants_right?(@user, :read)).to be_truthy
      end

      it "gives create_page rights to students" do
        expect(@course.wiki.grants_right?(@user, :create_page)).to be_truthy
      end

      it "does not give publish page rights to students" do
        expect(@course.wiki.grants_right?(@user, :publish_page)).to be_falsey
      end

      it "does not give publish page rights to students when the context is a group" do
        group
        expect(@group.wiki.grants_right?(@user, :publish_page)).to be_falsey
      end

      it "does not give delete_page rights to students" do
        expect(@course.wiki.grants_right?(@user, :delete_page)).to be_falsey
      end

      it "gives update_page rights to students" do
        expect(@course.wiki.grants_right?(@user, :update_page)).to be_truthy
      end
    end
  end

  context "find_page" do
    before :once do
      @page1 = @course.wiki_pages.create!(title: "Some Page")
      @pageN = @course.wiki_pages.create!(title: @page1.id.to_s)
    end

    it "finds page by URL" do
      expect(@wiki.find_page("some-page")).to eq @page1
    end

    it "finds page by title" do
      expect(@wiki.find_page("Some Page")).to eq @page1
    end

    it "falls back to ID if url/title don't match" do
      expect(@wiki.find_page(@page1.id.to_s)).to eq @pageN
      expect(@wiki.find_page(@pageN.id.to_s)).to eq @pageN
    end

    it "finds page by ID specifically with page_id:N" do
      expect(@wiki.find_page("page_id:#{@page1.id}")).to eq @page1
    end
  end

  context "find_page by lookup" do
    before :once do
      Account.site_admin.enable_feature!(:permanent_page_links)
      @page1 = @course.wiki_pages.create!(title: "Current Page")
      @lookup1 = @page1.current_lookup
      @lookup2 = WikiPageLookup.create!(slug: "old-url", wiki_page: @page1, root_account_id: @page1.root_account_id, context_id: @page1.context_id, context_type: @page1.context_type)
    end

    it "finds page by title" do
      expect(@wiki.find_page("Current Page")).to eq @page1
    end

    it "finds page by stale url" do
      expect(@wiki.find_page("old-url")).to eq @page1
    end

    it "doesn't include deleted page" do
      @page1.destroy
      expect(@wiki.find_page("Current Page")).to be_nil
    end

    it "can find deleted page if requested" do
      @page1.destroy
      expect(@wiki.find_page("Current Page", include_deleted: true)).to eq @page1
    end
  end

  it "#context_loaded?" do
    group
    wiki = @group.wiki
    expect(wiki.reload.context_loaded?).to be_falsey
  end

  context "sharding" do
    specs_require_sharding

    it "finds the wiki's context from another shard" do
      @shard1.activate do
        expect(@wiki.context).to eq @course
      end
    end
  end

  context "before save" do
    describe "set_root_account_id" do
      it "sets root_account_id using context" do
        expect(@wiki.root_account_id).to eq @course.root_account_id
      end
    end
  end

  describe "#build_wiki_page" do
    let(:created_page) { wiki.build_wiki_page(user, opts) }

    let(:user) do
      account_admin_user
      @user
    end

    let(:wiki) { @wiki }
    let(:opts) { {} }

    context "with Latin title" do
      let(:opts) { { title: "Hello World" } }

      it "Uses that latin title in the URL" do
        expect(created_page.url).to eq "hello-world"
      end

      context "with reserved URL chars" do
        let(:opts) { { title: "?&Hello World" } }

        it "Removes or replaces the reserved chars" do
          expect(created_page.url).to eq "and-hello-world"
        end
      end
    end

    context "with Katakana title" do
      let(:opts) { { title: "グループ映画プロジェクトの概要" } }

      it "uses the unicode characters" do
        expect(created_page.url).to eq "グループ映画プロジェクトの概要"
      end

      context "with reserved URL chars" do
        let(:opts) { { title: "?&グループ映画プロジェクトの概要" } }

        it "uses the unicode characters" do
          expect(created_page.url).to eq "and グループ映画プロジェクトの概要"
        end
      end

      context "with Latin characters mixed in" do
        let(:opts) { { title: "グループ映画プロジェクトの概要hello" } }

        it "uses the unicode characters" do
          expect(created_page.url).to eq "グループ映画プロジェクトの概要hello"
        end
      end
    end
  end
end
