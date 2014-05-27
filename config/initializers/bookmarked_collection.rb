# Initialize BookmarkedCollection gem

Rails.configuration.to_prepare do
  BookmarkedCollection.best_unicode_collation_key_proc = lambda { |col|
    ActiveRecord::Base.best_unicode_collation_key(col)
  }
end
