#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdOnModels

  # migration_tables should be a hash of a model and the association that has access to the root_account on that model
  # migration_tables should not need to be ordered, the job will try to determine if the required association
  # backfill has been completed, and wait to run it later when the requirements have completed if necessary.
  # You can use an array of associations if needed.  The column name will be assumed to be root_account_id
  # unless the association is a hash. Column names will be used in the order they are provided.
  # Ex: migration_tables = {
  #   Submission => [{assignment: [:root_account_id, :id]}, :user],
  #   OriginalityReport => :submission
  # }
  #
  # If you have a table where you want to use a polymorphic association, but you want to skip one of
  # the associated tables, you'll want to use the long form of the polymorphic association and skip
  # the association you don't want
  # Ex: migration_tables = {Attachment => :context} would turn in to
  # Attachment => [:account, :assessment_question, :assignment, :attachment, :content_export,
  #   :content_migration, :course, :eportfolio, :epub_export, :gradebook_upload, :group, :submission,
  #   :purgatory, {:context_folder=>"Folder", :context_sis_batch=>"SisBatch",
  #   :context_outcome_import=>"OutcomeImport", :context_user=>"User", :quiz=>"Quizzes::Quiz",
  #   :quiz_statistics=>"Quizzes::QuizStatistics", :quiz_submission=>"Quizzes::QuizSubmission"}] normally, but
  # if we want to avoid the users association, we could put it in the hash as
  # Attachment => [:account, :assessment_question, :assignment, :attachment, :content_export,
  #   :content_migration, :course, :eportfolio, :epub_export, :gradebook_upload, :group, :submission,
  #   :purgatory, {:context_folder=>"Folder", :context_sis_batch=>"SisBatch",
  #   :context_outcome_import=>"OutcomeImport", :quiz=>"Quizzes::Quiz",
  #   :quiz_statistics=>"Quizzes::QuizStatistics", :quiz_submission=>"Quizzes::QuizSubmission"}]
  #
  # You can also overwrite one table from a polymorphic association in the case where you might need a
  # different column from one of the polymorphic tables.  To do this, put the overwriting table at the end
  # For example, Group can have a context of account or course.  Account root accounts can come from
  # root_account_id or id
  # Ex: migration_tables = {Group => [:context, {account: [:root_account_id, :id]}]}
  # (Note that this specific example is handled by the association resolver now, so Account associations will
  # automatically have [:root_account_id, :id])
  #
  # NOTE: This code will NOT work with any models that need to have multiple root account ids
  # or any models that do not have a root_account_id column.
  def self.migration_tables
    {
      ContextModule => :context, DeveloperKey => {account: [:root_account_id, :id]},
      DeveloperKeyAccountBinding => {account: [:root_account_id, :id]},
      DiscussionTopic => :context,
      DiscussionTopicParticipant => :discussion_topic,
      Quizzes::Quiz => :course
    }.freeze
  end

  # tables that have been filled for a while already
  DONE_TABLES = [Account, Assignment, Course, Enrollment].freeze

  def self.run
    clean_and_filter_tables.each do |table, assoc|
      table.where(root_account_id: nil).find_ids_in_ranges(batch_size: 100_000) do |min, max|
        self.send_later_if_production_enqueue_args(:populate_root_account_ids,
          {
            priority: Delayed::MAX_PRIORITY,
            n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
          },
          table, assoc, min, max)
      end
    end
  end

  # Returns a Hash of model class => associations where root account ID
  # can be found. Also normalizes the associations hash, expands polymorphic
  # associations, and assumes root_account_id is the column name unless specified.
  #
  # Start with {Group => {context: [:root_account_id, :id], ContextModule => :context} will yield
  # { Group => { course: [:root_account_id, :id], account: [:root_account_id, :id] },
  #   ContextModule => {course: :root_account_id} }
  def self.clean_and_filter_tables
    tables_in_progress = in_progress_tables
    incomplete_tables = []
    complete_tables = []
    migration_tables.each_with_object({}) do |(table, assoc), memo|
      incomplete_tables << table && next unless table.column_names.include?('root_account_id')
      next if (tables_in_progress + complete_tables + DONE_TABLES).include?(table)
      association_hash = hash_association(assoc)
      direct_relation_associations = replace_polymorphic_associations(table, association_hash)
      check_if_table_has_root_account(table, direct_relation_associations.keys) ? complete_tables << table && next : incomplete_tables << table
      prereqs_ready = direct_relation_associations.keys.all? do |a|
        class_name = table.reflections[a.to_s]&.class_name&.constantize
        if (complete_tables + DONE_TABLES).include?(class_name)
          true
        elsif incomplete_tables.include?(class_name) || tables_in_progress.include?(class_name)
          false
        else
          check_if_table_has_root_account(class_name) ? complete_tables << table && true : incomplete_tables << table && false
        end
      end
      memo[table] = direct_relation_associations if prereqs_ready
    end
  end

  def self.in_progress_tables
    Delayed::Job.where(strand: "root_account_id_backfill/#{Shard.current.database_server.id}").map do |job|
        job.payload_object.try(:args)&.first
    end.uniq.compact
  end

  def self.hash_association(association)
    # we want a hash of tables with their associated column names
    case association
    when Hash
      association.each_with_object({}) do |(assoc, column), memo|
        memo[assoc.to_sym] = column.is_a?(Array) ? column.map(&:to_sym) : column.to_sym
      end
    when Array
      association.reduce({}){|memo, assoc| memo.merge(hash_association(assoc))}
    when String, Symbol
      {association.to_sym => :root_account_id}
    else
      raise "Unexpected association type for root_account association: #{association.class}"
    end
  end

  # Replaces polymorphic associations in the association_hash with their component associations
  # Eg: ContentTag with association of {context: :root_account_id} becomes
  # {
  #   :course=>:root_account_id,
  #   :learning_outcome_group=>:root_account_id,
  #   :assignment=>:root_account_id,
  #   :account=>[:root_account_id, :id],
  #   :quiz=>:root_account_id
  # }
  # Also accounts for polymorphic associations that have a prefix, since the usual associations
  # aren't present
  # Eg: CalendarEvent with association of {context: :root_account_id} becomes
  # {
  #   :context_course=>:root_account_id,
  #   :context_learning_outcome_group=>:root_account_id,
  #   :context_assignment=>:root_account_id,
  #   :context_account=>[:root_account_id, :id],
  #   :context_quiz=>:root_account_id
  # }
  # Accounts are a special case, since subaccounts will have a root_account_id but root accounts
  # have a nil root_account_id and will just use their id instead
  # Eg: ContextExternalTool with association of {context: :root_account_id} becomes
  # {
  #   :account=>[:root_account_id, :id],
  #   :course=>:root_account_id
  # }
  def self.replace_polymorphic_associations(table, association_hash)
    association_hash.each_with_object({}) do |(assoc, columns), memo|
      assoc_options = table.reflections[assoc.to_s].options
      prefix = assoc_options[:polymorphic_prefix] ? "#{assoc}_" : ""
      if assoc_options[:polymorphic].present?
        assoc_options[:polymorphic].each do |poly_a|
          poly_a = poly_a.keys.first if poly_a.is_a? Hash
          columns = [:root_account_id, :id] if assoc == :account
          memo[:"#{prefix}#{poly_a}"] = columns
        end
      else
        columns = [:root_account_id, :id] if assoc == :account
        memo[assoc] = columns
      end
    end
  end

  # if you provide a list of associations to this method, it will only check on the
  # tables items that have that association, so an attachment may be associated to a User
  # and not have a root account ID, but if you provide a list of associations like
  # [:course, :assignment], it will not check Attachments with a user as the context
  # and return true (assuming the course and assignment attachments have root account ids)
  # thus allowing us to pretend the Attachments table has been backfilled where necessary
  def self.check_if_table_has_root_account(class_name, associations=[])
    return false if class_name.column_names.exclude?('root_account_id')
    return class_name.where(root_account_id: nil).none? if associations.blank? 
    associations.all?{|a| class_name.joins(a).where(root_account_id: nil).none?}
  end

  def self.populate_root_account_ids(table, associations, min, max)
    table.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      associations.each do |assoc, columns|
        account_id_column = create_column_names(assoc, columns)
        table.where(id: batch_min..batch_max, root_account_id: nil).
          joins(assoc).
          update_all("root_account_id = #{account_id_column}")
      end
    end

    unlock_next_backfill_job(table)
  end

  def self.create_column_names(assoc, columns)
    names = Array(columns).map{|column| "#{assoc.to_s.tableize}.#{column}"}
    names.count == 1 ? names.first : "COALESCE(#{names.join(', ')})"
  end

  def self.unlock_next_backfill_job(table)
    # when the current table has been fully backfilled, restart the backfill job
    # so it can check to see if any new tables can begin working based off of this table
    if table.where(root_account_id: nil).none?
      self.send_later_if_production_enqueue_args(:run, {
        priority: Delayed::LOWER_PRIORITY,
        strand: ["root_account_id_backfill_strand", Shard.current.database_server.id]
      })
    end
  end
end
