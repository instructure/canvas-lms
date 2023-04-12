# frozen_string_literal: true

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

describe OutcomeImportError do
  describe "associations" do
    it { is_expected.to belong_to(:outcome_import) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :message }
    it { is_expected.to validate_presence_of :outcome_import_id }
  end

  describe "truncation" do
    before :once do
      account_model
    end

    let :import do
      OutcomeImport.create_with_attachment(@account, "instructure_csv", stub_file_data("test.csv", "abc", "text"), user_factory)
    end

    it "does not truncate short errors" do
      short = "short"
      subject.update!(outcome_import: import, message: short)
      expect(subject.message).to eq(short)
    end

    it "handles long error messages via truncation" do
      # the utf-8 encoding of 川 is E5 B7 9D, to test multi-byte sequences
      long = "long 川" * 1000
      subject.update!(outcome_import: import, message: long)
      expect(subject.message.length).to be < long.length
    end
  end
end
