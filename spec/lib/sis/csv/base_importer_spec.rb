#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::CSVBaseImporter do

  it 'should read file from index' do
    sis = double
    allow(sis).to receive(:batch).and_return nil
    allow(sis).to receive(:root_account).and_return nil
    # we also add row numbers on a 1 based index including header row.
    path = generate_csv_file(['h,h,h', # 1
                              '0,0,0', # 2
                              '1,1,1', # 3
                              '2,2,2', # 4
                              '3,3,3', # 5
                              '4,4,4', # 6
                              '5,5,5', # 7
                              '6,6,6', # 8
                              '7,7,7', # 9
                              '8,8,8', # 10
                              '9,9,9']) # 11
    csv = {}
    csv[:fullpath] = path
    rows, rows2, rows3 = [], [], []
    importer = SIS::CSV::CSVBaseImporter.new(sis)
    importer.csv_rows(csv, 0, 3) {|row| rows << row}
    importer.csv_rows(csv, 3, 6) {|row| rows2 << row}
    importer.csv_rows(csv, 9, 6) {|row| rows3 << row}
    expect(rows.first.fields).to eq ['0', '0', '0', 2]
    expect(rows.last.fields).to eq ['2', '2', '2', 4]
    expect(rows2.first.fields).to eq ['3', '3', '3', 5]
    expect(rows2.last.fields).to eq ['8', '8', '8', 10]
    expect(rows3.first.fields).to eq ['9', '9', '9', 11]
    expect(rows3.count).to eq 1
  end
end
