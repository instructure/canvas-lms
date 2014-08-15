module DataFixup::FixContentTagsWithoutContent
  def self.run
    while ContentTag.where("context_module_id IS NOT NULL AND content_id IS NULL AND
                            content_type IS NULL AND tag_type = ?", "default").limit(1000).delete_all > 0
    end
  end
end