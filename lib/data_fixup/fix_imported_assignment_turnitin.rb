module DataFixup
  module FixImportedAssignmentTurnitin
    def self.run
      start_at = DateTime.parse("2016-06-24")
      Assignment.find_ids_in_ranges(:batch_size => 10_000) do |min_id, max_id|
        assmt_ids = Assignment.where(:id => min_id..max_id, :turnitin_enabled => true).where("assignments.created_at > ?", start_at).where.not(:migration_id => nil).
          joins("LEFT OUTER JOIN #{Submission.quoted_table_name} ON submissions.assignment_id=assignments.id").where("submissions IS NULL").pluck(:id)
        next unless assmt_ids.any?

        Assignment.where(:id => assmt_ids).each do |assmt|
          settings = assmt.turnitin_settings
          if settings[:created]
            settings[:created] = false
            assmt.turnitin_settings = settings
            assmt.save!
          end
        end
      end
    end
  end
end