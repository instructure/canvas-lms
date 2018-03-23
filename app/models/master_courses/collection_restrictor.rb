#
# Copyright (C) 2016 - present Instructure, Inc.
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

module MasterCourses::CollectionRestrictor
  # this is super similar to the normal Restrictor - the main difference is that these models are locked by some parent object
  # e.g. this is a quiz question locked by a quiz
  # even though they do a lot of the same things, i couldn't figure out a way to keep them together that didn't make things super convoluted

  # FYI you'll have to directly hook code that replicates the behavior of
  # `check_before_overwriting_child_content_on_import` into the respective importers if you add this to new objects

  def self.included(klass)
    klass.include MasterCourses::Restrictor::CommonMethods
    klass.extend ClassMethods

    klass.cattr_accessor :collection_owner_association # this is the association to find the quiz

    klass.after_update :mark_downstream_changes
  end

  module ClassMethods
    def restrict_columns(edit_type, columns)
      raise "set the collection owner first" unless self.collection_owner_association

      super
      owner_class = self.reflections[self.collection_owner_association.to_s].klass
      owner_class.restrict_columns(edit_type, pseudocolumn_for_type(edit_type)) # e.g. add "assessment_questions_content" as a restricted column
    end

    def pseudocolumn_for_type(type) # prepend with table name because it looks better than "Quizzes::QuizQuestion"
      "#{self.table_name}_#{type}"
    end
  end

  def check_restrictions?
    if self.is_a?(Quizzes::QuizQuestion)
      !self.generated? # allow updating through the bank even though it's technically locked... shhh don't tell anybody
    else
      true
    end
  end

  def owner_for_restrictions
    self.send(self.class.base_class.collection_owner_association)
  end

  # delegate to the owner
  def is_child_content?
    owner_for_restrictions && owner_for_restrictions.is_child_content?
  end

  def child_content_restrictions
    self.owner_for_restrictions.child_content_restrictions
  end

  def mark_downstream_changes
    return if @importing_migration || !is_child_content? # don't mark changes on import

    # instead of marking the exact columns - i'm just going to be lazy and mark the edit type on the owner, e.g. "quiz_questions_content"
    changed_types = []
    self.class.base_class.restricted_column_settings.each do |edit_type, columns|
      if (self.saved_changes.keys & columns).any?
        changed_types << self.class.pseudocolumn_for_type(edit_type) # pretend it's sort of like a column in the downstream changes
      end
    end
    self.owner_for_restrictions.mark_downstream_changes(changed_types) if changed_types.any? # store changes on owner
  end
end
