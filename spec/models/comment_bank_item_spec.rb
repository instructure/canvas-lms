# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe CommentBankItem do
  let(:course) { course_model }
  let(:user) { user_model }
  let(:comment) { "comment" }
  let(:creation_params) { { course:, comment:, user: } }

  describe "validations" do
    subject { CommentBankItem.create!(creation_params) }

    it { is_expected.to validate_presence_of :course }
    it { is_expected.to validate_presence_of :comment }
    it { is_expected.to validate_presence_of :user }
    it { is_expected.to validate_length_of(:comment).is_at_most(ActiveRecord::Base.maximum_text_length) }
    it { is_expected.to validate_length_of(:comment).is_at_least(1) }
  end

  it_behaves_like "soft deletion" do
    subject { CommentBankItem }

    let(:creation_arguments) { [creation_params] }
  end

  describe "root_account_id" do
    subject { CommentBankItem.create!(comment: "A", course: @course, user:) }

    before do
      root_account = account_model
      @course = course_model(account: root_account)
    end

    it "sets root account from course" do
      expect(subject.root_account_id).to eq(@course.root_account_id)
    end
  end

  describe "permissions" do
    subject { CommentBankItem.create!(comment: "A", course:, user:) }

    describe "read/update/delete" do
      it "is allowed for the creator" do
        aggregate_failures do
          %i[read update delete].each do |permission|
            expect(subject.grants_right?(user, permission)).to be(true)
          end
        end
      end

      it "is not allowed for other users" do
        user2 = user_model
        %i[read update delete].each do |permission|
          expect(subject.grants_right?(user2, permission)).to be(false)
        end
      end
    end

    describe "create" do
      let(:user) { account_admin_user }

      it "requires manage_grades permissions" do
        expect(subject.grants_right?(user, :create)).to be(true)
        user = account_admin_user_with_role_changes(user:, role_changes: { manage_grades: false })
        expect(subject.grants_right?(user, :create)).to be(false)
      end
    end
  end
end
