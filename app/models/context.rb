# frozen_string_literal: true

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
  CONTEXT_TYPES = %i[Account Course CourseSection User Group].freeze

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
      Rails.cache.delete(["short_name_lookup", asset_string].cache_key)
    end
  end

  def add_aggregate_entries(entries, feed)
    entries.each do |entry|
      user = entry.user || feed.user
      # If already existed and has been updated
      if entry.entry_changed? && entry.asset
        entry.asset.update(
          title: entry.title,
          message: entry.message
        )
      elsif !entry.asset
        announcement = announcements.build(
          title: entry.title,
          message: entry.message
        )
        announcement.external_feed_id = feed.id
        announcement.user = user
        announcement.save
        entry.update(asset: announcement)
      end
    end
  end

  def self.sorted_rubrics(context)
    associations = RubricAssociation.active.bookmarked.for_context_codes(context.asset_string).preload(rubric: :context)
    Canvas::ICU.collate_by(associations.to_a.uniq(&:rubric_id).select(&:rubric)) { |r| r.rubric.title || CanvasSort::Last }
  end

  def rubric_contexts(user)
    associations = []
    course_ids = [id]
    course_ids = (course_ids + user.participating_instructor_course_with_concluded_ids.map { |id| Shard.relative_id_for(id, user.shard, Shard.current) }).uniq if user
    Shard.partition_by_shard(course_ids) do |sharded_course_ids|
      context_codes = sharded_course_ids.map { |id| "course_#{id}" }
      if Shard.current == shard
        context = self
        while context.respond_to?(:account) || context.respond_to?(:parent_account)
          context = context.respond_to?(:account) ? context.account : context.parent_account
          context_codes << context.asset_string if context
        end
      end
      associations += RubricAssociation.active.bookmarked.for_context_codes(context_codes).include_rubric.preload(:context).to_a
    end

    associations = associations.select(&:rubric).uniq { |a| [a.rubric_id, a.context.asset_string] }
    contexts = associations.group_by { |a| a.context.asset_string }.map do |code, code_associations|
      {
        rubrics: code_associations.length,
        context_code: code,
        name: code_associations.first.context_name
      }
    end
    Canvas::ICU.collate_by(contexts) { |r| r[:name] }
  end

  def active_record_types(only_check: nil)
    only_check = only_check.sort if only_check.present? # so that we always have consistent cache keys
    @active_record_types ||= {}
    return @active_record_types[only_check] if @active_record_types[only_check]

    possible_types = {
      files: -> { respond_to?(:attachments) && attachments.active.exists? },
      modules: -> { respond_to?(:context_modules) && context_modules.active.exists? },
      quizzes: lambda do
                 (respond_to?(:quizzes) && quizzes.active.exists?) ||
                   (respond_to?(:assignments) && assignments.active.quiz_lti.exists?)
               end,
      assignments: -> { respond_to?(:assignments) && assignments.active.exists? },
      pages: -> { respond_to?(:wiki_pages) && wiki_pages.active.exists? },
      conferences: -> { respond_to?(:web_conferences) && web_conferences.active.exists? },
      announcements: -> { respond_to?(:announcements) && announcements.active.exists? },
      outcomes: -> { respond_to?(:has_outcomes?) && has_outcomes? },
      discussions: -> { respond_to?(:discussion_topics) && discussion_topics.only_discussion_topics.except(:preload).exists? }
    }

    types_to_check = if only_check
                       possible_types.select { |k| only_check.include?(k) }
                     else
                       possible_types
                     end

    raise ArgumentError, "only_check is either an empty array or you are aking for invalid types" if types_to_check.empty?

    base_cache_key = "active_record_types3"
    cache_key = [base_cache_key, only_check.presence || "everything", self].cache_key

    # if it exists in redis, return that
    if (cached = Rails.cache.read(cache_key))
      return @active_record_types[only_check] = cached
    end

    # if we're only asking for a subset but the full set is cached return that, but filtered with just what we want
    if only_check.present? && (cache_with_everything = Rails.cache.read([base_cache_key, "everything", self].cache_key))
      return @active_record_types[only_check] = cache_with_everything.select { |k, _v| only_check.include?(k) }
    end

    # otherwise compute it and store it in the cache
    value_to_cache = nil
    ActiveRecord::Base.uncached do
      value_to_cache = types_to_check.transform_values(&:call)
    end
    Rails.cache.write(cache_key, value_to_cache)
    @active_record_types[only_check] = value_to_cache
  end

  def allow_wiki_comments
    false
  end

  def find_asset(asset_string, allowed_types = nil)
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
      klass.where(id: ids).pluck(:id, :name).map { |id, name| result[[type, id]] = name }
    end
    result
  end

  def self.context_code_for(record)
    raise ArgumentError unless record.respond_to?(:context_type) && record.respond_to?(:context_id)

    "#{record.context_type.underscore}_#{record.context_id}"
  end

  def self.find_by_asset_string(string)
    ActiveRecord::Base.find_by_asset_string(string, CONTEXT_TYPES.map(&:to_s))
  end

  def self.find_all_by_asset_string(strings)
    ActiveRecord::Base.find_all_by_asset_string(strings, CONTEXT_TYPES.map(&:to_s))
  end

  def self.asset_type_for_string(string)
    ASSET_TYPES[string.to_sym].to_s.constantize if ASSET_TYPES.key?(string.to_sym)
  end

  def self.find_asset_by_asset_string(string, context = nil, allowed_types = nil)
    type, id = ActiveRecord::Base.parse_asset_string(string)
    klass = asset_type_for_string(type)
    klass = nil if allowed_types && !allowed_types.include?(klass.to_s.underscore.to_sym)
    return nil unless klass

    res = nil
    if context && klass == ContextExternalTool
      res = klass.find_external_tool_by_id(id, context)
    elsif context && (klass.column_names & ["context_id", "context_type"]).length == 2
      res = klass.where(context:, id:).first
    else
      res = klass.find_by(id:)
      res = nil if context && res.respond_to?(:context_id) && res.context_id != context.id
    end
    res
  rescue
    nil
  end

  def self.get_front_wiki_page_for_course_from_url(url)
    params = Rails.application.routes.recognize_path(url)
    if params[:controller] == "courses" && params[:action] == "show"
      course = Course.find(params[:id])
      if course.default_view == "wiki"
        course.wiki.front_page
      end
    end
  rescue
    nil
  end

  def self.find_asset_by_url(url)
    object = nil
    uri = URI.parse(url)
    params = Rails.application.routes.recognize_path(uri.path)
    course = Course.find(params[:course_id]) if params[:course_id]
    group = Group.find(params[:group_id]) if params[:group_id]
    user = User.find(params[:user_id]) if params[:user_id]
    context = course || group || user

    return nil unless context || params[:controller] == "media_objects"

    case params[:controller]
    when "files"
      rel_path = params[:file_path]
      object = rel_path && Folder.find_attachment_in_context_with_path(course, CGI.unescape(rel_path))
      file_id = params[:file_id] || params[:id]
      file_id ||= uri.query && CGI.parse(uri.query).send(:[], "preview")&.first
      object ||= context.attachments.find_by(id: file_id) # attachments.find_by(id:) uses the replacement hackery
      full_path = params[:full_path]
      folder = full_path && Folder.find_by(name: full_path)
      object ||= folder if folder && folder.context == context
    when "wiki_pages"
      object = context.wiki.find_page(CGI.unescape(params[:id]), include_deleted: true)
      if !object && params[:id].to_s.include?("+") # maybe it really is a "+"
        object = context.wiki.find_page(CGI.unescape(params[:id].to_s.gsub("+", "%2B")), include_deleted: true)
      end
    when "external_tools"
      if params[:action] == "retrieve"
        query_params = CGI.parse(uri.query)
        tool_url = query_params["url"]&.first
        resource_link_lookup_uuid = query_params["resource_link_lookup_uuid"]&.first
        object = if tool_url
                   ContextExternalTool.find_external_tool(tool_url, context)
                 elsif resource_link_lookup_uuid
                   Lti::ResourceLink.where(
                     lookup_uuid: resource_link_lookup_uuid,
                     context:
                   ).active.take&.current_external_tool(context)
                 end
      elsif params[:id]
        object = ContextExternalTool.find_external_tool_by_id(params[:id], context)
      end
    when "context_modules"
      object = if %w[item_redirect item_redirect_mastery_paths choose_mastery_path].include?(params[:action])
                 context.context_module_tags.find_by(id: params[:id])
               else
                 context.context_modules.find_by(id: params[:id])
               end
    when "media_objects"
      object = if params[:media_object_id]
                 MediaObject.where(media_id: params[:media_object_id]).first
               elsif params[:attachment_id]
                 # get possibly replaced attachment, see app/models/attachment.rb find_attachment_possibly_replaced
                 Attachment.find_by(id: params[:attachment_id])&.context&.attachments&.find_by(id: params[:attachment_id])
               end
    when "context"
      object = context.users.find(params[:id]) if params[:action] == "roster_user" && params[:id]
    else
      object = context.try(params[:controller].sub(%r{^.+/}, ""))&.find_by(id: params[:id])
    end
    object
  rescue
    nil
  end

  def self.api_type_name(klass)
    case klass.to_s
    when "Announcement"
      "announcements"
    when "Attachment"
      "files"
    when "ContextModule"
      "modules"
    when "ContentTag"
      "module_items"
    when "WikiPage"
      "pages"
    else
      klass.table_name
    end
  end

  def self.asset_name(asset)
    name = asset.display_name.presence if asset.respond_to?(:display_name)
    name ||= asset.title.presence if asset.respond_to?(:title)
    name ||= asset.short_description.presence if asset.respond_to?(:short_description)
    name ||= asset.name if asset.respond_to?(:name)
    name ||= asset.asset_name if asset.respond_to?(:asset_name)
    name || ""
  end

  def self.asset_body(asset)
    asset.try(:body) || asset.try(:message) || asset.try(:description)
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

  def self.get_account_or_parent_account_global_id(context)
    case context
    when Account
      context.root_account? ? context.global_id : context.global_parent_account_id
    when Course
      context.global_account_id
    when CourseSection
      get_account_or_parent_account_global_id(context.course)
    when Group
      get_account_or_parent_account_global_id(context.context)
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

  def nickname_for(_user, fallback = :name, prefer_friendly_name: true)
    send fallback if fallback
  end

  def self.last_updated_at(klasses_to_ids)
    scopes = []

    klasses_to_ids.each do |(klass, ids)|
      next if ids.empty?

      scopes << klass
                .shard(Shard.current) # prevent it switching shards on us
                .where(id: ids)
                .order(updated_at: :desc)
                .select(:updated_at)
                .limit(1)
    end

    return nil if scopes.empty?

    final_scope = scopes.first if scopes.length == 1
    final_scope ||= scopes.first.union(*scopes[1..], from: true)
    final_scope.order(updated_at: :desc).limit(1).pluck(:updated_at)&.first
  end

  def resolved_root_account_id
    root_account_id if respond_to? :root_account_id
  end
end
