#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

# These methods are mixed into the classes that can be considered a "context".
# See Context::CONTEXT_TYPES below.
module Context

  CONTEXT_TYPES = [:Account, :Course, :User, :Group].freeze

  ASSET_TYPES = {
      Announcement: :Announcement,
      AssessmentQuestion: :AssessmentQuestion,
      AssessmentQuestionBank: :AssessmentQuestionBank,
      Assignment: :Assignment,
      AssignmentGroup: :AssignmentGroup,
      Attachment: :Attachment,
      CalendarEvent: :CalendarEvent,
      Collaboration: :Collaboration,
      ContentTag: :ContentTag,
      ContextExternalTool: :ContextExternalTool,
      ContextModule: :ContextModule,
      DiscussionEntry: :DiscussionEntry,
      DiscussionTopic: :DiscussionTopic,
      Folder: :Folder,
      LearningOutcome: :LearningOutcome,
      LearningOutcomeGroup: :LearningOutcomeGroup,
      MediaObject: :MediaObject,
      Progress: :Progress,
      Quiz: :"Quizzes::Quiz",
      QuizGroup: :"Quizzes::QuizGroup",
      QuizQuestion: :"Quizzes::QuizQuestion",
      QuizSubmission: :"Quizzes::QuizSubmission",
      Rubric: :Rubric,
      RubricAssociation: :RubricAssociation,
      Submission: :Submission,
      WebConference: :WebConference,
      Wiki: :Wiki,
      WikiPage: :WikiPage,
      Eportfolio: :Eportfolio
  }.freeze

  def clear_cached_short_name
    self.class.connection.after_transaction_commit do
      Rails.cache.delete(['short_name_lookup', self.asset_string].cache_key)
    end
  end

  def add_aggregate_entries(entries, feed)
    entries.each do |entry|
      user = entry.user || feed.user
      # If already existed and has been updated
      if entry.entry_changed? && entry.asset
        entry.asset.update_attributes(
          :title => entry.title,
          :message => entry.message
        )
      elsif !entry.asset
        announcement = self.announcements.build(
          :title => entry.title,
          :message => entry.message
        )
        announcement.external_feed_id = feed.id
        announcement.user = user
        announcement.save
        entry.update_attributes(:asset => announcement)
      end
    end
  end

  def self.sorted_rubrics(user, context)
    associations = RubricAssociation.bookmarked.for_context_codes(context.asset_string).preload(:rubric => :context)
    Canvas::ICU.collate_by(associations.to_a.uniq(&:rubric_id).select{|r| r.rubric }) { |r| r.rubric.title || CanvasSort::Last }
  end

  def rubric_contexts(user)
    associations = []
    course_ids = [self.id]
    course_ids = (course_ids + user.participating_instructor_course_ids.map{|id| Shard.relative_id_for(id, user.shard, Shard.current)}).uniq if user
    Shard.partition_by_shard(course_ids) do |sharded_course_ids|
      context_codes = sharded_course_ids.map{|id| "course_#{id}"}
      if Shard.current == self.shard
        context = self
        while context && context.respond_to?(:account) || context.respond_to?(:parent_account)
          context = context.respond_to?(:account) ? context.account : context.parent_account
          context_codes << context.asset_string if context
        end
      end
      associations += RubricAssociation.bookmarked.for_context_codes(context_codes).include_rubric.preload(:context).to_a
    end

    associations = associations.select(&:rubric).uniq{|a| [a.rubric_id, a.context.asset_string] }
    contexts = associations.group_by{|a| a.context.asset_string}.map do |code, code_associations|
      {
        :rubrics => code_associations.length,
        :context_code => code,
        :name => code_associations.first.context_name
      }
    end
    Canvas::ICU.collate_by(contexts) { |r| r[:name] }
  end

  def active_record_types(only_check: nil)
    only_check = only_check.sort if only_check.present? # so that we always have consistent cache keys
    @active_record_types ||= {}
    return @active_record_types[only_check] if @active_record_types[only_check]

    possible_types = {
      files: -> { self.respond_to?(:attachments) && self.attachments.active.exists? },
      modules: -> { self.respond_to?(:context_modules) && self.context_modules.active.exists? },
      quizzes: -> { self.respond_to?(:quizzes) && self.quizzes.active.exists? },
      assignments: -> { self.respond_to?(:assignments) && self.assignments.active.exists? },
      pages: -> { self.respond_to?(:wiki_pages) && self.wiki_pages.active.exists? },
      conferences: -> { self.respond_to?(:web_conferences) && self.web_conferences.active.exists? },
      announcements: -> { self.respond_to?(:announcements) && self.announcements.active.exists? },
      outcomes: -> { self.respond_to?(:has_outcomes?) && self.has_outcomes? },
      discussions: -> { self.respond_to?(:discussion_topics) && self.discussion_topics.only_discussion_topics.except(:preload).exists? }
    }

    types_to_check = if only_check
      possible_types.select { |k| only_check.include?(k) }
    else
      possible_types
    end

    raise ArgumentError, "only_check is either an empty array or you are aking for invalid types" if types_to_check.empty?

    base_cache_key = 'active_record_types3'
    cache_key = [base_cache_key, (only_check.present? ? only_check : 'everything'), self].cache_key

    # if it exists in redis, return that
    if (cached = Rails.cache.read(cache_key))
      return @active_record_types[only_check] = cached
    end

    # if we're only asking for a subset but the full set is cached return that, but filtered with just what we want
    if only_check.present? && (cache_with_everything = Rails.cache.read([base_cache_key, 'everything', self].cache_key))
      return @active_record_types[only_check] = cache_with_everything.select { |k,_v| only_check.include?(k) }
    end

    # otherwise compute it and store it in the cache
    value_to_cache = nil
    ActiveRecord::Base.uncached do
      value_to_cache = types_to_check.each_with_object({}) do |(key, type_to_check), memo|
        memo[key] = type_to_check.call
      end
    end
    Rails.cache.write(cache_key, value_to_cache)
    @active_record_types[only_check] = value_to_cache
  end

  def allow_wiki_comments
    false
  end

  def find_asset(asset_string, allowed_types=nil)
    return nil unless asset_string
    res = Context.find_asset_by_asset_string(asset_string, self, allowed_types)
    res = nil if res.respond_to?(:deleted?) && res.deleted?
    res
  end

  # [[context_type, context_id], ...] -> {[context_type, context_id] => name, ...}
  def self.names_by_context_types_and_ids(context_types_and_ids)
    ids_by_type = Hash.new([])
    context_types_and_ids.each do |type, id|
      next unless type && CONTEXT_TYPES.include?(type.to_sym)
      ids_by_type[type] += [id]
    end

    result = {}
    ids_by_type.each do |type, ids|
      klass = Object.const_get(type, false)
      klass.where(:id => ids).pluck(:id, :name).map {|id, name| result[[type, id]] = name}
    end
    result
  end

  def self.context_code_for(record)
    raise ArgumentError unless record.respond_to?(:context_type) && record.respond_to?(:context_id)
    "#{record.context_type.underscore}_#{record.context_id}"
  end

  def self.find_by_asset_string(string)
    from_context_codes([string]).first
  end

  def self.from_context_codes(context_codes)
    contexts = {}
    context_codes.each do |cc|
      type, _, id = cc.rpartition('_')
      if CONTEXT_TYPES.include?(type.camelize.to_sym)
        contexts[type.camelize] = [] unless contexts[type.camelize]
        contexts[type.camelize] << id
      end
    end
    contexts.reduce([]) do |memo, (context, ids)|
      memo + context.constantize.where(id: ids)
    end
  end

  def self.asset_type_for_string(string)
    ASSET_TYPES[string.to_sym].to_s.constantize if ASSET_TYPES.key?(string.to_sym)
  end

  def self.find_asset_by_asset_string(string, context=nil, allowed_types=nil)
    opts = string.split("_")
    id = opts.pop
    type = opts.join('_').classify
    klass = asset_type_for_string(type)
    klass = nil if allowed_types && !allowed_types.include?(klass.to_s.underscore.to_sym)
    return nil unless klass
    res = nil
    if context && klass == ContextExternalTool
      res = klass.find_external_tool_by_id(id, context)
    elsif context && (klass.column_names & ['context_id', 'context_type']).length == 2
      res = klass.where(context_id: context, context_type: context.class.to_s, id: id).first
    else
      res = klass.where(id: id).first
      res = nil if context && res && res.respond_to?(:context) && res.context != context
    end
    res
  rescue => e
    nil
  end

  def self.asset_name(asset)
    name = asset.display_name.presence if asset.respond_to?(:display_name)
    name ||= asset.title.presence if asset.respond_to?(:title)
    name ||= asset.short_description.presence if asset.respond_to?(:short_description)
    name ||= asset.name if asset.respond_to?(:name)
    name || ''
  end

  def self.get_account(context)
    case context
    when Account
      context
    when Course
      get_account(context.account)
    when CourseSection
      get_account(context.course)
    when Group
      get_account(context.context)
    end
  end

  def is_a_context?
    true
  end

  def concluded?
    false
  end

  # Public: Boolean flag re: whether a feature is enabled
  # provides defaults for objects that do not include FeatureFlags
  # (note: include Context _before_ FeatureFlags)
  #
  # Returns false
  def feature_enabled?(_feature)
    false
  end

  def nickname_for(_user, fallback = :name)
    self.send fallback if fallback
  end

  def self.last_updated_at(klass, ids)
    raise ArgumentError unless CONTEXT_TYPES.include?(klass.class_name.to_sym)
    klass.where(id: ids)
         .where.not(updated_at: nil)
         .order("updated_at DESC")
         .limit(1)
         .pluck(:updated_at)&.first
  end
end
