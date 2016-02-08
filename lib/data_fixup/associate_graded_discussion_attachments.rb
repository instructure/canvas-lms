module DataFixup
  module AssociateGradedDiscussionAttachments
    def self.run
      DiscussionTopic.find_ids_in_ranges do |min_id, max_id|

        rows = DiscussionTopic.where(:id => min_id..max_id).where.not(:assignment_id => nil).
          joins(:discussion_entries).where.not(:discussion_entries => {:attachment_id => nil}).
          pluck("discussion_topics.assignment_id, discussion_entries.user_id, discussion_entries.attachment_id")

        map = {}
        rows.each do |asmt_id, user_id, att_id| # group attachment_ids by user/assignment pairs
          k = [asmt_id, user_id]
          map[k] ||= []
          map[k] << att_id
        end

        map.each do |k, attachment_ids|
          assignment_id, user_id = k
          sub = Submission.where(:assignment_id => assignment_id, :user_id => user_id, :attachment_ids => nil).first
          if sub
            sub.attachment_ids = attachment_ids.sort.map(&:to_s).join(',')
            sub.save!
          end
        end
      end
    end
  end
end