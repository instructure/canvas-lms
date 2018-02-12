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

    def expect_ok_import(path)
      errors = Outcomes::CsvImporter.new(path, nil).run
      expect(errors).to eq([])
    end

    it 'can import the demo csv file' do
      expect_ok_import(csv_path('demo'))
      expect(LearningOutcomeGroup.count).to eq(3)
      expect(LearningOutcome.count).to eq(1)
    end

    it 'imports group attributes correctly' do
      expect_ok_import(csv_path('demo'))

      group = by_guid['b']
      expect(group.title).to eq('B')
      expect(group.description).to eq('BBB')
      expect(group.learning_outcome_group.vendor_guid).to eq('a')
    end

    it 'imports outcome attributes correctly' do
      expect_ok_import(csv_path('demo'))

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
      expect_ok_import(csv_path('scoring'))

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
      expect_ok_import(csv_path('no-ratings'))

      expect(by_guid['c'].rubric_criterion).to eq(nil)
    end

    it 'properly sets scoring types' do
      expect_ok_import(csv_path('scoring'))

      by_method = LearningOutcome.all.to_a.group_by(&:calculation_method)

      methods = LearningOutcome::CALCULATION_METHODS.keys.sort
      expect(by_method.keys.sort).to eq(methods)

      expect(by_method['decaying_average'][0].calculation_int).to eq(40)
      expect(by_method['n_mastery'][0].calculation_int).to eq(3)
    end

    it 'can import a utf-8 csv file with non-ascii characters' do
      guid = 'søren'
      expect_ok_import(csv_path('nor'))
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end

    it 'can import csv files with chinese characters' do
      guid = '作戰'
      expect_ok_import(csv_path('chn'))
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end
  end

  def import_fake_csv(rows)
    Tempfile.open do |tf|
      CSV.open(tf.path, 'wb') do |csv|
        rows.each { |r| csv << r }
      end
      Outcomes::CsvImporter.new(tf.path, nil).run
    end
  end

  def expect_import_error(rows, expected)
    errors = import_fake_csv(rows)
    expect(errors).to eq(expected)
  end

  describe 'throws user-friendly header errors' do
    it 'when required headers are missing' do
      expect_import_error(
        [['parent_guids', 'ratings']],
        [[1, 'Missing required fields: ["title", "vendor_guid", "object_type"]']]
      )
    end

    it 'when other headers are after the ratings header' do
      expect_import_error(
        [['parent_guids', 'ratings', 'vendor_guid', '', 'blagh', nil]],
        [[1, 'Invalid fields after ratings: ["vendor_guid", "blagh"]']]
      )
    end

    it 'when invalid headers are present' do
      expect_import_error(
        [['vendor_guid', 'title', 'object_type', 'spanish_inquisition', 'parent_guids', 'ratings']],
        [[1, 'Invalid fields: ["spanish_inquisition"]']]
      )
    end
  end

  describe 'throws user-friendly row errors' do
    let(:headers) do
      %w[
        title
        vendor_guid
        object_type
        parent_guids
        calculation_method
        calculation_int
        workflow_state
      ]
    end

    def outcome_row(**changes)
      valid = {
        title: 'title',
        vendor_guid: SecureRandom.uuid,
        object_type: 'outcome',
        parent_guids: '',
        calculation_method: 'highest',
        calculation_int: '',
        workflow_state: ''
      }

      row = valid.merge(changes)
      headers.map { |k| row[k.to_sym] }
    end

    def group_row(**changes)
      valid = {
        title: 'title',
        vendor_guid: SecureRandom.uuid,
        object_type: 'group',
        parent_guids: '',
        calculation_method: '',
        calculation_int: '',
        workflow_state: ''
      }

      row = valid.merge(changes)
      headers.map { |k| row[k.to_sym] }
    end

    it 'if rating tiers have points missing' do
      expect_import_error(
        [
          headers + ['ratings'],
          outcome_row + ['1', 'Sad Trombone', '', 'Zesty Trombone']
        ],
        [[2, 'Points for rating tier 2 not present']]
      )
    end

    it 'if rating tiers have invalid points values' do
      expect_import_error(
        [
          headers + ['ratings'],
          outcome_row + ['1', 'Sad Trombone', 'bwaaaaaa bwa bwaaaaa', 'Zesty Trombone']
        ],
        [[2, 'Invalid points for rating tier 2: "bwaaaaaa bwa bwaaaaa"']]
      )
    end

    it 'if rating tiers have points in wrong order' do
      expect_import_error(
        [
          headers + ['ratings'],
          outcome_row + ['1', 'Sad Trombone', '2', 'Zesty Trombone']
        ],
        [[2, 'Points for tier 2 must be less than points for prior tier (2 is greater than 1)']]
      )
    end

    it 'if object_type is incorrect' do
      expect_import_error(
        [
          headers,
          group_row(object_type: 'giraffe'),
        ],
        [[2, 'Invalid object_type: "giraffe"']]
      )
    end

    it 'if parent_guids refers to missing outcomes' do
      expect_import_error(
        [
          headers,
          group_row(vendor_guid: 'a'),
          outcome_row(vendor_guid: 'child', parent_guids: 'a b c'),
        ],
        [[3, 'Missing parent groups: ["b", "c"]']]
      )
    end

    it 'if required fields are missing' do
      expect_import_error(
        [
          headers,
          outcome_row(object_type: 'group', title: ''),
        ],
        [[2, 'The "title" field is required']]
      )

      expect_import_error(
        [
          headers,
          outcome_row(vendor_guid: ''),
        ],
        [[2, 'The "vendor_guid" field is required']]
      )
    end

    it 'if vendor_guid is invalid' do
      expect_import_error(
        [
          headers,
          outcome_row(vendor_guid: 'look some spaces'),
        ],
        [[2, 'The "vendor_guid" field must have no spaces']]
      )
    end

    it 'if workflow_state is invalid' do
      expect_import_error(
        [
          headers,
          outcome_row(workflow_state: 'limbo'),
          group_row(workflow_state: 'limbo'),
        ],
        [
          [2, '"workflow_state" must be either "active" or "deleted"'],
          [3, '"workflow_state" must be either "active" or "deleted"'],
        ]
      )
    end

    it 'if a value has an invalid utf-8 byte sequence' do
      expect_import_error(
        [
          headers,
          outcome_row(title: "evil \xFF utf-8".force_encoding("ASCII-8BIT")),
        ],
        [
          [2, "Not a valid utf-8 string: \"evil \\xFF utf-8\""]
        ]
      )
    end

    it 'if a validation fails' do
      methods = '["decaying_average", "n_mastery", "highest", "latest"]'
      expect_import_error(
        [
          headers,
          outcome_row(calculation_method: 'goofy'),
        ],
        [
          [2, "Calculation method calculation_method must be one of the following: #{methods}"],
        ]
      )
    end

    it 'if a group receives invalid fields' do
      expect_import_error(
        [
          headers + ['ratings'],
          group_row(
            vendor_guid: 'a',
            calculation_method: 'n_mastery',
            calculation_int: '5',
          ) + ['1', 'Sad Trombone'],
        ],
        [[2, 'Invalid fields for a group: ["calculation_method", "calculation_int", "ratings"]']]
      )
    end
  end
end
