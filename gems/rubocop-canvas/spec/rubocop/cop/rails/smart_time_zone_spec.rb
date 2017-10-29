#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'spec_helper'

describe RuboCop::Cop::Rails::SmartTimeZone do

  subject(:cop) { described_class.new() }


  described_class::TIMECLASS.each do |klass|
    it "registers an offense for #{klass}.now" do
      inspect_source("#{klass}.now")
      expect(cop.offenses.size).to eq(1)
    end

    it "registers an offense for #{klass}.new without argument" do
      inspect_source("#{klass}.new")
      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.first.message).to include('Time.zone.now')
    end

    it "registers an offense for #{klass}.new with argument" do
      inspect_source("#{klass}.new(2012, 6, 10, 12, 00)")
      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.first.message).to include('Time.zone.local')
    end
  end

  it 'registers an offense for Time.parse' do
    inspect_source('Time.parse("2012-03-02 16:05:37")')
    expect(cop.offenses.size).to eq(1)
  end

  it 'registers an offense for Time.strftime' do
    inspect_source('Time.strftime(time_string, "%Y-%m-%dT%H:%M:%S%z")')
    expect(cop.offenses.size).to eq(1)
  end

  it 'registers an offense for Time.strftime with nested Time.zone' do
    inspect_source(
      'Time.strftime(Time.zone.now.to_s, "%Y-%m-%dT%H:%M:%S%z")'
    )
    expect(cop.offenses.size).to eq(1)
  end

  it 'registers an offense for Time.zone.strftime with nested Time.now' do
    inspect_source(
      'Time.zone.strftime(Time.now.to_s, "%Y-%m-%dT%H:%M:%S%z")'
    )
    expect(cop.offenses.size).to eq(1)
  end

  it 'registers an offense for Time.at' do
    inspect_source('Time.at(ts)')
    expect(cop.offenses.size).to eq(1)
  end

  it 'accepts Time.now.utc' do
    inspect_source('Time.now.utc')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.zone.now' do
    inspect_source('Time.zone.now')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.zone.today' do
    inspect_source('Time.zone.today')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.zone.local' do
    inspect_source('Time.zone.local(2012, 6, 10, 12, 00)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.zone.parse' do
    inspect_source('Time.zone.parse("2012-03-02 16:05:37")')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.zone.at' do
    inspect_source('Time.zone.at(ts)')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.strptime' do
    inspect_source('Time.strptime(datetime, format).in_time_zone')
    expect(cop.offenses).to be_empty
  end

  it 'accepts Time.zone.strftime' do
    inspect_source(
      'Time.zone.strftime(time_string, "%Y-%m-%dT%H:%M:%S%z")'
    )
    expect(cop.offenses).to be_empty
  end


  described_class::TIMECLASS.each do |klass|
    it "accepts #{klass}.now.in_time_zone" do
      inspect_source("#{klass}.now.in_time_zone")
      expect(cop.offenses).to be_empty
    end
  end

  it 'accepts Time.strftime.in_time_zone' do
    inspect_source(
      'Time.strftime(time_string, "%Y-%m-%dT%H:%M:%S%z").in_time_zone'
    )
    expect(cop.offenses).to be_empty
  end
end
