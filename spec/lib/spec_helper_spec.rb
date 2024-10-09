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

describe "spec_helper" do
  context "ReadOnlyTestStub" do
    it "switches to a read-only secondary" do
      GuardRail.activate(:secondary) do
        expect { User.create! }.to raise_error(ActiveRecord::StatementInvalid, /PG::InsufficientPrivilege/)
      end
    end

    it "nests primary inside secondary" do
      GuardRail.activate(:secondary) do
        expect { User.last }.not_to raise_error
        GuardRail.activate(:primary) do
          expect { User.create! }.not_to raise_error
        end
      end
    end

    it "works with after-transaction-commit hooks" do
      GuardRail.activate(:secondary) do
        User.transaction do
          User.connection.after_transaction_commit do
            User.last.touch
          end
          n = User.count
          GuardRail.activate(:primary) do
            expect { User.create! }.not_to raise_error
          end
          expect(GuardRail.environment).to eq :secondary
          expect(User.count).to eq n + 1
        end
      end
    end
  end
end
