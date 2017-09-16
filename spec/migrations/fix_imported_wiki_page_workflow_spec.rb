#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20130617152008_fix_imported_wiki_page_workflow.rb'

describe 'DataFixup::FixImportedWikiPageWorkflow' do
  before :once do
    course_factory
    @wiki_pages = []
    5.times do |n|
      mod = @course.context_modules.create!(:name => "module")
      page = @course.wiki_pages.create!(:title => "wiki page #{n}", :body => "whatevaa")
      mod.add_item(:id => page.id, :type => 'wiki_page')
      @wiki_pages << page

      dummy_page = @course.wiki_pages.create!(:title => "ignore this wiki page #{n}", :body => "whatevaa")
      mod.add_item(:id => dummy_page.id, :type => 'wiki_page')
    end
    WikiPage.where(:id => @wiki_pages).update_all(:workflow_state => 'unpublished')
  end

  it "should find unpublished wiki pages" do
    expect(DataFixup::FixImportedWikiPageWorkflow.broken_wiki_page_scope.map(&:id).sort).to eq @wiki_pages.map(&:id).sort
  end

  it "should publish the broken wiki pages" do
    FixImportedWikiPageWorkflow.up
    @wiki_pages.each do |page|
      page.reload
      expect(page.workflow_state).to eq 'active'
    end
    expect(DataFixup::FixImportedWikiPageWorkflow.broken_wiki_page_scope.count).to eq 0
  end
end
