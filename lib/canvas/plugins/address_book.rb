#
# Copyright (C) 2016 - present Instructure, Inc.
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

Canvas::Plugin.register('address_book', nil, {
  :name => lambda{ t :name, 'Address Book' },
  :description => lambda{ t :description, 'Configure how to answer address book queries.' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '0.1.0',
  :settings_partial => 'plugins/address_book_settings',
  :validator => 'AddressBookValidator',
  # default settings
  :settings => { strategy: AddressBook::DEFAULT_STRATEGY }
})
