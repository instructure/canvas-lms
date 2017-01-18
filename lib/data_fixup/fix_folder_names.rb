module DataFixup
  module FixFolderNames
    def self.run
      wildcards = []
      [" ", "\t", "\r", "\n"].each do |ws|
        wildcards += ["#{ws}%", "%#{ws}"]
      end

      Folder.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        Folder.active.where(:id => min_id..max_id).where((["(name LIKE ?)"] * wildcards.count).join(" OR "), *wildcards).each do |f|
          f.name = f.name.strip
          f.save
        end
      end
    end
  end
end
