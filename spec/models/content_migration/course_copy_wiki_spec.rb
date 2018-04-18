#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy wiki" do
    include_examples "course copy"

    it "should copy wiki page attributes" do
      page = @copy_from.wiki_pages.create!(:title => "title", :body => "<p>butter</p>",
                                                :editing_roles => "teachers", :todo_date => Time.zone.now)

      run_course_copy

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first

      attrs = [:title, :body, :editing_roles, :todo_date]
      expect(page.attributes.slice(*attrs)).to eq page_to.attributes.slice(*attrs)
    end

    it "should reset user on re-import" do
      page = @copy_from.wiki_pages.create!(:title => "reset me", :body => "<p>blah</p>")

      run_course_copy

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      page_to.body = "something else"
      page_to.user = user_factory
      page_to.save!

      run_course_copy

      page_to.reload
      expect(page_to.user).to be_nil
      expect(page_to.body).to eq page.body
    end

    it "should not escape links to wiki urls" do
      page1 = @copy_from.wiki_pages.create!(:title => "keepthese%20percent signs", :body => "blah")

      body = %{<p>Link to module item: <a href="/courses/%s/pages/%s#header">some assignment</a></p>}
      page2 = @copy_from.wiki_pages.create!(:title => "some page", :body => body % [@copy_from.id, page1.url])

      run_course_copy

      page1_to = @copy_to.wiki_pages.where(migration_id: mig_id(page1)).first
      page2_to = @copy_to.wiki_pages.where(migration_id: mig_id(page2)).first

      new_body = body % [@copy_to.id, page1_to.url]
      expect(page2_to.body).to eq new_body
      expect(page2_to.versions.first.model.body).to eq new_body
    end

    it "should find and fix wiki links by title or id" do
      # simulating what happens when the user clicks "link to new page" and enters a title that isn't
      # urlified the same way by the client vs. the server.  this doesn't break navigation because
      # ApplicationController#get_wiki_page can match by urlified title, but it broke import (see #9945)
      @copy_from.wiki.set_front_page_url!('front-page')
      main_page = @copy_from.wiki.front_page
      main_page.body = %{<a href="/courses/#{@copy_from.id}/wiki/online:-unit-pages">wut</a>}
      main_page.save!
      @copy_from.wiki_pages.create!(:title => "Online: Unit Pages", :body => %{<a href="/courses/#{@copy_from.id}/wiki/#{main_page.id}">whoa</a>})
      run_course_copy
      expect(@copy_to.wiki.front_page.body).to eq %{<a href="/courses/#{@copy_to.id}/#{@copy_to.wiki.path}/online-unit-pages">wut</a>}
      expect(@copy_to.wiki_pages.where(url: "online-unit-pages").first!.body).to eq %{<a href="/courses/#{@copy_to.id}/#{@copy_to.wiki.path}/#{main_page.url}">whoa</a>}
    end

    it "should keep assignment relationship" do
      vanilla_page_from = @copy_from.wiki_pages.create!(title: "Everyone Sees This Page")
      title = "conditional page"
      wiki_page_assignment_model(course: @copy_from, title: title)

      run_course_copy

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(@page)).take!
      asg_to = @copy_to.assignments.where(migration_id: mig_id(@assignment)).take!
      expect(asg_to.wiki_page).to eq page_to
      expect(asg_to.title).to eq page_to.title

      vanilla_page_to = @copy_to.wiki_pages.where(migration_id: mig_id(vanilla_page_from)).take!
      expect(vanilla_page_to.assignment).to be_nil

      # ensure assignment is unlinked
      @page.assignment = nil
      @page.save!
      run_course_copy
      expect(page_to.reload.assignment).to be_nil
    end

    it "re-imports updated/deleted page" do
      page = @copy_from.wiki_pages.create!(:title => "blah", :body => "<p>orig</p>")

      run_course_copy

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(page)).first
      page_to.destroy

      page.body = '<p>updated</p>'
      page.save!

      run_course_copy

      page_to.reload
      expect(page_to.workflow_state).to eq 'active'
      expect(page_to.body).to eq page.body
    end

    context "wiki front page" do
      it "should copy wiki front page setting if there is no front page" do
        fake_front_page = @copy_from.wiki_pages.create!(:title => "Front Page")
        real_front_page = @copy_from.wiki_pages.create!(:title => "actual front page")
        @copy_from.wiki.set_front_page_url!(real_front_page.url)

        run_course_copy

        new_front_page = @copy_to.wiki_pages.where(migration_id: mig_id(real_front_page)).first
        expect(@copy_to.wiki.front_page).to eq new_front_page
      end

      it "should not set 'Front Page' as the front page" do
        fake_front_page = @copy_from.wiki_pages.create!(:title => "Front Page")

        run_course_copy

        @copy_to.reload
        expect(@copy_to.wiki.front_page).to be_nil
      end

      it "should not overwrite current front page" do
        copy_from_front_page = @copy_from.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(copy_from_front_page.url)

        copy_to_front_page = @copy_to.wiki_pages.create!(:title => "stuff and stuff and even more stuf")
        @copy_to.wiki.set_front_page_url!(copy_to_front_page.url)

        run_course_copy

        expect(@copy_to.wiki.front_page).to eq copy_to_front_page
      end

      it "should overwrite current front page if default_view setting is also changed to wiki" do
        copy_from_front_page = @copy_from.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(copy_from_front_page.url)

        copy_to_front_page = @copy_to.wiki_pages.create!(:title => "stuff and stuff and even more stuf")
        @copy_to.wiki.set_front_page_url!(copy_to_front_page.url)

        @copy_from.update_attribute(:default_view, 'wiki')
        @copy_to.update_attribute(:default_view, 'feed')

        run_course_copy

        @copy_to.reload
        expect(@copy_to.default_view).to eq 'wiki'
        new_front_page = @copy_to.wiki_pages.where(:migration_id => mig_id(copy_from_front_page)).first
        expect(@copy_to.wiki.front_page).to eq new_front_page
      end

      it "should remain with no front page if other front page is not selected for copy" do
        front_page = @copy_from.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(front_page.url)

        other_page = @copy_from.wiki_pages.create!(:title => "stuff and other stuff")

        @copy_to.wiki.unset_front_page!

        # only select one of each type
        @cm.copy_options = {
            :wiki_pages => {mig_id(other_page) => "1", mig_id(front_page) => "0"}
        }
        @cm.save!

        run_course_copy

        expect(@copy_to.wiki.has_no_front_page).to eq true
      end

      it "should set default view to modules if wiki front page is missing" do
        @copy_from.wiki.set_front_page_url!('haha not here')
        @copy_from.default_view = 'wiki'
        @copy_from.save!

        run_course_copy

        expect(@copy_to.default_view).to eq 'modules'
        expect(@copy_to.wiki.has_front_page?).to eq false
      end
    end
  end
end
