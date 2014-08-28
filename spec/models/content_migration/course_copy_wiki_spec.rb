require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy wiki" do
    include_examples "course copy"

    it "should not escape links to wiki urls" do
      page1 = @copy_from.wiki.wiki_pages.create!(:title => "keepthese%20percent signs", :body => "blah")

      body = %{<p>Link to module item: <a href="/courses/%s/#{@copy_from.feature_enabled?(:draft_state) ? 'pages' : 'wiki'}/%s#header">some assignment</a></p>}
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body % [@copy_from.id, page1.url])

      run_course_copy

      page1_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page1))
      page2_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page2))
      page2_to.body.should == body % [@copy_to.id, page1_to.url]
    end

    it "should find and fix wiki links by title or id" do
      # simulating what happens when the user clicks "link to new page" and enters a title that isn't
      # urlified the same way by the client vs. the server.  this doesn't break navigation because
      # ApplicationController#get_wiki_page can match by urlified title, but it broke import (see #9945)
      main_page = @copy_from.wiki.front_page
      main_page.body = %{<a href="/courses/#{@copy_from.id}/wiki/online:-unit-pages">wut</a>}
      main_page.save!
      @copy_from.wiki.wiki_pages.create!(:title => "Online: Unit Pages", :body => %{<a href="/courses/#{@copy_from.id}/wiki/#{main_page.id}">whoa</a>})
      run_course_copy
      @copy_to.wiki.front_page.body.should == %{<a href="/courses/#{@copy_to.id}/wiki/online-unit-pages">wut</a>}
      @copy_to.wiki.wiki_pages.find_by_url!("online-unit-pages").body.should == %{<a href="/courses/#{@copy_to.id}/wiki/#{main_page.url}">whoa</a>}
    end

    context "wiki front page" do
      it "should copy wiki front page setting if there is no front page" do
        page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(page.url)

        @copy_to.wiki.unset_front_page!
        run_course_copy

        new_page = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
        @copy_to.wiki.front_page.should == new_page
      end

      it "should not overwrite current front page" do
        @copy_to.root_account.enable_feature!(:draft_state)

        copy_from_front_page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(copy_from_front_page.url)

        copy_to_front_page = @copy_to.wiki.wiki_pages.create!(:title => "stuff and stuff and even more stuf")
        @copy_to.wiki.set_front_page_url!(copy_to_front_page.url)

        run_course_copy

        @copy_to.wiki.front_page.should == copy_to_front_page
      end

      it "should remain with no front page if other front page is not selected for copy" do
        @copy_to.root_account.enable_feature!(:draft_state)

        front_page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and stuff")
        @copy_from.wiki.set_front_page_url!(front_page.url)

        other_page = @copy_from.wiki.wiki_pages.create!(:title => "stuff and other stuff")

        @copy_to.wiki.unset_front_page!

        # only select one of each type
        @cm.copy_options = {
            :wiki_pages => {mig_id(other_page) => "1", mig_id(front_page) => "0"}
        }
        @cm.save!

        run_course_copy

        @copy_to.wiki.has_no_front_page.should == true
      end

      it "should set retain default behavior if front page is missing and draft state is not enabled" do
        @copy_to.wiki.front_page.save!

        @copy_from.default_view = 'wiki'
        @copy_from.save!
        @copy_from.wiki.set_front_page_url!('haha not here')

        run_course_copy

        @copy_to.wiki.has_front_page?.should == true
        @copy_to.wiki.get_front_page_url.should == 'front-page'
      end

      it "should set default view to feed if wiki front page is missing and draft state is enabled" do
        @copy_from.root_account.enable_feature!(:draft_state)

        @copy_from.default_view = 'wiki'
        @copy_from.save!
        @copy_from.wiki.set_front_page_url!('haha not here')

        run_course_copy

        @copy_to.default_view.should == 'feed'
        @copy_to.wiki.has_front_page?.should == false
      end
    end
  end
end
