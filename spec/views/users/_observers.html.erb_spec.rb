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

require_relative "../../spec_helper"
require_relative "../views_helper"

describe "users/_observers" do
  def assign_common_variables
    assign(:user, student)
    assign(:current_user, current_user)
    assign(:domain_root_account, domain_root_account)
  end

  let_once(:other_account) { Account.create! }
  let_once(:other_observer) { user_factory(name: "Other Observer") }
  let_once(:student) { user_factory(name: "Test Student") }
  let_once(:current_user) { user_factory }
  let_once(:observer) { user_factory(name: "Test Observer", active_user: true) }
  let_once(:domain_root_account) { Account.default }
  let_once(:pseudonym) do
    observer.pseudonyms.create!(
      unique_id: "observer@example.com",
      account: domain_root_account
    )
  end

  context "without permissions" do
    before do
      assign_common_variables
      allow(view).to receive(:can_do).and_return(false)
    end

    it "renders nothing" do
      render partial: "users/observers"
      expect(response.body.strip).to be_empty
    end
  end

  context "with permissions" do
    before do
      assign_common_variables
      UserObservationLink.create_or_restore(
        student:,
        observer:,
        root_account: domain_root_account
      )
      allow(view).to receive(:can_do).with(anything, anything, :manage, :manage_user_details).and_return(true)
      allow(view).to receive(:can_do).with(student, current_user, :manage, :manage_user_details).and_return(true)
    end

    it "renders the observers table with content" do
      observer.email = "observer@example.com"
      render partial: "users/observers"
      expect(rendered).to match(/Observers/)
      expect(rendered).to match(/<table.*ic-Table/)
      expect(rendered).to match(%r{<th[^>]*>Name</th>})
      expect(rendered).to match(%r{<th[^>]*>Email</th>})
      expect(rendered).to match(%r{<th[^>]*>Last Request</th>})
      expect(rendered).to include(observer.name)
      expect(rendered).to include(observer.email)
      expect(rendered).to include("never")
    end

    it "handles observer with no email" do
      no_email_observer = user_factory(name: "No Email Observer", active_user: true)
      expect(no_email_observer.email).to be_nil
      UserObservationLink.create_or_restore(
        student:,
        observer: no_email_observer,
        root_account: domain_root_account
      )
      render partial: "users/observers"
      expect(rendered).to include(no_email_observer.name)
      expect(rendered).to match(%r{<td>\s*</td>})
    end

    it "shows 'never' for observers without logins" do
      render partial: "users/observers"
      expect(rendered).to include("never")
    end

    it "shows last request time for observers with logins" do
      time = 1.hour.ago
      pseudonym.update!(last_request_at: time)
      render partial: "users/observers"
      expect(rendered).to include(datetime_string(time))
    end

    it "shows all active observers" do
      observers = Array.new(3) do |i|
        observer = user_factory(name: "Observer #{i}", active_user: true)
        UserObservationLink.create_or_restore(
          student:,
          observer:,
          root_account: domain_root_account
        )
        observer
      end
      render partial: "users/observers"
      observers.each do |observer|
        expect(rendered).to include(observer.name)
      end
    end

    it "excludes deleted observer accounts" do
      deleted_observer = user_factory(name: "Deleted Observer")
      UserObservationLink.create_or_restore(
        student:,
        observer: deleted_observer,
        root_account: domain_root_account
      )
      deleted_observer.destroy
      render partial: "users/observers"
      expect(rendered).not_to include(deleted_observer.name)
    end

    it "excludes inactive observation links" do
      inactive_observer = user_factory(name: "Inactive Link Observer")
      link = UserObservationLink.create_or_restore(
        student:,
        observer: inactive_observer,
        root_account: domain_root_account
      )
      link.update!(workflow_state: "deleted")
      render partial: "users/observers"
      expect(rendered).not_to include(inactive_observer.name)
    end

    it "hides observer section when no active links exist" do
      UserObservationLink.where(student:).destroy_all
      render partial: "users/observers"
      expect(rendered.strip).to be_empty
    end

    it "only shows observers linked through current root account" do
      UserObservationLink.create_or_restore(
        student:,
        observer: other_observer,
        root_account: other_account
      )
      UserObservationLink.create_or_restore(
        student:,
        observer:,
        root_account: domain_root_account
      )
      allow(student).to receive(:grants_right?).and_return(true)
      allow(current_user).to receive(:grants_right?).and_return(true)
      allow(view).to receive(:can_do).and_return(true)
      render partial: "users/observers"
      expect(rendered).to include(observer.name)
      expect(rendered).not_to include(other_observer.name)
    end

    context "with different observer states" do
      %w[pre_registered pending_approval creation_pending deleted].each do |state|
        it "excludes #{state} observers" do
          state_observer = user_factory(
            name: "#{state.capitalize} Observer",
            user_state: state
          )
          UserObservationLink.create_or_restore(
            student:,
            observer: state_observer,
            root_account: domain_root_account
          )
          render partial: "users/observers"
          expect(rendered).not_to include(state_observer.name)
        end
      end
    end

    context "with multiple pseudonyms" do
      let_once(:old_time) { 2.days.ago }
      let_once(:recent_time) { 1.hour.ago }
      let_once(:old_pseudonym) do
        observer.pseudonyms.create!(
          unique_id: "old_observer@example.com",
          account: domain_root_account,
          last_request_at: old_time
        )
      end
      let_once(:recent_pseudonym) do
        observer.pseudonyms.create!(
          unique_id: "recent_observer@example.com",
          account: domain_root_account,
          last_request_at: recent_time
        )
      end

      it "shows most recent login time across all pseudonyms" do
        render partial: "users/observers"
        expect(rendered).to include(datetime_string(recent_time))
        expect(rendered).not_to include(datetime_string(old_time))
      end

      it "shows 'never' when all pseudonyms have nil last_request_at" do
        observer.pseudonyms.update_all(last_request_at: nil)
        render partial: "users/observers"
        expect(rendered).to include("never")
      end
    end
  end
end
