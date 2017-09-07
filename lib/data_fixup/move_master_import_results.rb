module DataFixup::MoveMasterImportResults
  def self.run
    MasterCourses::MasterMigration.find_ids_in_ranges do |min_id, max_id|
      MasterCourses::MasterMigration.where(:id => min_id..max_id).where.not(:import_results => nil).each do |mig|
        mig.import_results.each do |cm_id, res|
          next if mig.migration_results.where(:content_migration_id => cm_id).exists?

          attrs = {
            :content_migration_id => cm_id,
            :state => res[:state],
            :child_subscription_id => res[:subscription_id],
            :import_type => res[:import_type]
          }
          if res[:skipped].present?
            attrs[:results] = {:skipped => res[:skipped]}
          end
          mig.migration_results.create!(attrs)
        end
        mig.import_results = {}
        mig.save!
      end
    end
  end
end
