module DataFixup::FixImportedWikiFrontPages
  # some Wiki objects are getting has_no_front_page set to true, even when there should be a front page
  def self.potentially_broken_wikis
    Wiki.where(:has_no_front_page => true)
  end

  def self.run
    self.potentially_broken_wikis.find_in_batches do |wikis|
      Wiki.where(:id => wikis).update_all(:has_no_front_page => nil)
    end
  end
end
