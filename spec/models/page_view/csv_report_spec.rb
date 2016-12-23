#
# Copyright (C) 2016 Instructure, Inc.
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

require_relative '../../spec_helper.rb'

describe PageView::CsvReport do
  class PaginationStub < Array
    def next_page
      true
    end
  end

  before(:once) do
    @user = user_factory
  end

  describe "#records" do
    it "returns records" do
      pv1 = page_view_model
      pv2 = page_view_model

      report = PageView::CsvReport.new(@user)

      expect(report.records.map(&:id).sort).to eq [pv1.id, pv2.id].sort
    end

    it "accumulates until it has enough" do
      Setting.set('page_views_csv_export_rows', 2)
      pv1 = page_view_model

      report = PageView::CsvReport.new(@user)
      report.stubs(:page_views).returns(PaginationStub.new([pv1]))

      expect(report.records.map(&:id).sort).to eq [pv1.id, pv1.id].sort
    end

    it "returns the exact amount" do
      Setting.set('page_views_csv_export_rows', 3)
      pv1 = page_view_model
      pv2 = page_view_model

      report = PageView::CsvReport.new(@user)
      report.stubs(:page_views).returns(PaginationStub.new([pv1, pv2]))

      expect(report.records.map(&:id).sort).to eq [pv1.id, pv2.id, pv1.id].sort
    end
  end

  describe "#generate" do
    it "returns a csv" do
      pv1 = page_view_model
      pv2 = page_view_model

      csv = PageView::CsvReport.new(@user).generate
      rows = CSV.parse(csv, headers: true)
      expect(rows.length).to eq 2
      expect(rows.map{|x| x['request_id']}.sort).to eq [pv1.id, pv2.id].sort
    end
  end
end
