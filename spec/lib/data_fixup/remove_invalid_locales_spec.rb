# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::RemoveInvalidLocales do
  it "removes invalid locale settings on accounts" do
    a1 = Account.create!(name: "invalid locale", default_locale: "az")
    a2 = Account.create!(name: "valid locale", default_locale: "de")

    expect([a1, a2].map(&:default_locale_before_type_cast)).to eq ["az", "de"]

    DataFixup::RemoveInvalidLocales.run

    [a1, a2].each(&:reload)
    expect([a1, a2].map(&:default_locale_before_type_cast)).to eq [nil, "de"]
  end

  it "removes invalid locale settings on courses" do
    c1 = Course.create!(name: "invalid locale", locale: "hy")
    c2 = Course.create!(name: "valid locale", locale: "fr")

    expect([c1, c2].map(&:locale_before_type_cast)).to eq ["hy", "fr"]

    DataFixup::RemoveInvalidLocales.run

    [c1, c2].each(&:reload)
    expect([c1, c2].map(&:locale_before_type_cast)).to eq [nil, "fr"]
  end

  it "removes invalid locale settings on users" do
    u1 = User.create!(name: "invalid locale", locale: "hy")
    u2 = User.create!(name: "valid locale", locale: "fr")

    # Avoid Validation
    u1.update_attribute("browser_locale", "de")
    u2.update_attribute("browser_locale", "kk")

    expect([u1, u2].map(&:browser_locale_before_type_cast)).to eq ["de", "kk"]
    expect([u1, u2].map(&:locale_before_type_cast)).to eq ["hy", "fr"]

    DataFixup::RemoveInvalidLocales.run

    [u1, u2].each(&:reload)
    expect([u1, u2].map(&:browser_locale_before_type_cast)).to eq ["de", nil]
    expect([u1, u2].map(&:locale_before_type_cast)).to eq [nil, "fr"]
  end
end
