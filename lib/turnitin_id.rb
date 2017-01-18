module TurnitinID
  def generate_turnitin_id!
    # the reason we don't just use the global_id all the time is so that the
    # turnitin_id is preserved when shard splits/etc. occur
    turnitin_id || update_attribute(:turnitin_id, global_id)
  end

  def turnitin_asset_string
    generate_turnitin_id!
    "#{self.class.reflection_type_name}_#{turnitin_id}"
  end
end
