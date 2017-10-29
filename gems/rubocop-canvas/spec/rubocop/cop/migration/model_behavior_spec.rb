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

describe RuboCop::Cop::Migration::ModelBehavior do
  let(:config) {
    RuboCop::Config.new(
      "Migration/ModelBehavior" => {
        "Enabled" => true,
        "Included" => ["- db/migrate/*"],
        "Whitelist" => [
          "Account.default",
          "DataFixup",
          "Migrations::FooFix",
          "update_all",
          "delete_all",
          "connection.*"
        ]
      }
    )
  }

  subject(:cop) { described_class.new(config) }

  it "should find no offenses when calling whitelisted classes/methods" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        def up
          Migrations::FooFix.run
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling whitelisted Receiver/method combination" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        def up
          Account.default.lol.InstructureRules
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when a portion of the receiver is whitelisted" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        def up
          DataFixup::Module1::Module2::DeleteInvalidCommunicationChannels.send_now.blah
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling methods on whitelisted classes/methods" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        def up
          User.connection.execute "YOLO"
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling whitelisted methods" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        def up
          User.update_all(name: "sally")
          Course.where(id: [1,2,3]).delete_all
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling receiver-less methods" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        module Lol
        end

        include Lol
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when referencing classes defined in the file itself" do
    inspect_source(%{
      class User < ActiveRecord::Base; end
      Course = Class.new(ActiveRecord::Base)

      class Foo < ActiveRecord::Migration
        def up
          User.find_each { |u| u.save! }
          Course.find_each { |c| c.save! }
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should error if referencing unknown/auto-loaded classes" do
    inspect_source(%{
      class Foo < ActiveRecord::Migration
        def up
          User.find_each { |u| u.save! }
          Course.where(id: [1,2,3]).find_each { |c| c.save! }
        end
      end
    })
    expect(subject.offenses.size).to eq(2)
    expect(subject.offenses.all? { |off| off.severity.name == :convention })
  end
end
