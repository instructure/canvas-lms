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
  attr_reader :generated_count, :fixture_count, :skipped_count, :iteration_count

  def initialize
    Rails.application.eager_load!
    @model_queue = ActiveRecord::Base.descendants
    @generated_count = @fixture_count = @skipped_count = @iteration_count = 0
  end

  def queue_length
    @model_queue.length
  end

  def run
    loop do
      last_queue_length = @model_queue.length
      create_models
      @iteration_count+=1
      break if @model_queue.empty?
      # If no models were created in that run (so the queue length didn't change),
      # something is preventing it from advancing.
      raise "Couldn't generate all necessary models." if last_queue_length == @model_queue.length
    end
  end

  private

  def create_models
    @model_queue.each do
      model = @model_queue.shift()
      if !model.table_exists? || records?(model.table_name_prefix + model.table_name)
        @skipped_count+=1
        next
      end

      begin
        create_model(model)
      # If there's a foreign key error, put this model back at the end of the
      # queue and try again later so that the prerequisite models can
      # be created first. This takes several cycles, but finishes eventually.
      rescue ActiveRecord::InvalidForeignKey
        @model_queue.push(model)
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
      @fixture_count+=1
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
    required_attributes.merge! set_inheritance_column(model)

    begin
      model.new(required_attributes).save!(validate: false)
      @generated_count+=1
    rescue ActiveRecord::ReadOnlyRecord
      @skipped_count +=1
      # If we just tried to create a read-only record, ignore it.
      # AssignmentStudentVisibility, (and possibly other models?) don't
      # allow creating records directly for some reason. These are not
      # important tables and can be safely ignored.
    end
  end

  # Partman is a gem in gems/canvas_partman that tries to do some automatic
  # relationships based on column names like "thing_id" and "thing_type".
  # It is not avoided by skipping validations or callbacks, so we have to fill
  # in those _id columns.
  def get_partman_attributes(model)
    relation_names = find_partman_columns(model)
    attributes = {}
    relation_names.each do |relation_name|
      attributes[relation_name + '_id'] = 1
      attributes[relation_name + '_type'] = polymorphic_class_name(model, relation_name)
    end

    attributes
  end

  def find_partman_columns(model)
    model.columns.map { |column|
      is_partman_column = false
      relation_name = nil

      # Look for a column name that ends with _id, then look for a matching
      # column that ends with _type.
      if column.name.end_with?("_id")
        column_without_suffix = column.name[0..-4]
        is_partman_column = model.columns.any?{ |col| col.name == column_without_suffix + '_type' }
        relation_name = column_without_suffix if is_partman_column
      end

      relation_name
    }.compact
  end

  # This method tries to find a valid class name to fill in for columns that store
  # the class name in a polymorphic relationship. (E.g., the 'context_type' column.)
  # Uses "Account" as a default value.
  def polymorphic_class_name(model, relation_name)
    class_name = 'Account'
    reflections = model.reflections[relation_name].options[:polymorphic] rescue nil
    reflections&.each do |reflection|
      # These key/value pairs look like { underscored_name: 'ClassName' }.
      # A value is only given if underscored_name does not describe a class.
      # If a value is there, that is the class name.
      if reflection.is_a? Hash
        class_name = reflection.values.first
        break
      end

      # If a value was not given, turn underscored_name into a class name.
      classified_name = ActiveSupport::Inflector.classify(reflection)
      # Check if the class name exists.
      if ActiveSupport::Inflector.constantize(classified_name)
        class_name = classified_name
        break
      end
    end

    class_name
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
      class_name = model.attribute_types[column.name].coder.object_class.name
      case class_name
      when 'Hash', 'Object'
        {foo: 'bar'}
      when 'Array'
        ['foo']
      else raise "Model #{model.name} has serializable column #{column.name} of unknown type #{class_name}"
      end
    else
      char_limit = 8
      char_limit = [column.limit, char_limit].min if column.limit
      'a' * char_limit
    end
  end

  def fixture_file_path(model)
    FIXTURES_BASEDIR + '/' + model.name.underscore + '.rb'
  end

  def set_inheritance_column(model)
    attrs = {}
    attrs = {'type' => model.descendants.first.name} if model.has_attribute?(:type)
    attrs
  end

  def records?(table_name)
    ActiveRecord::Base.connection.exec_query("SELECT * FROM #{Shard.current.name}.#{table_name}").any?
  end

end
