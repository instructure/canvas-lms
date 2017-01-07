module MasterCourses::TagHelper
  # may as well just reuse the code
  def self.included(klass)
    klass.cattr_accessor :content_tag_association
  end

  def content_tags
    self.send(self.content_tag_association)
  end

  def load_tags!
    return if @content_tag_index
    @content_tag_index = {}
    self.content_tags.to_a.group_by(&:content_type).each do |content_type, typed_tags|
      @content_tag_index[content_type] = typed_tags.index_by(&:content_id)
    end
    true
  end

  def content_tag_for(content, defaults={})
    return unless MasterCourses::ALLOWED_CONTENT_TYPES.include?(content.class.base_class.name)
    if @content_tag_index
      tag = (@content_tag_index[content.class.base_class.name] || {})[content.id]
      unless tag
        tag = create_content_tag_for!(content, defaults)
        @content_tag_index[content.class.base_class.name] ||= {}
        @content_tag_index[content.class.base_class.name][content.id] = tag
      end
      tag
    else
      self.content_tags.polymorphic_where(:content => content).first || create_content_tag_for!(content, defaults)
    end
  end

  def create_content_tag_for!(content, defaults={})
    self.class.unique_constraint_retry do |retry_count|
      tag = nil
      tag = self.content_tags.polymorphic_where(:content => content).first if retry_count > 0
      tag ||= self.content_tags.create!(defaults.merge(:content => content))
      tag
    end
  end
end
