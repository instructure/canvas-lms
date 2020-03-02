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

class ModelGenerator

  FIXTURES_BASEDIR = 'lib/cdc_migration_testing/fixtures'.freeze
  attr_accessor :model_queue

  def initialize
    @model_queue = ActiveRecord::Base.descendants
  end

  def run
    loop do
      last_queue_length = self.model_queue.length
      create_models
      break if self.model_queue.empty?
      # If no models were created in that run (so the queue length didn't change),
      # something is preventing it from advancing.
      raise "Couldn't generate all necessary models." if last_queue_length == self.model_queue.length
    end
    Rails.logger.info "Finished generating models"
  end

  private

  def create_models
    self.model_queue.each do
      model = self.model_queue.shift()
      next if !model.table_exists? || records?(model.table_name_prefix + model.table_name)
      begin
        create_model(model)
      # If there's a foreign key error, put this model back at the end of the
      # queue and try again later so that the prerequisite models can
      # be created first. This takes several cycles, but finishes eventually.
      rescue ActiveRecord::InvalidForeignKey
        self.model_queue.push(model)
      rescue StandardError => e
      raise <<~ERROR
        Couldn't create a #{model.name}. If one can't be generated, you
        will need to define a CdcFixtures.create_#{model.class_name.underscore} method in
        #{fixture_file_path(model)} that returns a #{model.name}.\n Error message:\n #{e.message}
        ERROR
      end
    end
  end

  def create_model(model)
    remove_callbacks(model)
    begin
      create_from_fixture_file(model)
    # TypeError is thrown if the file doesn't exist.
    rescue TypeError
      Rails.logger.info "No sample #{model.name} found in #{fixture_file_path(model)}, will try to auto-generate one."
      generate_model(model)
    end
  end

  def remove_callbacks(model)
    callbacks = model.__callbacks

    [:create, :update, :save, :commit].each do |callback_type|
      callbacks[callback_type].each do |callback|
        model.skip_callback(callback.name, callback.kind, callback.filter)
      end
    end
  end

  def create_from_fixture_file(model)
    model_file_path = fixture_file_path(model)

    begin
      require Rails.root.join(model_file_path)
      created_model = CdcFixtures.send("create_#{model.class_name.underscore}".to_sym)
      created_model.save!(validate: false)
    rescue ActiveRecord::RecordInvalid => e
      raise <<~NOSAVE
      Couldn't save the #{model.name} returned by the self.create method in
      #{model_file_path}. Make sure that the self.create method returns a
      valid #{model.name}.\n
      Exception:\n
      #{e.message}
      NOSAVE
    rescue NoMethodError => e
      raise <<~ERR
      There was an unknown error when loading #{model_file_path} and calling
      CdcFixtures.create_#{model.class_name.underscore}.\n
      Exception:\n
      #{e.message}
      ERR
    end
  end

  def generate_model(model)
    required_attributes = get_postgres_non_nullable_attributes(model)
    required_attributes.merge! get_partman_attributes(model)

    begin
      model.new(required_attributes).save!(validate: false)
    rescue ActiveRecord::ReadOnlyRecord
      # If we just tried to create a read-only record, ignore it.
    end
  end

  # Partman is a gem in gems/canvas_partman that tries to do some automatic
  # relationships based on column names like "thing_id" and "thing_type".
  # It is not avoided by skipping validations or callbacks, so we have to fill
  # in those _id columns.
  def get_partman_attributes(model)
    partman_columns = find_partman_columns(model)
    attributes = {}
    partman_columns.each do |column|
      attributes[column.name] = 1
    end

    attributes
  end

  def find_partman_columns(model)
    model.columns.select do |column|
      is_partman_column = false

      # Look for a column name that ends with _id, then look for a matching
      # column that ends with _type.
      if column.name.end_with?("_id")
        model_name = column.name[0..-4]
        is_partman_column = !!model.columns.index { |col| col.name == model_name + '_type' }
      end

      is_partman_column
    end
  end

  def get_postgres_non_nullable_attributes(model)
    required_columns = model.columns.select do |column|
      # column.default_function means that postgres will auto-fill something
      # on INSERT (e.g., an auto-incremented ID). So we don't have to fill in
      # those columns, unless it's the 'id' field. Then we want to hard-code
      # that to 1, since other models always use 1 for foreign key fields.
      !column.null && (!column.default_function || column.name == 'id')
    end

    attributes = {}
    required_columns.each do |column|
      case column.type
      when :integer
        attributes[column.name] = 1
      when :decimal, :float
        attributes[column.name] = 0.9
      when :string, :text
        attributes[column.name] = string_or_serializable_object(model, column)
      when :boolean
        attributes[column.name] = false
      when :datetime
        attributes[column.name] = Time.zone.now
      when :json, :jsonb
        attributes[column.name] = {foo: 'bar'}
      else
        raise "Model #{model.name} has no fixture and no default value for column '#{column.name}' of type '#{column.type}'"
      end
    end

    attributes
  end

  def string_or_serializable_object(model, column)
    # A "coder" is defined if the column is a string or text type, but is going
    # to be encoded/decoded into a Hash, Array, etc. by ActiveRecord.
    if defined? model.attribute_types[column.name].coder
      case model.attribute_types[column.name].coder.object_class.name
      when 'Hash', 'Object'
        {foo: 'bar'}
      when 'Array'
        ['foo']
      end
    else
      'default'
    end
  end

  def fixture_file_path(model)
    FIXTURES_BASEDIR + '/' + model.name.underscore + '.rb'
  end


  def records?(table_name)
    ActiveRecord::Base.connection.exec_query("SELECT * FROM #{Shard.current.name}.#{table_name}").any?
  end

end
