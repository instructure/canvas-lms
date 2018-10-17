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
  def csv_file(name)
    path = File.expand_path(File.dirname(__FILE__) + "/fixtures/#{name}.csv")
    File.open(path, 'rb')
  end

  def import_fake_csv(rows, separator: ',', &updates)
    no_errors = lambda do |status|
      expect(status[:errors]).to eq([])
    end

    updates ||= no_errors
    Tempfile.open do |tf|
      CSV.open(tf.path, 'wb', col_sep: separator) do |csv|
        rows.each { |r| csv << r }
      end
      tf.binmode
      Outcomes::CsvImporter.new(import, tf).run(&updates)
    end
  end

  def outcome_row_with_headers(outcome_headers, **changes)
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
    outcome_headers.map { |k| row[k.to_sym] }
  end

  def outcome_row(**changes)
    outcome_row_with_headers(headers, **changes)
  end

  def group_row_with_headers(group_headers, **changes)
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
    group_headers.map { |k| row[k.to_sym] }
  end

  def group_row(**changes)
    group_row_with_headers(headers, **changes)
  end

  before :once do
    account_model
  end

  let(:import) do
    OutcomeImport.create!(context: @account)
  end

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

  describe 'the csv importer' do
    let(:by_guid) do
      outcomes = LearningOutcome.all.to_a.index_by(&:vendor_guid)
      groups = LearningOutcomeGroup.all.to_a.index_by(&:vendor_guid)
      outcomes.merge(groups)
    end

    def expect_ok_import(path)
      Outcomes::CsvImporter.new(import, path).run do |status|
        expect(status[:errors]).to eq([])
      end
    end

    it 'can import the demo csv file' do
      expect_ok_import(csv_file('demo'))
      expect(LearningOutcomeGroup.count).to eq(3)
      expect(LearningOutcome.count).to eq(1)
    end

    it 'imports group attributes correctly' do
      expect_ok_import(csv_file('demo'))

      group = by_guid['b']
      expect(group.title).to eq('B')
      expect(group.description).to eq('BBB')
      expect(group.learning_outcome_group.vendor_guid).to eq('a')
    end

    it 'imports outcome attributes correctly' do
      expect_ok_import(csv_file('demo'))

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
      expect_ok_import(csv_file('scoring'))

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
      expect_ok_import(csv_file('no-ratings'))

      expect(by_guid['c'].data).not_to be_nil
      expect(by_guid['c'].rubric_criterion).not_to be_nil
    end

    it 'properly sets scoring types' do
      expect_ok_import(csv_file('scoring'))

      by_method = LearningOutcome.all.to_a.group_by(&:calculation_method)

      methods = LearningOutcome::CALCULATION_METHODS.keys.sort
      expect(by_method.keys.sort).to eq(methods)

      expect(by_method['decaying_average'].map(&:calculation_int)).to include(40)
      expect(by_method['n_mastery'][0].calculation_int).to eq(3)
    end

    it 'can import a utf-8 csv file with non-ascii characters' do
      guid = 'søren'
      expect_ok_import(csv_file('nor'))
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end

    it 'can import a utf-8 csv file exported from excel' do
      guid = 'søren'
      expect_ok_import(csv_file('nor-excel'))
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end

    it 'can import csv files with chinese characters' do
      guid = '作戰'
      expect_ok_import(csv_file('chn'))
      expect(LearningOutcomeGroup.where(vendor_guid: guid).count).to eq(1)
    end

    it 'reports import progress' do
      stub_const('Outcomes::CsvImporter::BATCH_SIZE', 2)

      increments = []
      import_fake_csv([headers] + (1..3).map { |ix| group_row(vendor_guid: ix) }.to_a) do |status|
        increments.push(status[:progress])
      end
      expect(increments).to eq([0, 50, 100, 100])
    end

    it 'properly sets mastery_points' do
      uuid = SecureRandom.uuid
      import_fake_csv([
        headers + ['mastery_points', 'ratings'],
        outcome_row(vendor_guid: uuid) + ['3.14', '5.34', 'awesome', '1.2', 'adequate', '0', 'nonexistant']
      ])

      outcome = LearningOutcome.find_by(vendor_guid: uuid)
      expect(outcome.rubric_criterion[:mastery_points]).to eq(3.14)
    end

    it 'can import a file with english decimal numbers' do
      uuid = SecureRandom.uuid
      import_fake_csv([
        headers + ['ratings'],
        outcome_row(vendor_guid: uuid) + [' 0012,34.5678 ', 'english number']
      ]) { }

      outcome = LearningOutcome.find_by(vendor_guid: uuid)
      expect(outcome.rubric_criterion[:ratings][0][:points]).to eq(1234.5678)
    end

    it 'can import a file with i18n decimal numbers' do
      I18n.locale = 'fr'
      uuid = SecureRandom.uuid
      import_fake_csv([
        headers + ['ratings'],
        outcome_row(vendor_guid: uuid) + [' 123 456,5678 ', 'bon nombre']
      ]) { }

      outcome = LearningOutcome.find_by(vendor_guid: uuid)
      expect(outcome.rubric_criterion[:ratings][0][:points]).to eq(123456.5678)
    end

    it 'automatically detects column separator from header' do
      rows = [headers] + (1..3).map { |ix| group_row(vendor_guid: ix) }.to_a
      import_fake_csv(rows, separator: ';')
      expect(LearningOutcomeGroup.count).to eq(4)
    end

    context 'with optional headers' do
      Outcomes::CsvImporter::OPTIONAL_FIELDS.each do |field|
        it "does not require #{field}" do
          no_field = headers - [field]
          rows = [no_field] + (1..3).map do |ix|
            group_row_with_headers(no_field, vendor_guid: ix)
          end
          rows = rows.to_a + [outcome_row_with_headers(no_field, vendor_guid: 'outcome')]
          import_fake_csv(rows)
          expect(LearningOutcomeGroup.count).to eq(4)
          expect(LearningOutcome.count).to eq(1)
        end
      end
    end
  end

  def expect_import_error(rows, expected)
    errors = []
    import_fake_csv(rows) do |status|
      errors += status[:errors]
    end
    expect(errors).to eq(expected)
  end

  def expect_import_failure(rows, message)
    expect { import_fake_csv(rows) }.to raise_error(Outcomes::Import::DataFormatError, message)
  end

  describe 'throws user-friendly header errors' do
    it 'when the csv file is totally malformed' do
      rows = [headers] + (1..3).map { |ix| group_row(vendor_guid: ix) }.to_a
      expect { import_fake_csv(rows, separator: ':(') }.to raise_error(Outcomes::Import::DataFormatError, 'Invalid CSV File')
    end

    it 'when the file is empty' do
      expect_import_failure([], 'File has no data')
    end

    it 'when required headers are missing' do
      expect_import_failure(
        [['parent_guids', 'ratings']],
        'Missing required fields: ["title", "vendor_guid", "object_type"]'
      )
    end

    it 'when other headers are after the ratings header' do
      expect_import_failure(
        [['parent_guids', 'ratings', 'vendor_guid', '', 'blagh', nil]],
        'Invalid fields after ratings: ["vendor_guid", "blagh"]'
      )
    end

    it 'when invalid headers are present' do
      expect_import_failure(
        [['vendor_guid', 'title', 'object_type', 'spanish_inquisition', 'parent_guids', 'ratings']],
        'Invalid fields: ["spanish_inquisition"]'
      )
    end

    it 'when no data rows are present' do
      expect_import_failure(
        [headers + ['ratings']],
        'File has no outcomes data'
      )
    end
  end

  describe 'throws user-friendly row errors' do

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
        [[2, 'Invalid value for rating tier 2 threshold: "bwaaaaaa bwa bwaaaaa"']]
      )
    end

    it 'if rating tiers have points in wrong order' do
      expect_import_error(
        [
          headers + ['ratings'],
          outcome_row + ['1', 'Sad Trombone', '2', 'Zesty Trombone']
        ],
        [[2, 'Points for tier 2 must be less than points for prior tier (2.0 is greater than 1.0)']]
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
        [[3, 'Parent references not found prior to this row: ["b", "c"]']]
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

    it 'raises a line error when vendor_guid is too long' do
      expect_import_error(
        [
          headers,
          outcome_row(vendor_guid: 'long-' * 200),
        ],
        [
          [2, "Vendor guid is too long (maximum is 255 characters)"],
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
