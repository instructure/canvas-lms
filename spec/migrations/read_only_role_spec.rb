# frozen_string_literal: true

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

describe "read-only database role" do
  def with_read_only_role
    ActiveRecord::Base.connection.execute("SET ROLE canvas_readonly_user")
    yield
  ensure
    ActiveRecord::Base.connection.execute("RESET ROLE")
  end

  it "allows select" do
    user_factory(name: "blah")
    with_read_only_role do
      expect(User.where(id: @user).pluck(:name)).to eq(["blah"])
    end
  end

  it "allows switching from read-only to read-write" do
    user_factory(name: "blah")
    name = nil
    with_read_only_role do
      name = User.take.name
    end
    expect do
      @user.update name: name.succ
    end.not_to raise_error
  end

  it "disallows insert" do
    expect do
      with_read_only_role do
        user_factory
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /PG::InsufficientPrivilege/)
  end

  it "disallows update" do
    user_factory(name: "blah")
    expect do
      with_read_only_role do
        @user.update_attribute(:name, "bleh")
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /PG::InsufficientPrivilege/)
  end

  it "disallows delete" do
    user_factory(name: "blah")
    expect do
      with_read_only_role do
        @user.destroy_permanently!
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /PG::InsufficientPrivilege/)
  end
end
