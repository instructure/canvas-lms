# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../shared_constants"
require_relative "../shared_linter_examples"

describe TatlTael::Linters::Simple::SubstitutionVariablesLinter do
  let(:config) { TatlTael::Linters.config_for_linter(described_class) }

  context "when variable_expander.rb is modified" do
    it_behaves_like "comments",
                    [{ path: "lib/lti/variable_expander.rb", status: "modified" }]
  end

  context "when variable_expander.rb is added" do
    it_behaves_like "comments",
                    [{ path: "lib/lti/variable_expander.rb", status: "added" }]
  end

  context "when variable_expander.rb is deleted" do
    it_behaves_like "does not comment",
                    [{ path: "lib/lti/variable_expander.rb", status: "deleted" }]
  end

  context "when only extractSubstitutionVariables.ts is modified" do
    it_behaves_like "does not comment",
                    [{ path: "ui/features/lti_registrations/manage/lib/extractSubstitutionVariables.ts", status: "modified" }]
  end

  context "when both files are modified" do
    it_behaves_like "comments",
                    [{ path: "lib/lti/variable_expander.rb", status: "modified" },
                     { path: "ui/features/lti_registrations/manage/lib/extractSubstitutionVariables.ts", status: "modified" }]
  end
end
