module SimpleTags
  module ReaderInstanceMethods
    def tags
      @tag_array ||= if tags = read_attribute(:tags)
        tags.split(',')
      else
        []
      end
    end

    def context_tags
      tags.grep(/\A(course|group)_\d+\z/)
    end

    def serialized_tags(tags=self.tags)
      return nil unless tags.present?
      SimpleTags.normalize_tags(tags).join(',')
    end

    def self.included(klass)
      klass.named_scope :tagged, lambda { |tag|
        {:conditions => klass.wildcard(klass.quoted_table_name + '.tags', tag, :delimiter => ',')}
      }
    end
  end

  module WriterInstanceMethods
    def tags=(new_tags)
      @tag_array = new_tags
    end

    def reload(*args)
      remove_instance_variable :@tag_array if @tag_array
      super
    end

    protected
    def serialize_tags
      if @tag_array
        write_attribute(:tags, serialized_tags)
        remove_instance_variable :@tag_array
      end
    end

    def self.included(klass)
      klass.before_save :serialize_tags
    end
  end

  def self.normalize_tags(tags)
    tags.inject([]) { |ary, tag|
      if tag =~ /\A((course|group)_\d+).*/
        ary << $1
      elsif tag =~ /\Asection_(\d+).*/
        section = CourseSection.find_by_id($1)
        ary << section.course.asset_string if section
      # TODO: allow user-defined tags, e.g. #foo
      end
      ary
    }.uniq
  end

  def self.included(klass)
    klass.send :include, ReaderInstanceMethods
    klass.send :include, WriterInstanceMethods
  end
end