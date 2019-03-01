#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Loaders::AssociationLoader do
  before(:once) do
    @c1 = Course.create! name: "asdf"
    @c2 = Course.create! name: "qwer"
    @c3 = Course.create! name: "zxcv"

    @a1 = @c1.assignments.create! name: "asdf"
    @a2 = @c2.assignments.create! name: "qwer"
    @a3 = @c3.assignments.create! name: "zxcv"
  end

  around(:each) do |example|
    @query_count = 0
    subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |_, _, _, _, data|
      @query_count += 1
    end

    example.run

    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  it "batch loads" do
    a1 = Assignment.find(@a1.id)
    a2 = Assignment.find(@a2.id)

    puts @query_count

    expect {
      GraphQL::Batch.batch do
        Loaders::AssociationLoader.for(Assignment, :context).load(a1).then { |course|
          expect(course).to eq @c1
        }
        Loaders::AssociationLoader.for(Assignment, :context).load(a2).then { |course|
          expect(course).to eq @c2
        }
      end
    }.to change{@query_count}.by(1)
  end

  it "batch loads when the association is already loaded on first object" do
    a1 = Assignment.find(@a1.id)
    a2 = Assignment.find(@a2.id)
    a3 = Assignment.find(@a3.id)

    # pre-load the course on the first record.
    # normally this would cause an N+1 for subsequent records
    # (ActiveRecord::Preloader.new only checks the first record when
    # determining whether or not to run)
    a1.course

    expect {
      GraphQL::Batch.batch do
        Loaders::AssociationLoader.for(Assignment, :context).load_many([a1, a2, a3])
      end
    }.to change{@query_count}.by(1)
  end
end
