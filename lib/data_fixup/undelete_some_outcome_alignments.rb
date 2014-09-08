module DataFixup::UndeleteSomeOutcomeAlignments
  def self.run
    occurred = Time.zone.parse("2013-09-14 00:00:00 UTC")
    rubric_ids = []

    # See lib/data_fixup/fix_out_of_sync_outcome_alignments, the second block
    # with the comment "Active alignments to rubrics that should no longer be
    # aligned".  When the data was a HashWithIndifferentAccess instead of just
    # a Hash, it didn't have the comma in front of learning_outcome_id.  This
    # brings those content tags back.
    scope = ContentTag.joins("
      INNER JOIN rubrics r
        ON content_tags.content_id = r.id
        AND content_tags.content_type = 'Rubric'
    ").select("content_tags.*")
    scope = scope.where("
      content_tags.tag_type = 'learning_outcome'
      AND content_tags.workflow_state = 'deleted'
      AND content_tags.updated_at > ?
      AND r.workflow_state = 'active'
      AND NOT r.data LIKE '%:learning_outcome_id: ' || content_tags.learning_outcome_id || '%'
      AND r.data LIKE '%learning_outcome_id: ' || content_tags.learning_outcome_id || '%'
    ", occurred)
    scope.find_each do |ct|
      ct.workflow_state = 'active'
      ct.save!
      rubric_ids << ct.content_id
    end

    # The fourth block in that same fixup then found outcomes that should no
    # longer be aligned to assignments, so we need to bring those back as well.
    rubric_ids.each_slice(1000) do |rids|
      scope = ContentTag.joins("
        INNER JOIN assignments a
          ON content_tags.content_id = a.id
          AND content_tags.content_type = 'Assignment'
        INNER JOIN rubric_associations ra
          ON ra.association_id = a.id
          AND ra.association_type = 'Assignment'
        INNER JOIN rubrics r
          ON ra.rubric_id = r.id
        INNER JOIN content_tags ct2
          ON ct2.content_id = r.id
          AND ct2.content_type = 'Rubric'
          AND ct2.tag_type = 'learning_outcome'
          AND ct2.workflow_state = 'active'
          AND ct2.learning_outcome_id = content_tags.learning_outcome_id
      ").select("content_tags.*")
      scope = scope.where("
        content_tags.tag_type = 'learning_outcome'
        AND content_tags.workflow_state = 'deleted'
        AND ct2.content_id IN (?)
        AND content_tags.updated_at > ?
      ", rids, occurred)
      scope.find_each do |ct|
        ct.workflow_state = 'active'
        ct.save!
      end
    end
  end
end
