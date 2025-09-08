# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Auditors::AccountUser do
  let(:account_user) { AccountUser.create!(account: Account.default, user: user_model) }
  let(:performing_user) { user_model }
  let(:action) { "delete" }

  describe ".record" do
    subject { described_class.record(account_user, performing_user, action:) }

    context "without an account_user" do
      let(:account_user) { nil }

      it "requires an account_user" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "without an action" do
      let(:action) { nil }

      it "requires an action" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe Auditors::AccountUser::Record do
    subject { described_class.generate(account_user, performing_user, action:) }

    describe ".generate" do
      context "with a user" do
        it "uses the id of the user who performed the action" do
          subject
          expect(subject.performing_user_id).to eq(performing_user.id)
        end
      end

      context "without a user" do
        let(:performing_user) { nil }

        it "uses nil as the performing user's id" do
          subject
          expect(subject.performing_user_id).to be_nil
        end
      end
    end
  end
end
