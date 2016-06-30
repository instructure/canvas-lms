module DataFixup
  module FixOldSubmissionVersionYAML
    def self.run
      Version.find_ids_in_ranges do |min_id, max_id|
        Version.where(:id => min_id..max_id, :versionable_type => "Submission").
                where("yaml LIKE ?", "%cached_due_date: !ruby/string%").each do |version|
          begin
            yaml = version.yaml.sub("cached_due_date: !ruby/string", "cached_due_date: ")
            obj = YAML.load(yaml)
            obj["cached_due_date"] = Time.parse(obj["cached_due_date"]["str"])
            version.yaml = YAML.dump(obj)
            version.save!
          rescue
            Rails.logger.error("Error occured trying to process Version #{version.global_id}")
          end
        end
      end
    end
  end
end
