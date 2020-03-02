#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper.rb')
require_dependency 'cdc_migration_testing/model_generator'

describe ModelGenerator do

  let(:generator) { ModelGenerator.new }

  before :each do
    allow(ActiveRecord::Base).to receive(:descendants).and_return(models)
  end

  # Make sure that it iterates through the model list until all foreign key
  # constraints are satisfied. Here, Account is passed in last, but needs
  # to be created first, since most models rely on an account.
  context 'with an out-of-order model list' do
    let(:models) { [ User, EnrollmentTerm, Course, AuthenticationProvider, Account] }

    it 'should populate the model_queue when initialized' do
      expect(generator.model_queue).to eq(models)
    end

    it 'should populate models when run' do
      models.each { |model| expect(model.any?).to be false }

      generator.run

      models.each { |model| expect(model.any?).to be true }
    end
  end

  context 'with fixture files' do

    let(:models) { [ User, Csp::Domain, Account ] }

    before :each do
      stub_const('ModelGenerator::FIXTURES_BASEDIR', 'spec/lib/cdc_migration_testing/fixtures')
    end

    it 'uses the fixture file for a model' do
      generator.run
      expect(User.last.name).to eq('CDC Sample User')
    end

    it 'finds fixture files for classes in modules' do
      generator.run
      expect(Csp::Domain.last.domain).to eq('example.com')
    end
  end

  context 'with an invalid fixture file' do
    let(:models) { [ User ] }
    before :each do
      stub_const('ModelGenerator::FIXTURES_BASEDIR', 'spec/lib/cdc_migration_testing/bad_fixtures')
    end

    it 'throws a useful error when the method name is incorrect' do
      expect {
        # User fixture file has a bad method name. Error should
        # tell you that the method name should be create_user.
        generator.run
      }.to raise_error(/create_user/)
    end
  end

  context 'with a model' do
    def run_and_ignore_exceptions
      # ActiveRecord will throw many errors because SampleModel isn't real.
      # We really just want to check what the attributes are when it attempts to
      # create an object -- we can ignore the exceptions when it fails to save.
      begin generator.run rescue StandardError end
    end

    class SampleModel < ActiveRecord::Base
      validates_presence_of :attr_required_in_rails

      self.table_name = :users # specifying an existing table gets around some AR exceptions
    end

    let(:models) { [ SampleModel ] }

    before :each do
      allow(SampleModel).to receive(:columns).and_return(columns)
    end

    context 'having multiple column types' do
      let(:columns) {[
        double("int column", name: 'id', type: :integer, null: false, default_function: false),
        double("optional int column", name: 'age', type: :integer, null: true, default_function: false),
        double("date column with default", name: 'join_date', type: :datetime, null: false, default_function: 'NOW()')
      ]}

      it 'ignores column that are nullable or have default values' do
        expect(SampleModel).not_to receive(:new).with hash_including('age')
        expect(SampleModel).not_to receive(:new).with hash_including('join_date')
        run_and_ignore_exceptions
      end

      it 'fills in an integer' do
        expect(SampleModel).to receive(:new).with('id' => 1)
        run_and_ignore_exceptions
      end

      context 'with models that share a table' do
        # SampleModel uses the users table.
        it 'only creates one model per table' do
          User.create!
          expect(SampleModel).not_to receive(:new)
        end
      end
    end

    context 'having string columns' do
      let(:columns) {[
        double("string column", name: 'name', type: :string, null: false, default_function: false),
        double("text column", name: 'description', type: :text, null: false, default_function: false),
        double("array column", name: 'array_col', type: :text, null: false, default_function: false),
        double("hash column", name: 'hash_col', type: :text, null: false, default_function: false),
        double("object column", name: 'obj_col', type: :string, null: false, default_function: false),
        double("short string", name: 'middle_initial', type: :string, null: false, default_function: false, limit: 1)
      ]}

      it 'fills in strings' do
        expect(SampleModel).to receive(:new).with hash_including({
          'name' => 'default',
          'description' => 'default'
        })
        run_and_ignore_exceptions
      end

      context 'with serialized attributes' do
        before :each do
          array_coder = double('array coder', object_class: Array)
          array_column = double('array column', type: :text, coder: array_coder)

          hash_coder = double('hash coder', object_class: Hash)
          hash_column = double('hash column', type: :text, coder: hash_coder)

          object_coder = double('object coder', object_class: Object)
          object_column = double('object column', type: :string, coder: object_coder)

          allow(SampleModel).to receive(:attribute_types).and_return({
            'array_col' => array_column,
            'hash_col' => hash_column,
            'obj_col' => object_column
          })
        end

        it 'fills in a hash' do
          expect(SampleModel).to receive(:new).with hash_including('hash_col' => instance_of(Hash))
          run_and_ignore_exceptions
        end

        it 'fills in an array' do
          expect(SampleModel).to receive(:new).with hash_including('array_col' => instance_of(Array))
          run_and_ignore_exceptions
        end

        it 'fills in an Object' do
          expect(SampleModel).to receive(:new).with hash_including('obj_col' => instance_of(Hash))
          run_and_ignore_exceptions
        end
      end
    end

    context 'having a boolean column' do
      let(:columns) {[
        double("boolean column", name: 'active', type: :boolean, null: false, default_function: false)
      ]}

      it 'fills in a boolean' do
        expect(SampleModel).to receive(:new).with hash_including('active' => false)
        run_and_ignore_exceptions
      end
    end

    context 'having a date column' do
      let(:columns) {[
        double("date column", name: 'birthdate', type: :datetime, null: false, default_function: false)
      ]}

      it 'fills in a date' do
        expect(SampleModel).to receive(:new).with hash_including('birthdate' => instance_of(ActiveSupport::TimeWithZone))
        run_and_ignore_exceptions
      end
    end

    context 'having json columns' do
      let(:columns) {[
        double("json column", name: 'json', type: :json, null: false, default_function: false),
        double("jsonb column", name: 'jsonb', type: :json, null: false, default_function: false)
      ]}

      it 'fills in a hash' do
        expect(SampleModel)
          .to receive(:new)
          .with hash_including('json' => {foo: 'bar'}, 'jsonb' => {foo: 'bar'})
        run_and_ignore_exceptions
      end
    end
  end

  context 'with a tableless model' do
    class TablelessModel < Tableless
    end

    let(:models) { [ TablelessModel ] }

    it 'does not throw an error' do
      expect {
        generator.run
      }.not_to raise_error
    end
  end
end
