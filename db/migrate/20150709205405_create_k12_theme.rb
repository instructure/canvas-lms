# frozen_string_literal: true

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

class CreateK12Theme < ActiveRecord::Migration[4.2]
  tag :predeploy

  NAME = "K12 Theme"
  MD5_OF_K12_CONFIG = 'a1f113321fa024e7a14cb0948597a2a4'

  def up
    variables = {
      "ic-brand-primary"=>"#E66135",
      "ic-brand-button--primary-bgd"=>"#4A90E2",
      "ic-link-color"=>"#4A90E2",
      "ic-brand-global-nav-bgd"=>"#4A90E2",
      "ic-brand-global-nav-logo-bgd"=>"#3B73B4"
    }
    bc = BrandConfig.new(variables: variables)
    bc.name = NAME
    bc.share = true
    bc.md5 = MD5_OF_K12_CONFIG
    # set the md5 directly in the record for backwards compatability
    BrandConfig.suspend_callbacks(:generate_md5) do
      bc.save!
    end
    SharedBrandConfig.create!(name: bc.name, brand_config_md5: bc.md5)
  end

  def down
    SharedBrandConfig.where(name: NAME).delete_all
    BrandConfig.where(name: NAME).delete_all
  end
end
