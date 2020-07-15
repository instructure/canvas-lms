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
      AccessToken => :developer_key,
      AccountUser => :account,
      AssessmentQuestion => :assessment_question_bank,
      AssessmentQuestionBank => :context,
      AssetUserAccess => [:context_course, :context_group, {context_account: [:root_account_id, :id]}],
      AssignmentGroup => :context,
      AssignmentOverride => :assignment,
      AssignmentOverrideStudent => :assignment,
      CalendarEvent => [:context_course, :context_group, :context_course_section],
      ContentMigration => [:account, :course, :group],
      ContentParticipation => :content,
      ContentParticipationCount => :course,
      ContentShare => [:course, :group],
      ContextExternalTool => [{context: [:root_account_id, :id]}],
      ContextModule => :context,
      ContextModuleProgression => :context_module,
      CourseAccountAssociation => :account,
      CustomGradebookColumn => :course,
      CustomGradebookColumnDatum => :custom_gradebook_column,
      ContentTag => :context,
      DeveloperKey => :account,
      DeveloperKeyAccountBinding => :account,
      DiscussionEntry => :discussion_topic,
      DiscussionEntryParticipant => :discussion_entry,
      DiscussionTopic => :context,
      DiscussionTopicParticipant => :discussion_topic,
      EnrollmentState => :enrollment,
      GradingPeriod => :grading_period_group,
      GradingPeriodGroup => [{root_account: [:root_account_id, :id]}, :course],
      GradingStandard => :context,
      GroupCategory => :context,
      GroupMembership => :group,
      LatePolicy => :course,
      LearningOutcome => :content_tag, # dependency, but not association
      LearningOutcomeGroup => :context,
      LearningOutcomeQuestionResult => :learning_outcome_result,
      LearningOutcomeResult => :context,
      Lti::LineItem => :assignment,
      Lti::ResourceLink => :context_external_tool,
      Lti::Result => :line_item,
      MasterCourses::ChildContentTag => :child_subscription,
      MasterCourses::ChildSubscription => :child_course,
      MasterCourses::MasterContentTag => :master_template,
      MasterCourses::MasterMigration => :master_template,
      MasterCourses::MasterTemplate => :course,
      MasterCourses::MigrationResult => :master_migration,
      OriginalityReport => :submission,
      OutcomeProficiency => :account,
      OutcomeProficiencyRating => :outcome_proficiency,
      PostPolicy => :course,
      Quizzes::Quiz => :course,
      Quizzes::QuizGroup => :quiz,
      Quizzes::QuizQuestion => :quiz,
      Quizzes::QuizSubmission => :quiz,
      RoleOverride => :account,
      Rubric => :context,
      RubricAssessment => :rubric,
      RubricAssociation => :context,
      Score => :enrollment,
      ScoreStatistic => :assignment,
      Submission => :assignment,
      SubmissionComment => :course,
      SubmissionVersion => :course,
      UserAccountAssociation => :account,
      WebConference => :context,
      WebConferenceParticipant => :web_conference,
      Wiki => [:course, :group],
      WikiPage => :context,
    }.freeze
  end

  # for special case tables that populate root_account_id in a different
  # way than the normal tables above, but still would like access to the
  # job cycle this backfill provides
  #
  # Each key points to a code module. This module is expected to have a
  # `populate` method that takes `(table, assoc, min, max)`.
  #
  # Tables that are listed here may list their dependencies in the
  # `migration_tables` hash above.
  def self.populate_overrides
    {
      LearningOutcome => DataFixup::PopulateRootAccountIdsOnLearningOutcomes
    }.freeze
  end

  def self.multiple_root_account_ids_tables
    [
      LearningOutcome
    ].freeze
  end

  # tables that have been filled for a while already
  DONE_TABLES = [Account, Assignment, Course, CourseSection, Enrollment, EnrollmentDatesOverride, EnrollmentTerm, Group].freeze

  def self.run
    clean_and_filter_tables.each do |table, assoc|
      table.find_ids_in_ranges(batch_size: 100_000) do |min, max|
        # default populate method
        unless populate_overrides.key?(table)
          self.send_later_if_production_enqueue_args(:populate_root_account_ids,
          {
            priority: Delayed::MAX_PRIORITY,
            n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
          },
          table, assoc, min, max)
        else
          # allow for one or more override methods of population
          Array(populate_overrides[table]).each do |override_module|
            self.send_later_if_production_enqueue_args(:populate_root_account_ids_override,
            {
              priority: Delayed::MAX_PRIORITY,
              n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
            },
            table, override_module, min, max)
          end
        end
      end
    end
  end

  # Returns a Hash of model class => associations where root account ID
  # can be found. Also normalizes the associations hash, expands polymorphic
  # associations, and assumes root_account_id is the column name unless specified.
  # Also checks table dependencies to see if it can begin backfilling, whether
  # those dependencies are associations on the table or just other tables.
  #
  # Start with {Group => {context: [:root_account_id, :id], ContextModule => :context} will yield
  # { Group => { course: [:root_account_id, :id], account: [:root_account_id, :id] },
  #   ContextModule => {course: :root_account_id} }
  def self.clean_and_filter_tables
    tables_in_progress = in_progress_tables
    incomplete_tables = []
    complete_tables = []
    migration_tables.each_with_object({}) do |(table, assoc), memo|
      incomplete_tables << table && next unless table.column_names.include?(get_column_name(table))
      next if (tables_in_progress + complete_tables + DONE_TABLES).include?(table)
      association_hash = hash_association(assoc)
      direct_relation_associations = replace_polymorphic_associations(table, association_hash)
      check_if_table_has_root_account(table, direct_relation_associations.keys) ? complete_tables << table && next : incomplete_tables << table
      prereqs_ready = direct_relation_associations.keys.all? do |a|
        class_name = table.reflections[a.to_s]&.class_name&.constantize || a.to_s.classify.safe_constantize
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
    Delayed::Job.where(strand: "root_account_id_backfill/#{Shard.current.database_server.id}",
      shard_id: Shard.current).map do |job|
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
      # ignore non-association dependencies
      next unless table.reflections[assoc.to_s]

      assoc_options = table.reflections[assoc.to_s].options
      prefix = assoc_options[:polymorphic_prefix] ? "#{assoc}_" : ""
      if assoc_options[:polymorphic].present?
        assoc_options[:polymorphic].each do |poly_a|
          poly_a = poly_a.keys.first if poly_a.is_a? Hash
          account_columns = [:root_account_id, :id] if poly_a == :account
          memo[:"#{prefix}#{poly_a}"] = account_columns || columns
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
    return false if class_name.column_names.exclude?(get_column_name(class_name))
    if associations.blank?
      return unfillable_tables.include?(class_name) ||
        empty_root_account_column_scope(class_name).none?
    end
    associations.all?{|a| empty_root_account_column_scope(class_name).joins(a).none?}
  end

  # In case we run into other tables that can't fully finish being filled with
  # root account ids, and they have children who need them to pretend they're full
  def self.unfillable_tables
    [DeveloperKey]
  end

  def self.empty_root_account_column_scope(table)
    if multiple_root_account_ids_tables.include?(table)
      # takes care of nil and empty arrays
      table.where("ARRAY_LENGTH(#{table.quoted_table_name}.root_account_ids, 1) IS NULL")
    else
      table.where(root_account_id: nil)
    end
  end

  def self.get_column_name(table)
    multiple_root_account_ids_tables.include?(table) ? "root_account_ids" : "root_account_id"
  end

  def self.populate_root_account_ids(table, associations, min, max)
    primary_key_field = table.primary_key
    table.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      associations.each do |assoc, columns|
        account_id_column = create_column_names(table.reflections[assoc.to_s], columns)
        table.where(primary_key_field => batch_min..batch_max, root_account_id: nil).
          joins(assoc).
          update_all("root_account_id = #{account_id_column}")
      end
    end

    unlock_next_backfill_job(table)
  end

  def self.populate_root_account_ids_override(table, override_module, min, max)
    override_module.populate(min, max)

    unlock_next_backfill_job(table)
  end

  def self.create_column_names(assoc, columns)
    names = Array(columns).map{|column| "#{assoc.klass.table_name}.#{column}"}
    names.count == 1 ? names.first : "COALESCE(#{names.join(', ')})"
  end

  def self.unlock_next_backfill_job(table)
    # when the current table has been fully backfilled, restart the backfill job
    # so it can check to see if any new tables can begin working based off of this table
    if table.where(get_column_name(table) => nil).none?
      self.send_later_if_production_enqueue_args(:run, {
        priority: Delayed::LOWER_PRIORITY,
        singleton: "root_account_id_backfill_strand_#{Shard.current.id}"
      })
    end
  end
end
