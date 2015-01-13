module DataFixup::FixGroupDiscussionSubmissions
  def self.run
    DiscussionTopic.where("assignment_id IS NOT NULL").where(:context_type => "Group").find_each do |topic|
      if topic.for_assignment?
        topic.posters.each do |user|
          if topic.context.grants_right?(user, :participate_as_student) && topic.assignment.visible_to_user?(user)
            topic.ensure_submission(user)
          end
        end
      end
    end
  end
end