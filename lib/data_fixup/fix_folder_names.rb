module DataFixup
  module FixFolderNames
    def self.run
      Folder.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        Folder.active.where(:id => min_id..max_id).where("name LIKE ?", "% ").each do |f|
          f.name = f.name.rstrip
          f.save
        end
      end
    end
  end
end
