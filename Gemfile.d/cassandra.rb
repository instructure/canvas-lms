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

group :cassandra do
  gem 'cassandra-cql', '1.2.2', github: 'kreynolds/cassandra-cql', ref: 'fa9e4253ec35e1066f76418b1cd6ee03019ecb82' #dependency of canvas_cassandra
    gem 'simple_uuid', '0.4.0', require: false
    gem 'thrift', '0.8.0', require: false
    gem 'thrift_client', '0.8.4', require: false
  gem "canvas_cassandra", path: "gems/canvas_cassandra"
end

