require 'canvas_partman/partition_manager'
require 'canvas_partman/migration'
require 'canvas_partman/dynamic_relation'
require 'canvas_partman/concerns/partitioned'

module CanvasPartman
  class << self
    # @property [String, "partitions"] migrations_scope
    #   The filename "scope" that identifies partition migrations. This is a key
    #   that is separated from the name of the migration file and the "rb"
    #   extension by dots.
    #
    #   Example: "partitions" => "20141215000000_add_something.partitions.rb"
    attr_accessor :migrations_scope
  end

  self.migrations_scope = 'partitions'
end
