module DataFixup::PopulateContextOnWikiPages
  def self.run
    WikiPage.find_ids_in_ranges do |min_id, max_id|
      WikiPage.where(:id => min_id..max_id, :context_id => nil).joins(:wiki => :course).update_all("context_type='Course', context_id=courses.id")
      WikiPage.where(:id => min_id..max_id, :context_id => nil).joins(:wiki => :group).update_all("context_type='Group', context_id=groups.id")
    end
  end
end
