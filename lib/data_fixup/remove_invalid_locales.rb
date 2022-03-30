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

module DataFixup::RemoveInvalidLocales
  INVALID_LOCALES = %w[az el hi hr hu hy id ka kk ro th uk].freeze

  def self.run
    Account.where(default_locale: INVALID_LOCALES).in_batches.each_record do |account|
      account.update!(default_locale: nil)
    end

    Course.where(locale: INVALID_LOCALES).in_batches.each_record do |course|
      course.update!(locale: nil)
    end

    User.where(browser_locale: INVALID_LOCALES).in_batches.each_record do |user|
      user.update!(browser_locale: nil)
    end

    User.where(locale: INVALID_LOCALES).in_batches.each_record do |user|
      user.update!(locale: nil)
    end
  end
end
