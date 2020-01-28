# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'page_objects/wiki_page'
require_relative '../helpers/public_courses_context'

describe 'course wiki pages' do
  include_context 'in-process server selenium tests'
  include CourseWikiPage
  
  context "MathML" do
    include_context "public course as a logged out user"

    it "should load mathjax in a page with <math>" do
      title = "mathML"
      public_course.wiki_pages.create!(
        :title => title,
        :body => "<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup></math>"
      )
      visit_wiki_page_view(public_course.id, title)
      is_mathjax_loaded = driver.execute_script("return (typeof MathJax == 'object')")
      expect(is_mathjax_loaded).to match(true)
    end

    it "should not load mathjax without <math>" do
      title = "not_mathML"
      public_course.wiki_pages.create!(:title => title, :body => "not mathML")
      visit_wiki_page_view(public_course.id, title)
      is_mathjax_loaded = driver.execute_script("return (typeof MathJax == 'object')")
      expect(is_mathjax_loaded).not_to match(true)
    end
  end
end