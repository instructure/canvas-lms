class MagicFieldSchema < ActiveRecord::Base
  def self.for_key(key)
    mfs = MagicFieldSchema.find_by_field_key(key)
    if mfs.nil?
      mfs = MagicFieldSchema.new
      mfs.field_key = key
    end
    mfs
  end

  def schema
    JSON.parse(schema_json)
  end
end
