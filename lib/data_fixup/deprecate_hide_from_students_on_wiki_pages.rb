module DataFixup::DeprecateHideFromStudentsOnWikiPages
  def self.run
    WikiPage.find_ids_in_ranges do |min_id, max_id|
      WikiPage.where(id: min_id..max_id)
        .where("hide_from_students IS NOT NULL")
        .update_all("hide_from_students=NULL, workflow_state=CASE WHEN hide_from_students AND workflow_state='active' THEN 'unpublished' ELSE workflow_state END")
    end
  end
end
