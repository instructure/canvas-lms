# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe RuboCop::Cop::Datafixup::StrandDownstreamJobs do
  subject(:cop) { described_class.new }

  it "requires a strand on a delay" do
    inspect_source(<<~RUBY)
      module DataFixup::RecomputeRainbowAsteroidField
        def self.run
          User.delay.recompute_rainbow_asteroid_field
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/strand/)
    expect(cop.offenses.first.severity.name).to eq(:error)
  end

  it "requires a strand on a delay when there are other arguments" do
    inspect_source(<<~RUBY)
      module DataFixup::RecomputeRainbowAsteroidField
        def self.run
          User.delay(run_at: 5.minutes.from_now).recompute_rainbow_asteroid_field
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/strand/)
    expect(cop.offenses.first.severity.name).to eq(:error)
  end

  it "doesn't register an offsense when the job is stranded" do
    inspect_source(<<~RUBY)
      module DataFixup::RecomputeRainbowAsteroidField
        def self.run
          User.delay(strand: "space").recompute_rainbow_asteroid_field
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(0)
  end

  it "doesn't register an offsense when the job is n-stranded" do
    inspect_source(<<~RUBY)
      module DataFixup::RecomputeRainbowAsteroidField
        def self.run
          User.delay(n_strand: "space").recompute_rainbow_asteroid_field
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(0)
  end

  it "doesn't register an offsense when the job is a singleton" do
    inspect_source(<<~RUBY)
      module DataFixup::RecomputeRainbowAsteroidField
        def self.run
          User.delay(singleton: "space").recompute_rainbow_asteroid_field
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(0)
  end
end
