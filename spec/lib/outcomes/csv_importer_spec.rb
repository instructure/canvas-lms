# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Outcomes::CsvImporter do
  def csv_path(name)
    File.expand_path(File.dirname(__FILE__) + "/fixtures/#{name}.csv")
  end

  describe 'the csv importer' do
    let(:by_guid) do
      outcomes = LearningOutcome.all.to_a.index_by(&:vendor_guid)
      groups = LearningOutcomeGroup.all.to_a.index_by(&:vendor_guid)
      outcomes.merge(groups)
    end

    it 'can import the demo csv file' do
      Outcomes::CsvImporter.new(csv_path('demo'), nil).run
      expect(LearningOutcomeGroup.count).to eq(3)
      expect(LearningOutcome.count).to eq(1)
    end

    it 'imports group attributes correctly' do
      Outcomes::CsvImporter.new(csv_path('demo'), nil).run

      group = by_guid['b']
      expect(group.title).to eq('B')
      expect(group.description).to eq('BBB')
      expect(group.learning_outcome_group.vendor_guid).to eq('a')
    end

    it 'imports outcome attributes correctly' do
      Outcomes::CsvImporter.new(csv_path('demo'), nil).run

      outcome = by_guid['c']
      expect(outcome.title).to eq('C')
      expect(outcome.description).to eq('CCC')
      expect(outcome.display_name).to eq('here')
      expect(outcome.calculation_method).to eq('decaying_average')
      expect(outcome.calculation_int).to eq(40)

      parents = [by_guid['a'], by_guid['b']]
      parents.each do |parent|
        expect(parent.child_outcome_links.map(&:content).map(&:vendor_guid)).to eq(['c'])
      end
    end

    it 'imports ratings correctly' do
      Outcomes::CsvImporter.new(csv_path('scoring'), nil).run

      criteria = by_guid['c'].rubric_criterion
      ratings = criteria[:ratings].sort_by { |r| r[:points] }
      expect(ratings.map { |r| r[:points] }).to eq([1, 2, 3])
      expect(ratings.map { |r| r[:description] }).to eq(['Good', 'Better', 'Betterest'])

      expect(by_guid['d'].rubric_criterion[:ratings].length).to eq(2)
      expect(by_guid['e'].rubric_criterion[:ratings].length).to eq(2)
      expect(by_guid['f'].rubric_criterion[:ratings].length).to eq(2)
      expect(by_guid['g'].rubric_criterion[:ratings].length).to eq(1)
    end

    it 'works when no ratings are present' do
      Outcomes::CsvImporter.new(csv_path('no-ratings'), nil).run

      expect(by_guid['c'].rubric_criterion).to eq(nil)
    end

    it 'properly sets scoring types' do
      Outcomes::CsvImporter.new(csv_path('scoring'), nil).run

      by_method = LearningOutcome.all.to_a.group_by(&:calculation_method)

      methods = LearningOutcome::CALCULATION_METHODS.keys.sort
      expect(by_method.keys.sort).to eq(methods)

      expect(by_method['decaying_average'][0].calculation_int).to eq(40)
      expect(by_method['n_mastery'][0].calculation_int).to eq(3)
    end

    it 'can import a utf-8 csv file with non-ascii characters' do
      guid = 'søren'
      Outcomes::CsvImporter.new(csv_path('nor'), nil).run
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end

    it 'can import csv files with chinese characters' do
      guid = '作戰'
      Outcomes::CsvImporter.new(csv_path('chn'), nil).run
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end
  end

  # OUT-1885 : need lots of specs for testing error messages on invalid row content
end
