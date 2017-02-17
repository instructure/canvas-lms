# SimplyVersioned 0.9.3
#
# Simple ActiveRecord versioning
# Copyright (c) 2007,2008 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

# A Version represents a numbered revision of an ActiveRecord model.
#
# The version has two attributes +number+ and +yaml+ where the yaml attribute
# holds the representation of the ActiveRecord model attributes. To access
# these call +model+ which will return an instantiated model of the original
# class with those attributes.
#
class Version < ActiveRecord::Base #:nodoc:
  belongs_to :versionable, :polymorphic => true

  validates_presence_of :versionable_id, :versionable_type

  before_create :initialize_number
  
  # Return an instance of the versioned ActiveRecord model with the attribute
  # values of this version.
  def model
    @model ||= begin
      obj = versionable_type.constantize.new
      YAML::load( self.yaml ).each do |var_name,var_value|
        # INSTRUCTURE:  added if... so that if a column is removed in a migration after this was versioned it doesen't die with NoMethodError: undefined method `some_column_name=' for ...
        obj.write_attribute(var_name, var_value) if obj.class.columns_hash[var_name]
      end
      obj.instance_variable_set(:@new_record, false)
      obj.simply_versioned_options[:on_load].try(:call, obj, self)
      # INSTRUCTURE: Added to allow model instances pulled out
      # of versions to still know their version number
      obj.simply_versioned_version_model = true
      obj.send("force_version_number", self.number)
      obj
    end
  end

  # INSTRUCTURE: Added to allow previous version models to be updated
  def model=(model)
    options = model.class.simply_versioned_options
    self.yaml = model.attributes.except(*options[:exclude]).to_yaml
  end

  # Return the next higher numbered version, or nil if this is the last version
  def next
    versionable.versions.next_version( self.number )
  end

  # Return the next lower numbered version, or nil if this is the first version
  def previous
    versionable.versions.previous_version( self.number )
  end

  # If the model has new columns that it didn't have before just return nil
  def method_missing(method_name, *args, &block)
    if read_attribute(:versionable_type) && read_attribute(:versionable_type).constantize.column_names.member?(method_name.to_s)
      return nil
    else
      super
    end
  end

  protected
  def initialize_number
    self.number = (versionable.versions.maximum( :number ) || 0) + 1
  end

end
