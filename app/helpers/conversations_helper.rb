module ConversationsHelper

  def contexts_for(audience, context_tags)
    result = {:courses => {}, :groups => {}}
    return result if audience.empty?
    context_tags.inject(result) do |hash, tag|
      next unless tag =~ /\A(course|group)_(\d+)\z/
      hash["#{$1}s".to_sym][$2.to_i] = []
      hash
    end
    if audience.size == 1 && include_private_conversation_enrollments
      audience.first.common_courses.each do |id, enrollments|
        result[:courses][id] = enrollments if result[:courses][id]
      end
      audience.first.common_groups.each do |id, enrollments|
        result[:groups][id] = enrollments if result[:groups][id]
      end
    end
    result
  end

end
