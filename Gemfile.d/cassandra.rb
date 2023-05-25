# frozen_string_literal: true

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
  gem "cassandra-cql",
      "1.2.3",
      github: "kreynolds/cassandra-cql",
      ref: "02b5abbe441a345c051a180327932566fd66bb36" # dependency of canvas_cassandra
    gem "thrift_client",
        "0.9.3",
        require: false,
        github: "twitter/thrift_client",
        ref: "5c10d59881825cb8e26ab1aa8f1d2738e88c0e83"
  gem "canvas_cassandra", path: "../gems/canvas_cassandra"
end
