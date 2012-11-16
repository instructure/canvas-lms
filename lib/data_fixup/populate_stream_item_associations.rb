module DataFixup::PopulateStreamItemAssociations
  def self.run
    StreamItem.scoped(:conditions => "context_type IS NULL OR asset_type IS NULL").find_each do |si|
      si.context_type, si.context_id = ActiveRecord::Base.parse_asset_string(si.context_code) if si.context_code.present?
      si.asset_type, si.asset_id = ActiveRecord::Base.parse_asset_string(si.item_asset_string) if si.item_asset_string.present?
      begin
        si.save! if si.changed?
      rescue ActiveRecord::UniqueConstraintViolation
        # duplicate!
        # we have no way of knowing which one (or both) has stream item instances,
        # so just let the first one win
        si.destroy
      end
    end

    StreamItemInstance.scoped(:conditions => "context_type IS NULL").find_each do |sii|
      sii.context_type, sii.context_id = ActiveRecord::Base.parse_asset_string(sii.context_code) if sii.context_code.present?
      sii.save! if sii.changed?
    end
  end
end
