#
# Copyright (C) 2018 - present Instructure, Inc.
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

module SpecMultipleLocales
  class << self
    def run(example)
      example.example_group.hooks.register(:prepend, :before, :each) do |example_in_group|
        locale = example_in_group.metadata[:locale]
        allow(I18n).to receive(:locale).and_return(locale)
      end

      all_locales = I18n.available_locales
      failures_so_far = 0

      all_locales.each do |locale|
        example.metadata[:locale] = locale
        example.run
        locale_message = 'Locale: ' + locale.to_s

        if example.exception
          if example.exception.respond_to?(:all_exceptions) # multiple exceptions present
            total_exceptions = example.exception.all_exceptions.length
            new_exceptions = total_exceptions - failures_so_far
            new_exceptions.times do |index|
              example.exception.all_exceptions[total_exceptions - index - 1].message << locale_message
            end
            failures_so_far = total_exceptions
          else
            example.exception.message << locale_message # only one exception present
            failures_so_far = 1
          end
        end
      end
    end
  end
end
