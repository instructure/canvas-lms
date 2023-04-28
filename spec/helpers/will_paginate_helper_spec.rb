# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
#
require "will_paginate/collection"
require "folio/page"

describe WillPaginateHelper do
  describe "makes accessible pagination link titles" do
    before do
      klass = Class.new(WillPaginateHelper::AccessibleLinkRenderer) do
        def url(page)
          "url://#{page}"
        end
      end
      @renderer = klass.new
      @collection = Folio::Page.create
    end

    context "for numbered pages" do
      before do
        @collection.current_page = 2
        @renderer.prepare(@collection, {}, nil)
      end

      it "when page is current page" do
        link = @renderer.send(:page_number, 2)
        expect(link).to match('aria-label="Page 2"')
        expect(link).to match('class="current"')
        expect(link).to_not match("href")
        expect(link).to_not match("rel")
      end

      it "when page is not current page" do
        link = @renderer.send(:page_number, 3)
        expect(link).to match('aria-label="Page 3"')
        expect(link).to match('href="url://3')
      end
    end

    context "for logical pages" do
      before do
        @collection.previous_page = 2
        @collection.next_page = 4
        @renderer.prepare(@collection, {}, nil)
      end

      it "when linking to previous page" do
        link = @renderer.send(
          :previous_or_next_page,
          2,
          "Previous",
          "previous_page"
        )
        expect(link).to match('aria-label="Previous Page"')
        expect(link).to match('class="previous_page"')
        expect(link).to match('rel="prev"')
        expect(link).to match('href="url://2')
      end

      it "when linking to next page" do
        link = @renderer.send(
          :previous_or_next_page,
          4,
          "Next",
          "next_page"
        )
        expect(link).to match('aria-label="Next Page"')
        expect(link).to match('class="next_page"')
        expect(link).to match('rel="next"')
        expect(link).to match('href="url://4')
      end

      it "when linking to previous page without page number" do
        link = @renderer.send(
          :previous_or_next_page,
          nil,
          "Previous",
          "previous_page"
        )
        expect(link).to match('aria-label="Previous Page"')
        expect(link).to match('class="previous_page disabled"')
        expect(link).to_not match("rel")
        expect(link).to_not match("href")
      end

      it "when linking to next page without page number" do
        link = @renderer.send(
          :previous_or_next_page,
          nil,
          "Next",
          "next_page"
        )
        expect(link).to match('aria-label="Next Page"')
        expect(link).to match('class="next_page disabled"')
        expect(link).to_not match("rel")
        expect(link).to_not match("href")
      end
    end
  end
end
