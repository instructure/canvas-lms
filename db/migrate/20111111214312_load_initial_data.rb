# frozen_string_literal: true

#
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

class LoadInitialData < ActiveRecord::Migration[7.0]
  tag :predeploy

  def up
    create_dummy_data
    create_default_shard
    # all we want in the test env is the dummy root account and the default shard
    # everything else will get truncated anyway
    return if Rails.env.test?

    create_k12_theme
    create_minimalist_theme
    create_state_theme
    add_priority_to_notifications
  end

  def create_dummy_data
    # self-referential; so defer constraint checking until the end of the transaction
    defer_constraints("fk_rails_5de7ad5dec") do
      Account.create_with(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: 0)
             .find_or_create_by!(id: 0)
    end
    return if Rails.env.test? # all we want in the test env is the dummy root account

    EnrollmentTerm.ensure_dummy_enrollment_term
    Course.ensure_dummy_course
  end

  def create_default_shard
    unless Switchman::Shard.default.is_a?(Switchman::Shard)
      Switchman::Shard.reset_column_information
      Switchman::Shard.create!(default: true)
      Switchman::Shard.default(reload: true)
    end
  end

  def create_k12_theme
    create_theme("K12 Theme", {
                   "ic-brand-primary" => "#E66135",
                   "ic-brand-button--primary-bgd" => "#4A90E2",
                   "ic-link-color" => "#4A90E2",
                   "ic-brand-global-nav-bgd" => "#4A90E2",
                   "ic-brand-global-nav-logo-bgd" => "#3B73B4"
                 })
  end

  def create_minimalist_theme
    create_theme("Minimalist Theme", {
                   "ic-brand-primary" => "#2773e2",
                   "ic-brand-button--secondary-bgd" => "#4d4d4d",
                   "ic-link-color" => "#1d6adb",
                   "ic-brand-global-nav-bgd" => "#f2f2f2",
                   "ic-brand-global-nav-ic-icon-svg-fill" => "#444444",
                   "ic-brand-global-nav-menu-item__text-color" => "#444444",
                   "ic-brand-global-nav-avatar-border" => "#444444",
                   "ic-brand-global-nav-logo-bgd" => "#4d4d4d",
                   "ic-brand-watermark-opacity" => "1",
                   "ic-brand-Login-body-bgd-color" => "#f2f2f2",
                   "ic-brand-Login-body-bgd-shadow-color" => "#f2f2f2",
                   "ic-brand-Login-Content-bgd-color" => "#ffffff",
                   "ic-brand-Login-Content-border-color" => "#efefef",
                   "ic-brand-Login-Content-label-text-color" => "#444444",
                   "ic-brand-Login-Content-password-text-color" => "#444444",
                   "ic-brand-Login-Content-button-bgd" => "#2773e2",
                   "ic-brand-Login-footer-link-color" => "#2773e2",
                   "ic-brand-Login-instructure-logo" => "#aaaaaa"
                 })
  end

  def create_state_theme
    create_theme("State U. Theme", {
                   "ic-brand-primary" => "#d12e2e",
                   "ic-link-color" => "#b52828",
                   "ic-brand-global-nav-bgd" => "#262626",
                   "ic-brand-global-nav-ic-icon-svg-fill" => "#d43c3c",
                   "ic-brand-global-nav-menu-item__text-color--active" => "#d12e2e",
                   "ic-brand-global-nav-menu-item__badge-bgd" => "#128812",
                   "ic-brand-global-nav-logo-bgd" => "#d12e2e",
                   "ic-brand-watermark-opacity" => "1",
                   "ic-brand-Login-body-bgd-color" => "#d12e2e",
                   "ic-brand-Login-body-bgd-shadow-color" => "#d12e2e",
                   "ic-brand-Login-Content-bgd-color" => "#262626",
                   "ic-brand-Login-Content-border-color" => "#262626",
                   "ic-brand-Login-Content-password-text-color" => "#dddddd",
                   "ic-brand-Login-Content-button-bgd" => "#d12e2e",
                   "ic-brand-Login-footer-link-color" => "#dddddd",
                   "ic-brand-Login-footer-link-color-hover" => "#cccccc",
                   "ic-brand-Login-instructure-logo" => "#cccccc"
                 })
  end

  def create_theme(name, variables)
    bc = BrandConfig.create!(name:, variables:, share: true)
    SharedBrandConfig.create!(name: bc.name, brand_config_md5: bc.md5)
  end

  def add_priority_to_notifications
    return unless Shard.current.default?

    priority_message_list = ["Account User Registration",
                             "Confirm Email Communication Channel",
                             "Confirm Registration",
                             "Confirm SMS Communication Channel",
                             "Enrollment Invitation",
                             "Enrollment Notification",
                             "Forgot Password",
                             "Manually Created Access Token Created",
                             "Merge Email Communication Channel",
                             "Pseudonym Registration",
                             "Pseudonym Registration Done",
                             "Self Enrollment Registration"].freeze

    Notification.where(name: priority_message_list).update_all(priority: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
