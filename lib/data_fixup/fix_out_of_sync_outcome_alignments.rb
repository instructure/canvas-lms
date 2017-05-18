#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module DataFixup::FixOutOfSyncOutcomeAlignments
  def self.run
    # Active alignments to deleted rubrics
    scope = ContentTag.joins("
      INNER JOIN #{Rubric.quoted_table_name} r
        ON content_tags.content_id = r.id
        AND content_tags.content_type = 'Rubric'
    ").select("content_tags.*")
    scope = scope.where("
      content_tags.tag_type = 'learning_outcome'
      AND content_tags.workflow_state = 'active'
      AND r.workflow_state = 'deleted'
    ")
    scope.find_each do |ct|
      ct.destroy
    end

    # Active alignments to rubrics that should no longer be aligned
    scope = ContentTag.joins("
      INNER JOIN #{Rubric.quoted_table_name} r
        ON content_tags.content_id = r.id
        AND content_tags.content_type = 'Rubric'
    ").select("content_tags.*")
    scope = scope.where("
      content_tags.tag_type = 'learning_outcome'
      AND content_tags.workflow_state = 'active'
      AND r.workflow_state = 'active'
      AND NOT r.data LIKE '%learning_outcome_id: ' || content_tags.learning_outcome_id || '%'
    ")
    scope.find_each do |ct|
      ct.destroy
    end

    # Active alignments to assignments without rubrics
    scope = ContentTag.joins("
      INNER JOIN #{Assignment.quoted_table_name} a
        ON content_tags.content_id = a.id
        AND content_tags.content_type = 'Assignment'
      LEFT OUTER JOIN #{RubricAssociation.quoted_table_name} ra
        ON ra.association_id = a.id
        AND ra.association_type = 'Assignment'
    ").select("content_tags.*")
    scope = scope.where("
      content_tags.tag_type = 'learning_outcome'
      AND content_tags.workflow_state = 'active'
      AND ra.id IS NULL
    ")
    scope.find_each do |ct|
      ct.destroy
    end

    # Active alignments to assignments with rubrics
    # that don't have a matching alignment
    scope = ContentTag.joins("
      INNER JOIN #{Assignment.quoted_table_name} a
        ON content_tags.content_id = a.id
        AND content_tags.content_type = 'Assignment'
      INNER JOIN #{RubricAssociation.quoted_table_name} ra
        ON ra.association_id = a.id
        AND ra.association_type = 'Assignment'
      INNER JOIN #{Rubric.quoted_table_name} r
        ON ra.rubric_id = r.id
      LEFT OUTER JOIN #{ContentTag.quoted_table_name} ct2
        ON ct2.content_id = r.id
        AND ct2.content_type = 'Rubric'
        AND ct2.tag_type = 'learning_outcome'
        AND ct2.workflow_state = 'active'
        AND ct2.learning_outcome_id = content_tags.learning_outcome_id
    ").select("content_tags.*")
    scope = scope.where("
      content_tags.tag_type = 'learning_outcome'
      AND content_tags.workflow_state = 'active'
      AND ct2.id IS NULL
    ")
    scope.find_each do |ct|
      ct.destroy
    end
  end
end
