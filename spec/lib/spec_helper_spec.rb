# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "spec_helper" do
  context "encompass" do
    it "checks values" do
      root = { key1: :value1, key2: :value2 }
      expect(root).not_to encompass({ key1: "value1", key2: "value2" })
      expect(root).to encompass({ key1: :value1, key2: :value2 })
      expect([root]).not_to encompass([{ key1: "value1", key2: "value2" }])
      expect([root]).to encompass([{ key1: :value1, key2: :value2 }])
    end

    it "checks array length" do
      root = [{ key1: :value1, key2: :value2 },
              { key1: :value1, key2: :value2 },
              { key1: :value1, key2: :value2 }]
      expect(root).to encompass([{ key1: :value1, key2: :value2 },
                                 { key1: :value1, key2: :value2 },
                                 { key1: :value1, key2: :value2 }])
      expect(root).not_to encompass([{ key1: :value1, key2: :value2 },
                                     { key1: :value1, key2: :value2 }])
      expect(root).not_to encompass([{ key1: :value1, key2: :value2 },
                                     { key1: :value1, key2: :value2 },
                                     { key1: :value1, key2: :value2 },
                                     { key1: :value1, key2: :value2 }])
    end

    it "supports comparing dictionaries with different types of things" do
      thing_to_check = { :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }
      expect({ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }).to encompass(thing_to_check)
      expect({ :mkey1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 2, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 1, "mkey2" => 2.0, 3 => :val3, 4.0 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 1, "key2" => 2.1, 3 => :val3, 4.0 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 1, "key2" => 2.0, 2 => :val3, 4.0 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 1, "key2" => 2.0, 3 => :mval3, 4.0 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.1 => "val4" }).not_to encompass(thing_to_check)
      expect({ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "mval4" }).not_to encompass(thing_to_check)
      expect([{ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }]).to encompass([thing_to_check])
      expect([{ :mkey1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 2, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 1, "mkey2" => 2.0, 3 => :val3, 4.0 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 1, "key2" => 2.1, 3 => :val3, 4.0 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 1, "key2" => 2.0, 2 => :val3, 4.0 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 1, "key2" => 2.0, 3 => :mval3, 4.0 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.1 => "val4" }]).not_to encompass([thing_to_check])
      expect([{ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "mval4" }]).not_to encompass([thing_to_check])
    end

    it "supports dictionary encompassing" do
      root = { key1: :val1, key2: :val2, key3: :val3 }
      expect(root).to encompass({ key1: :val1, key2: :val2 })
      expect(root).to encompass({ key1: :val1, key3: :val3 })
      expect(root).to encompass({ key2: :val2, key3: :val3 })
      expect(root).to encompass({ key1: :val1 })
      expect(root).to encompass({ key2: :val2 })
      expect(root).to encompass({ key3: :val3 })
      expect(root).not_to encompass({ key1: :val1, key2: :val2, key4: :val4 })
      expect(root).not_to encompass({ key1: :val1, key3: :val3, key4: :val4 })
      expect(root).not_to encompass({ key2: :val2, key3: :val3, key4: :val4 })
      expect(root).not_to encompass({ key1: :val1, key4: :val4 })
      expect(root).not_to encompass({ key2: :val2, key4: :val4 })
      expect(root).not_to encompass({ key3: :val3, key4: :val4 })
      expect(root).not_to encompass({ key1: :val2, key2: :val2 })
      expect(root).not_to encompass({ key1: :val2, key3: :val3 })
      expect(root).not_to encompass({ key2: :val2, key3: :val1 })
      expect(root).not_to encompass({ key1: :val2 })
      expect(root).not_to encompass({ key2: :val3 })
      expect(root).not_to encompass({ key3: :val1 })
    end

    it "supports array encompassing" do
      root = [{ key1: :val1, key2: :val2 }, { key3: :val3, key4: :val4 }]
      expect(root).to encompass([{ key1: :val1 }, { key3: :val3, key4: :val4 }])
      expect(root).to encompass([{ key2: :val2 }, { key3: :val3 }])
      expect(root).to encompass([{ key1: :val1 }, { key4: :val4 }])
      expect(root).to encompass([{ key2: :val2 }, { key4: :val4 }])
      expect(root).to encompass([{ key2: :val2, key1: :val1 }, { key4: :val4 }])
      expect(root).not_to encompass([{ key2: :val1 }, { key4: :val4 }])
      expect(root).not_to encompass([{ key2: :val1 }, { key4: :val3 }])
      expect(root).not_to encompass([{ key2: :val2 }, { key4: :val3 }])
      expect(root).not_to encompass([{ key2: :val2 }, { key4: :val3 }, { key1: :val2 }])
      expect(root).not_to encompass([{ key4: :val4 }, { key2: :val2 }])
      expect(root).not_to encompass([{ key2: :val2 }])
      expect(root).not_to encompass([{ key2: :val2, key3: :val3 }, { key4: :val4 }])
    end
  end

  context "ReadOnlyTestStub" do
    it "switches to a read-only secondary" do
      GuardRail.activate(:secondary) do
        expect { User.create! }.to raise_error(ActiveRecord::StatementInvalid, /PG::InsufficientPrivilege/)
      end
    end

    it "nests primary inside secondary" do
      GuardRail.activate(:secondary) do
        expect { User.last }.not_to raise_error
        GuardRail.activate(:primary) do
          expect { User.create! }.not_to raise_error
        end
      end
    end

    it "works with after-transaction-commit hooks" do
      GuardRail.activate(:secondary) do
        User.transaction do
          User.connection.after_transaction_commit do
            User.last.touch
          end
          n = User.count
          GuardRail.activate(:primary) do
            expect { User.create! }.not_to raise_error
          end
          expect(GuardRail.environment).to eq :secondary
          expect(User.count).to eq n + 1
        end
      end
    end
  end
end
