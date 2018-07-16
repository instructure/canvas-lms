#
# Copyright (C) 2014 - present Instructure, Inc.
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

group :development, :test do
  gem 'dress_code', '1.2.0'
    gem 'colored', '1.2', require: false
    gem 'colorize', '0.8.1', require: false
    gem 'mustache', '1.0.5', require: false
    gem 'pygments.rb', '1.2.1', require: false
    gem 'redcarpet', '3.4.0', require: false
  gem 'bluecloth', '2.2.0' # for generating api docs
  gem 'yard', '0.9.5'
  gem 'yard-appendix', '0.1.8'

  gem 'bullet', '5.7.5', require: false, github: 'flyerhzm/bullet', ref: '0e852d87bc9c461d4a9b807c12af1c0d27c1d1b6'
end
