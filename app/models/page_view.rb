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

class PageView < ActiveRecord::Base
  self.primary_key = "request_id"

  belongs_to :developer_key
  belongs_to :user
  belongs_to :account
  belongs_to :real_user, class_name: "User"
  belongs_to :asset_user_access

  before_save :ensure_account
  before_save :cap_interaction_seconds
  belongs_to :context, polymorphic: %i[course account group user user_profile], polymorphic_prefix: true

  CONTEXT_TYPES = %w[Course Account Group User UserProfile].freeze

  attr_accessor :is_update

  # NOTE: currently we never query page views from the perspective of the course;
  # we simply don't record them for non-logged-in users in a public course
  # if we ever do either of the above, we'll need to remove this, and figure out
  # where such page views should belong (currently page views end up on the user's
  # shard)
  validates :user_id, presence: true

  def self.generate(request, attributes = {})
    new(attributes).tap do |p|
      p.url = LoggingFilter.filter_uri(request.url)[0, 255]
      p.http_method = request.request_method.downcase
      p.controller = request.path_parameters[:controller]
      p.action = request.path_parameters[:action]
      p.session_id = request.session_options[:id].to_s.dup.force_encoding(Encoding::UTF_8).presence
      p.user_agent = request.user_agent
      p.remote_ip = request.remote_ip
      p.interaction_seconds = 5
      p.created_at = Time.now
      p.updated_at = Time.now
      p.id = RequestContext::Generator.request_id
      p.export_columns.each do |c|
        v = p.send(c)
        if !v.nil? && v.respond_to?(:force_encoding)
          p.send(:"#{c}=", v.force_encoding(Encoding::UTF_8))
        end
      end
    end
  end

  def self.find_for_update(request_id)
    if PageView.updates_enabled? && db?
      find_by(id: request_id)
    else
      new { |p| p.request_id = request_id }
    end
  end

  def token
    CanvasSecurity::PageViewJwt.generate({
                                           request_id:,
                                           user_id: Shard.global_id_for(user_id),
                                           created_at:
                                         })
  end

  def url
    url = read_attribute(:url)
    url && LoggingFilter.filter_uri(url)
  end

  def ensure_account
    self.account_id ||= ((context_type == "Account") ? context_id : context.account_id) rescue nil
    self.account_id ||= (context.is_a?(Account) ? context : context.account) if context
  end

  def cap_interaction_seconds
    self.interaction_seconds = [interaction_seconds || 5, 10.minutes.to_i].min
  end

  # the list of columns we display to users, export to csv, etc
  EXPORTED_COLUMNS = %w[request_id user_id url context_id context_type asset_id asset_type controller action interaction_seconds created_at user_request render_time user_agent participated account_id real_user_id http_method remote_ip].freeze

  def self.page_views_enabled?
    !!page_view_method
  end

  def self.page_view_method
    enable_page_views = Setting.get("enable_page_views", "false")
    return false if enable_page_views == "false"

    enable_page_views = "db" if %w[true cache].include?(enable_page_views) # backwards compat
    enable_page_views.to_sym
  end

  def self.db?
    page_view_method == :db
  end

  def self.cassandra?
    page_view_method == :cassandra
  end

  def self.pv4?
    page_view_method == :pv4 || Setting.get("read_from_pv4", "false") == "true"
  end

  def self.global_storage_namespace?
    cassandra? || pv4?
  end

  def self.find_all_by_id(ids)
    if PageView.pv4?
      []
    else
      where(request_id: ids).to_a
    end
  end

  def self.find_by(id:)
    if PageView.pv4?
      nil
    else
      super(request_id: id)
    end
  end

  def self.from_attributes(attrs, new_record = false)
    @blank_template ||= columns.each_with_object({}) do |c, h|
      h[c.name] = nil
    end
    attrs = attrs.slice(*@blank_template.keys)
    shard = PageView.global_storage_namespace? ? Shard.birth : Shard.current
    shard.activate do
      if new_record
        new { |pv| pv.assign_attributes(attrs) }
      else
        instantiate(@blank_template.merge(attrs))
      end
    end
  end

  def self.updates_enabled?
    Setting.get("skip_pageview_updates", "false") != "true"
  end

  def store
    self.created_at ||= Time.zone.now
    return false unless user
    return false if is_update && !PageView.updates_enabled?

    result = case PageView.page_view_method
             when :log
               Rails.logger.info "PAGE VIEW: #{attributes.to_json}"
             when :db
               self.shard = user.shard if new_record?
               save
             end

    store_page_view_to_user_counts

    result
  end

  def do_update(params = {})
    # nothing currently in the block is shard-sensitive, but to prevent
    # accidents in the future, we'll add the correct shard activation now
    shard = PageView.db? ? Shard.current : Shard.default
    shard.activate do
      updated_at = params["updated_at"] || self.updated_at || Time.now
      updated_at = Time.parse(updated_at) if updated_at.is_a?(String)
      seconds = interaction_seconds || 0
      if params["interaction_seconds"].to_i > 0
        seconds += params["interaction_seconds"].to_i
      else
        seconds += [5, (Time.now - updated_at)].min
        seconds = [seconds, Time.now - created_at].min if created_at
      end
      self.updated_at = Time.now
      self.interaction_seconds = seconds
      self.is_update = true
    end
  end

  scope :for_context, ->(ctx) { where(context_type: ctx.class.name, context_id: ctx) }
  scope :for_users, ->(users) { where(user_id: users) }

  def self.pv4_client
    ConfigFile.cache_object("pv4") do |config|
      creds = Rails.application.credentials.pv4_creds

      Pv4Client.new(config["uri"], creds&.dig(Rails.env.to_sym, :access_token))
    end
  end

  # returns a collection with very limited functionality
  # basically, it responds to #paginate and returns a
  # WillPaginate::Collection-like object
  def self.for_user(user, options = {})
    viewer = options.delete(:viewer)
    viewer = nil if viewer == user
    viewer = nil if viewer && Account.site_admin.grants_any_right?(viewer, :view_statistics, :manage_students)
    user.shard.activate do
      if PageView.pv4?
        result = pv4_client.for_user(user.global_id, **options)
        result = AccountFilter.filter(result, viewer) if viewer
        result
      else
        scope = where(user_id: user).order("created_at desc")
        scope = scope.where(created_at: options[:oldest]..) if options[:oldest]
        scope = scope.where(created_at: ..options[:newest]) if options[:newest]
        if viewer
          accounts = user.associated_accounts.shard(user).select { |a| a.grants_any_right?(viewer, :view_statistics, :manage_students) }
          accounts << nil
          scope = scope.where(account_id: accounts)
        end
        scope
      end
    end
  end

  def self.user_count_bucket_for_time(time)
    utc = time.in_time_zone("UTC")
    # round down to the last 5 minute mark -- so 03:43:28 turns into 03:40:00
    utc = utc - ((utc.min % 5) * 60) - utc.sec
    "active_users:#{utc.as_json}"
  end

  # this is not intended to be called often; only from console as a debugging measure
  def self.active_user_counts_by_shard(time = Time.now)
    members = Set.new
    time = time..time unless time.is_a?(Range)
    bucket_time = time.begin
    while time.cover?(bucket_time)
      bucket = user_count_bucket_for_time(bucket_time)
      members.merge(Canvas.redis.smembers(bucket))
      bucket_time += 5.minutes
    end

    result = {}
    members.each do |uid|
      shard = Shard.shard_for(uid)
      next unless shard

      result[shard.id] ||= 0
      result[shard.id] += 1
    end
    result
  end

  def store_page_view_to_user_counts
    return unless Setting.get("page_views_store_active_user_counts", "false") == "redis" && Canvas.redis_enabled?
    return unless self.created_at.present? && user.present?

    exptime = Setting.get("page_views_active_user_exptime", 1.day.to_s).to_i
    bucket = PageView.user_count_bucket_for_time(self.created_at)
    Canvas.redis.pipelined(bucket, failsafe: nil) do |pipeline|
      pipeline.sadd(bucket, user.global_id)
      pipeline.expire(bucket, exptime)
    end
  end

  # to_csv uses these methods, see lib/ext/array.rb
  def export_columns
    PageView::EXPORTED_COLUMNS
  end

  def to_row
    export_columns.map { |c| send(c).presence }
  end

  def app_name
    DeveloperKey.find_cached(developer_key_id).try(:name) if developer_key_id
  end
end
