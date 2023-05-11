# frozen_string_literal: true

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
      AssetUserAccess => [:context_course, :context_group, { context_account: Account.resolved_root_account_id_sql }],
      AssignmentGroup => :context,
      AssignmentOverride => [:assignment, :quiz],
      AssignmentOverrideStudent => [:assignment, :quiz],
      # Attachment is handled differently than other fix ups, it is triggered in the populate_overrides
      Attachment => [],
      AttachmentAssociation => %i[course group submission attachment], # attachment is last, only used if context is a ConversationMessage
      CalendarEvent => %i[context_course context_group context_course_section],
      CommunicationChannel => [], # has override
      ContentMigration => %i[account course group],
      ContentParticipation => :content,
      ContentParticipationCount => :course,
      ContentShare => [:course, :group],
      ContextExternalTool => :context,
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
      Favorite => :context,
      Folder => %i[account course group],
      GradingPeriod => :grading_period_group,
      GradingPeriodGroup => [{ root_account: Account.resolved_root_account_id_sql }, :course],
      GradingStandard => :context,
      GroupCategory => :context,
      GroupMembership => :group,
      LatePolicy => :course,
      LearningOutcome => [], # no associations, only dependencies
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
      Quizzes::QuizSubmissionEvent => :quiz_submission,
      Role => :account,
      RoleOverride => :account,
      Rubric => :context,
      RubricAssessment => :rubric,
      RubricAssociation => :context,
      Score => :enrollment,
      ScoreStatistic => :assignment,
      Submission => :assignment,
      SubmissionComment => :course,
      SubmissionVersion => :course,
      User => [],
      UserAccountAssociation => :account,
      WebConference => :context,
      WebConferenceParticipant => :web_conference,
      Wiki => [:course, :group],
      WikiPage => :context,
    }.freeze
  end

  # these are non-association dependencies, mostly used for override backfills
  def self.dependencies
    {
      AssetUserAccess => [:attachment, :calendar_event],
      Attachment => %i[account assessment_question assignment course group submission],
      CommunicationChannel => :user,
      LearningOutcome => :content_tag,
      User => :user_account_association,
    }.freeze
  end

  # for special case tables that populate root_account_id in a different
  # way than the normal tables above, but still would like access to the
  # job cycle this backfill provides
  #
  # Each key points to a code module. This module is expected to have a
  # `populate` method that takes `(min, max)`.
  #
  # Tables that are listed here must be also listed in the `migration_tables`
  # hash above, and may list their non-association dependencies in the
  # `dependencies` hash above.
  def self.populate_overrides
    {
      AssetUserAccess => DataFixup::PopulateRootAccountIdOnAssetUserAccesses,
      Attachment => DataFixup::PopulateRootAccountIdOnAttachments,
      CommunicationChannel => DataFixup::PopulateRootAccountIdsOnCommunicationChannels,
      LearningOutcome => DataFixup::PopulateRootAccountIdsOnLearningOutcomes,
      User => DataFixup::PopulateRootAccountIdsOnUsers,
    }.freeze
  end

  # table has `root_account_ids` column, not `root_account_id`
  # tables listed here should override the populate method above
  def self.multiple_root_account_ids_tables
    [
      CommunicationChannel,
      LearningOutcome,
      User
    ].freeze
  end

  # In case we run into other tables that can't fully finish being filled with
  # root account ids, and they have children who need them to consider them as full.
  def self.unfillable_criteria
    # Arguments to where()
    @unfillable_criteria ||= {
      DeveloperKey => "account_id IS NULL",
    }.transform_values { |criteria| [criteria].flatten(1) }.freeze
  end

  # A better alternative to the above, perhaps not possible in all cases, is to
  # actually fill it with a dummy root_account of "0". This unlocks
  # dependencies and simplifies our checking of what is done because the
  # unfillable row is actually filled with a value.
  # NOTE: also used in check_if_table_has_root_account() with where(root_account_id: nil)
  # to check if table is unfilled; be aware of potential performance problems on this check
  def self.fill_with_zeros_criteria
    # Arguments to where()
    @fill_with_zeros_criteria ||= {
      CalendarEvent => { context_type: "User", effective_context_code: nil },
      LearningOutcomeGroup => "context_id IS NULL",
      ContentMigration => { context_type: "User" },
    }.transform_values { |criteria| [criteria].flatten(1) }.freeze
  end

  # These must be simple associations or specific polymorphic associations ("course" not "context")
  # For non-=full table detection to work right, these should be associations already covered by
  # `migration_tables` or `dependencies`. See also scope_for_association_does_not_exist.
  # Multiple root account tables ("root_account_ids" not "root_account_id") not supported.
  def self.nonexistent_associations_to_fill_with_zeros
    @nonexistent_associations_to_fill_with_zeros ||= {
      CalendarEvent => %i[context_course context_group context_course_section],
    }
  end

  def self.ignore_cross_shard_associations_tables
    [
      ContentMigration, # there are a very small number cross-shard associations for some reason; we can ignore them
      Wiki, # complicated because it is a has_one instead of a belongs_to; really shouldn't have cross-shard associations anyway
    ]
  end

  # tables that have been filled for a while already
  DONE_TABLES = [Account, Assignment, Course, CourseSection, Enrollment, EnrollmentTerm, Group].freeze

  def self.send_later_backfill_strand(job, *args)
    delay_if_production(priority: Delayed::MAX_PRIORITY,
                        n_strand: ["root_account_id_backfill", Shard.current.database_server.id]).__send__(job, *args)
  end

  def self.run
    clean_and_filter_tables.each do |table, assoc|
      table.find_ids_in_ranges(batch_size: 100_000) do |min, max|
        # default populate method
        unless assoc.empty?
          send_later_backfill_strand(:populate_root_account_ids, table, assoc, min, max)
        end
        if fill_with_zeros_criteria.key?(table)
          send_later_backfill_strand(:fill_with_zeros, table, min, max)
        end
        if nonexistent_associations_to_fill_with_zeros.key?(table)
          send_later_backfill_strand(:fill_nonexistent_associations_with_zeros, table, min, max)
        end

        if populate_overrides.key?(table)
          # allow for one or more override methods of population
          Array(populate_overrides[table]).each do |override_module|
            next unless override_module.respond_to?(:populate)
            next if table.where(get_column_name(table) => nil).none?

            send_later_backfill_strand(:populate_root_account_ids_override, table, override_module, min, max)
          end
        end
      end

      next unless populate_overrides.key?(table)

      Array(populate_overrides[table]).each do |override_module|
        next unless override_module.respond_to?(:populate_table) &&
                    override_module.respond_to?(:run_populate_table?)
        next unless override_module.run_populate_table?

        send_later_backfill_strand(:populate_root_account_ids_override_table, table, override_module)
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
      (incomplete_tables << table) && next unless table.column_names.include?(get_column_name(table))
      next if (tables_in_progress + complete_tables + DONE_TABLES).include?(table)

      association_hash = hash_association(assoc)
      direct_relation_associations = replace_polymorphic_associations(table, association_hash)
      check_if_table_has_root_account(table, direct_relation_associations.keys) ? (complete_tables << table) && next : incomplete_tables << table

      all_dependencies = direct_relation_associations.keys + Array(dependencies[table])
      prereqs_ready = all_dependencies.all? do |a|
        assoc_reflection = table.reflections[a.to_s]
        class_name = assoc_reflection&.class_name&.constantize || a.to_s.classify.safe_constantize
        if (complete_tables + DONE_TABLES).include?(class_name)
          true
        elsif incomplete_tables.include?(class_name) || tables_in_progress.include?(class_name)
          false
        elsif table == CommunicationChannel
          # For single-sharded (OSS) Canvas, if any users have been filled in
          # and User jobs are complete, we are good to fill in comm channels
          User.where.not(root_account_ids: nil).any?
        else
          check_if_association_has_root_account(table, assoc_reflection) ? (complete_tables << table) && true : (incomplete_tables << table) && false
        end
      end
      memo[table] = direct_relation_associations if prereqs_ready
    end
  end

  def self.in_progress_tables
    Delayed::Job.where(strand: "root_account_id_backfill/#{Shard.current.database_server.id}",
                       shard_id: Shard.current).map do |job|
      job.payload_object&.args&.first
    end.uniq.compact
  end

  def self.hash_association(association)
    # we want a hash of tables with their associated column names
    case association
    when Hash
      association.transform_keys(&:to_sym)
    when Array
      association.reduce({}) { |memo, assoc| memo.merge(hash_association(assoc)) }
    when String, Symbol
      { association.to_sym => :root_account_id }
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
  # have a 0 root_account_id and will just use their id instead
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
          account_columns = Account.resolved_root_account_id_sql if poly_a == :account
          memo[:"#{prefix}#{poly_a}"] = account_columns || columns
        end
      else
        columns = Account.resolved_root_account_id_sql if assoc == :account
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
  def self.check_if_table_has_root_account(table, associations)
    return false if table.column_names.exclude?(get_column_name(table))
    return empty_root_account_column_scope(table).none? if associations.blank? || dependencies.key?(table)

    return false unless associations.all? do |a|
      reflection = table.reflections[a.to_s]
      scope = empty_root_account_column_scope(table)

      # when reflection is linked to `context`, it's polymorphic, so:
      # - get the polymorphic reflection (i.e. `context`, as opposed to `account`)
      # - limit the checking query to just this context type to prevent overlap
      # - limit by joining on the `through` association, if present
      poly_ref = find_polymorphic_reflection(table, reflection)
      if poly_ref
        scope = scope.where("#{poly_ref.foreign_type} = '#{reflection.class_name}'")
        scope = scope.joins(poly_ref.through_reflection.name) if poly_ref.through_reflection?
      end

      # further refine query based on association type
      if reflection.belongs_to? || reflection.through_reflection&.belongs_to?
        scope = scope.where("#{reflection.foreign_key} IS NOT NULL")
      elsif reflection.has_one?
        scope = scope.where(id: reflection.klass.select(reflection.foreign_key))
      end

      # are there any nil root account ids?
      scope.none?
    end

    # These rows can be filled with zeros. If they aren't filled, the table isn't filled
    if (zeros_criteria = fill_with_zeros_criteria[table]) &&
       empty_root_account_column_scope(table).where(*zeros_criteria).any?
      return false
    end

    true
  end

  # An association may have foreign keys for records on other shards, and to
  # backfill this table, we need to wait until the the foreign table has been
  # filled on all those shards.
  # For instance, `favorites` can have a `context_id` that is a course id from
  # another shard, so this checks to see if the `courses` tables on all shards
  # referenced by cross-shard `context_id`s have been backfilled.
  def self.check_if_association_has_root_account(table, assoc_reflection)
    class_name = assoc_reflection&.class_name&.constantize
    return true if assoc_reflection.nil?

    # find all cross-shard foreign keys for this association
    scope = table.where("#{assoc_reflection.foreign_key} > ?", Shard::IDS_PER_SHARD)

    # is this a polymorphic reflection like `context`? If so, limit the query
    # for shard ids to just the context type of this association
    poly_ref = find_polymorphic_reflection(table, assoc_reflection)
    scope = scope.where("#{poly_ref.foreign_type} = '#{assoc_reflection.class_name}'") if poly_ref

    shard_ids = [Shard.current.id, *scope.select("(#{assoc_reflection.foreign_key}/#{Shard::IDS_PER_SHARD}) as shard_id").distinct.map(&:shard_id)]

    # check associated table on all possible shards for any nil root account ids
    Shard.where(id: shard_ids).all? do |shard|
      shard.activate { empty_root_account_column_scope(class_name).none? }
    end
  end

  def self.empty_root_account_column_scope(table)
    if unfillable_criteria[table]
      table = table.where.not(*unfillable_criteria[table])
    end

    if multiple_root_account_ids_tables.include?(table)
      # takes care of nil and empty arrays
      table.where("ARRAY_LENGTH(#{table.quoted_table_name}.root_account_ids, 1) IS NULL")
    else
      table.where(root_account_id: nil)
    end
  end

  # some reflections are related to polymorphic reflections like `context`,
  # which can help limit queries to the context type.
  # this method finds a polymorphic reflection for the given reflection,
  # if there is one
  def self.find_polymorphic_reflection(table, reflection)
    table.reflections.values.find { |values| values.foreign_key == reflection.foreign_key && values.foreign_type }
  end

  def self.get_column_name(table)
    multiple_root_account_ids_tables.include?(table) ? "root_account_ids" : "root_account_id"
  end

  def self.populate_root_account_ids(table, associations, min, max)
    primary_key_field = table.primary_key
    table.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      associations.each do |assoc, columns|
        reflection = table.reflections[assoc.to_s]
        account_id_column = create_column_names(reflection, columns)
        scope = table.where(primary_key_field => batch_min..batch_max, :root_account_id => nil)
        scope.joins(assoc).update_all("root_account_id = #{account_id_column}")
        unless ignore_cross_shard_associations_tables.include?(table)
          fill_cross_shard_associations(table, scope, reflection, account_id_column)
        end
      end
    end

    unlock_next_backfill_job(table)
  end

  def self.fill_with_zeros(table, min, max)
    if (criteria = fill_with_zeros_criteria[table])
      table.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
        table
          .where(table.primary_key => batch_min..batch_max)
          .where(root_account_id: nil)
          .where(*criteria)
          .update_all("root_account_id = 0")
      end
    end
  end

  # Returns a scope for records in the table where the foreign record doesn't exist.
  # Assoc can be a simple association, or a specific polymorphic association
  # (e.g. "course" where "context" is a polymorphic association that includes
  # source). It cannot be a general polymorphic association ("context")
  def self.scope_for_association_does_not_exist(table, assoc)
    reflection = table.reflections[assoc.to_s]
    foreign_table = reflection.options[:class_name].constantize

    # Polymorphic associations: add scope, e.g. "context_type = Course":
    scope = reflection.scope ? table.class_eval(&reflection.scope) : table
    # cross-shard could actually exist so ignore:
    scope = scope.where("#{reflection.join_foreign_key} < #{Shard::IDS_PER_SHARD}")

    scope.where.not(foreign_table.where(
      "#{foreign_table.quoted_table_name}.#{reflection.join_primary_key}=#{table.quoted_table_name}.#{reflection.join_foreign_key}"
    ).arel.exists)
  end

  def self.fill_nonexistent_associations_with_zeros(table, min, max)
    assoc_names = nonexistent_associations_to_fill_with_zeros[table] or return
    return unless assoc_names

    table.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      assoc_names.each do |assoc_name|
        scope_for_association_does_not_exist(table, assoc_name)
          .where(id: batch_min..batch_max)
          .where(root_account_id: nil)
          .update_all("root_account_id = 0")
      end
    end
  end

  def self.populate_root_account_ids_override(table, override_module, min, max)
    override_module.populate(min, max)

    unlock_next_backfill_job(table)
  end

  def self.populate_root_account_ids_override_table(table, override_module)
    override_module.populate_table

    unlock_next_backfill_job(table)
  end

  def self.create_column_names(assoc, columns)
    return columns if columns.is_a?(String)

    names = Array(columns).map { |column| "#{assoc.klass.table_name}.#{column}" }
    (names.count == 1) ? names.first : "COALESCE(#{names.join(", ")})"
  end

  def self.fill_cross_shard_associations(table, scope, reflection, column)
    reflection = reflection.through_reflection if reflection.through_reflection?
    foreign_key = reflection.foreign_key

    # is this a polymorphic reflection like `context`? If so, limit the query
    # and updates to just the context type of this association
    poly_ref = find_polymorphic_reflection(table, reflection)
    scope = scope.where("#{poly_ref.foreign_type} = '#{reflection.class_name}'") if poly_ref

    min = scope.where("#{foreign_key} > ?", Shard::IDS_PER_SHARD).minimum(foreign_key)
    while min
      # one shard at a time
      foreign_shard = Shard.shard_for(min)
      if foreign_shard
        # scope for developer key ids within the current foreign_shard:
        subscope = scope.where("#{foreign_key} >= ? AND #{foreign_key} < ?", min, (foreign_shard.id + 1) * Shard::IDS_PER_SHARD)
        associated_ids = subscope.pluck(foreign_key)
        root_ids_with_foreign_keys = foreign_shard.activate do
          reflection.klass
                    .select("#{column} AS root_id, array_agg(#{reflection.table_name}.#{reflection.klass.primary_key}) AS foreign_keys")
                    .where(id: associated_ids)
                    .group("root_id")
        end
        root_ids_with_foreign_keys.each do |attributes|
          foreign_keys = attributes.foreign_keys.map { |fk| Shard.global_id_for(fk, foreign_shard) }
          subscope.where("#{foreign_key} IN (#{foreign_keys.join(",")})")
                  .update_all("root_account_id = #{Shard.global_id_for(attributes.root_id, foreign_shard) || "null"}")
        end
      end
      min = scope.where("#{foreign_key} > ?", ((min / Shard::IDS_PER_SHARD) + 1) * Shard::IDS_PER_SHARD).minimum(foreign_key)
    end
  end

  def self.unlock_next_backfill_job(table)
    # when the current table has been fully backfilled, restart the backfill job
    # so it can check to see if any new tables can begin working based off of this table
    if empty_root_account_column_scope(table).none?
      delay_if_production(priority: Delayed::LOWER_PRIORITY,
                          singleton: "root_account_id_backfill_strand_#{Shard.current.id}").run
    end
  end
end
