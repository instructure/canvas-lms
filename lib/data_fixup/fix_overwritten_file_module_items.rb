module DataFixup
  module FixOverwrittenFileModuleItems
    def self.run
      replacement_ids = []
      Attachment.find_ids_in_ranges(:batch_size => 10_000) do |min_id, max_id|
        replacement_ids += Attachment.where(:id => min_id..max_id, :file_state => 'deleted', :could_be_locked => true).
          where.not(:replacement_attachment_id => nil).pluck(:replacement_attachment_id)
      end
      replacement_ids.uniq.sort.each_slice(1000) do |sliced_ids|
        Attachment.where(:id => sliced_ids).where("could_be_locked IS NULL OR could_be_locked = ?", false).update_all(:could_be_locked => true)
      end
    end
  end
end
