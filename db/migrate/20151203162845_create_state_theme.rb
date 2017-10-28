#
# Copyright (C) 2015 - present Instructure, Inc.
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

class CreateStateTheme < ActiveRecord::Migration[4.2]
  tag :predeploy

  NAME = "State U. Theme"

  def up
    variables = {
      "ic-brand-primary"=>"#d12e2e",
      "ic-link-color"=>"#b52828",
      "ic-brand-global-nav-bgd"=>"#262626",
      "ic-brand-global-nav-ic-icon-svg-fill"=>"#d43c3c",
      "ic-brand-global-nav-menu-item__text-color--active"=>"#d12e2e",
      "ic-brand-global-nav-menu-item__badge-bgd"=>"#128812",
      "ic-brand-global-nav-logo-bgd"=>"#d12e2e",
      "ic-brand-watermark-opacity"=>"1",
      "ic-brand-Login-body-bgd-color"=>"#d12e2e",
      "ic-brand-Login-body-bgd-shadow-color"=>"#d12e2e",
      "ic-brand-Login-Content-bgd-color"=>"#262626",
      "ic-brand-Login-Content-border-color"=>"#262626",
      "ic-brand-Login-Content-password-text-color"=>"#dddddd",
      "ic-brand-Login-Content-button-bgd"=>"#d12e2e",
      "ic-brand-Login-footer-link-color"=>"#dddddd",
      "ic-brand-Login-footer-link-color-hover"=>"#cccccc",
      "ic-brand-Login-instructure-logo"=>"#cccccc"
    }
    bc = BrandConfig.new(variables: variables)
    bc.name = NAME
    bc.share = true
    bc.save!
  end

  def down
    BrandConfig.where(name: NAME).delete_all
  end
end
