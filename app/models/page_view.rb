#
# Copyright (C) 2012 Instructure, Inc.
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
  set_primary_key 'request_id'

  belongs_to :developer_key
  belongs_to :user
  belongs_to :account
  belongs_to :real_user, :class_name => 'User'
  belongs_to :asset_user_access

  before_save :ensure_account
  before_save :cap_interaction_seconds
  belongs_to :context, :polymorphic => true

  def initialize_with_shard_assignment(*a, &b)
    initialize_without_shard_assignment(*a, &b)
    if self.class.cassandra?
      self.shard = Shard.default
    end
  end
  alias_method_chain :initialize, :shard_assignment

  attr_accessor :generated_by_hand
  attr_accessor :is_update

  attr_accessible :url, :user, :controller, :action, :session_id, :developer_key, :user_agent, :real_user, :context

  def ensure_account
    self.account_id ||= (self.context_type == 'Account' ? self.context_id : self.context.account_id) rescue nil
    self.account_id ||= (self.context.is_a?(Account) ? self.context : self.context.account) if self.context
  end

  def cap_interaction_seconds
    self.interaction_seconds = [self.interaction_seconds || 5, 10.minutes.to_i].min
  end

  # the list of columns we display to users, export to csv, etc
  EXPORTED_COLUMNS = %w(request_id user_id url context_id context_type asset_id asset_type controller action contributed interaction_seconds created_at user_request render_time user_agent participated account_id real_user_id)

  def self.page_views_enabled?
    !!page_view_method
  end

  def self.page_view_method
    enable_page_views = Shard.current.settings[:page_view_method] || Setting.get_cached('enable_page_views', 'false')
    return false if enable_page_views == 'false'
    enable_page_views = 'db' if enable_page_views == 'true' # backwards compat
    enable_page_views.to_sym
  end

  def self.redis_queue?
    %w(cache cassandra).include?(page_view_method.to_s)
  end

  def self.cassandra?
    %w(cassandra).include?(page_view_method.to_s)
  end

  def self.cassandra
    @cassandra ||= Canvas::Cassandra::Database.from_config('page_views')
  end
  def cassandra
    self.class.cassandra
  end

  def self.find_one(id, options)
    return super unless cassandra?
    find_some([id], options).first || raise(ActiveRecord::RecordNotFound, "Couldn't find PageView with ID=#{id}")
  end

  def self.find_some(ids, options)
    return super unless cassandra?
    raise(NotImplementedError, "options not implemented: #{options.inspect}") if options.present?
    pvs = []
    cassandra.execute("SELECT * FROM page_views WHERE request_id IN (?)", ids).fetch do |row|
      pvs << from_cassandra(row)
    end
    pvs
  end

  def self.find_every(options)
    return super unless cassandra?
    raise(NotImplementedError, "find_every not implemented")
  end

  def self.from_cassandra(attrs)
    @blank_template ||= columns.inject({}) { |h,c| h[c.name] = nil; h }
    Shard.default.activate { instantiate(@blank_template.merge(attrs)) }
  end

  def store
    self.created_at ||= Time.zone.now

    result = case PageView.page_view_method
    when :log
      Rails.logger.info "PAGE VIEW: #{self.attributes.to_json}"
    when :cache, :cassandra
      json = self.attributes.as_json
      json['is_update'] = true if self.is_update
      Canvas.redis.rpush(PageView.cache_queue_name, json.to_json)
    when :db
      self.save
    end

    self.store_page_view_to_user_counts

    result
  end

  def do_update(params = {})
    updated_at = params['updated_at'] || self.updated_at || Time.now
    updated_at = Time.parse(updated_at) if updated_at.is_a?(String)
    self.contributed ||= params['page_view_contributed'] || params['contributed']
    seconds = self.interaction_seconds || 0
    if params['interaction_seconds'].to_i > 0
      seconds += params['interaction_seconds'].to_i
    else
      seconds += [5, (Time.now - updated_at)].min
      seconds = [seconds, Time.now - created_at].min if created_at
    end
    self.updated_at = Time.now
    self.interaction_seconds = seconds
    self.is_update = true
  end

  def create_without_callbacks
    return super unless self.class.cassandra?
    self.created_at ||= Time.zone.now
    update
    if user
      cassandra.execute("INSERT INTO page_views_history_by_context (context_and_time_bucket, ordered_id, request_id) VALUES (?, ?, ?)", "#{user.global_asset_string}/#{PageView.timeline_bucket_for_time(created_at, "User")}", "#{created_at.to_i}/#{request_id[0,8]}", request_id)
    end
    @new_record = false
    self.id
  end

  def update_without_callbacks
    return super unless self.class.cassandra?
    cassandra.update_record("page_views", { :request_id => request_id }, self.changes)
    true
  end

  named_scope :for_context, proc { |ctx| { :conditions => { :context_type => ctx.class.name, :context_id => ctx.id } } }
  named_scope :for_users, proc { |users| { :conditions => { :user_id => users.map(&:id) } } }

  # returns a collection with very limited functionality
  # basically, it responds to #paginate and returns a
  # WillPaginate::Collection-like object
  def self.for_user(user)
    if cassandra?
      PaginatedCollection.build { |pager| page_view_history(user, pager) }
    else
      self.scoped(:conditions => { :user_id => user.id }, :order => 'created_at desc')
    end
  end

  def self.page_view_history(context, pager)
    context_type = context.class.name
    context_id = context.global_id
    scrollback_limit = Setting.get('page_views_scrollback_limit:users', 52.weeks.to_s).to_i.ago
    results = []

    if pager.current_page.to_s =~ %r{^(\d+):(\d+/\w+)$}
      row_ts = $1.to_i
      start_column = $2
    else
      # page 1
      row_ts = PageView.timeline_bucket_for_time(Time.now, context_type)
    end

    until pager.next_page || Time.at(row_ts) < scrollback_limit
      limit = pager.per_page + 1 - results.size
      args = []
      args << "#{context_type.underscore}_#{context_id}/#{row_ts}"
      if start_column
        ordered_id = "AND ordered_id <= ?"
        args << start_column
      else
        ordered_id = nil
      end
      qs = "SELECT ordered_id, request_id FROM page_views_history_by_context where context_and_time_bucket = ? #{ordered_id} ORDER BY ordered_id DESC LIMIT #{limit}"
      PageView.cassandra.execute(qs, *args).fetch do |row|
        if results.size == pager.per_page
          pager.next_page = "#{row_ts}:#{row['ordered_id']}"
        else
          results << row['request_id']
        end
      end

      start_column = nil
      # possible optimization: query page_views_counters_by_context_and_day ,
      # and use it as a secondary index to skip days where the user didn't
      # have any page views
      row_ts -= PageView.timeline_bucket_size(context_type)
    end

    pager.replace(PageView.find(results).sort_by { |pv| results.index(pv.request_id) })
  end

  def self.cache_queue_name
    'page_view_queue'
  end

  def self.process_cache_queue
    redis = Canvas.redis
    lock_key = 'page_view_queue_processing'
    lock_key += ":#{Shard.current.id}" unless Shard.current.default?
    lock_time = Setting.get("page_view_queue_lock_time", 15.minutes.to_s).to_i

    # lock other processors out until we're done. if more than lock_time
    # passes, the lock will be dropped and we'll assume this processor died.
    unless redis.setnx lock_key, 1
      return
    end
    redis.expire lock_key, lock_time

    begin
      # process as many items as were in the queue when we started.
      todo = redis.llen(self.cache_queue_name)
      while todo > 0
        batch_size = [Setting.get_cached('page_view_queue_batch_size', '1000').to_i, todo].min
        redis.expire lock_key, lock_time
        transaction do
          process_cache_queue_batch(batch_size, redis)
        end
        todo -= batch_size
      end
    ensure
      redis.del lock_key
    end
  end

  def self.process_cache_queue_batch(batch_size, redis = Canvas.redis)
    batch_size.times do
      json = redis.lpop(self.cache_queue_name)
      break unless json
      attrs = JSON.parse(json)
      self.process_cache_queue_item(attrs)
    end
  end

  def self.process_cache_queue_item(attrs)
    return if attrs['is_update'] && Setting.get_cached('skip_pageview_updates', nil) == "true"
    self.transaction(:requires_new => true) do
      if attrs['is_update']
        page_view = self.find_some([attrs['request_id']], {}).first
        return unless page_view
        page_view.do_update(attrs)
        page_view.save
      else
        # bypass mass assignment protection
        self.create { |p| p.send(:attributes=, attrs, false) }
      end
    end
  rescue ActiveRecord::StatementInvalid => e
  end

  def self.timeline_bucket_for_time(time, context_type)
    time.to_i - (time.to_i % timeline_bucket_size(context_type))
  end

  def self.timeline_bucket_size(context_type)
    case context_type
    when "User"
      1.week.to_i
    else
      raise "don't know bucket size for context type: #{context_type}"
    end
  end

  def self.user_count_bucket_for_time(time)
    utc = time.in_time_zone('UTC')
    # round down to the last 5 minute mark -- so 03:43:28 turns into 03:40:00
    utc = utc - ((utc.min % 5) * 60) - utc.sec
    "active_users:#{utc.as_json}"
  end

  def store_page_view_to_user_counts
    return unless Setting.get_cached('page_views_store_active_user_counts', 'false') == 'redis' && Canvas.redis_enabled?
    return unless self.created_at.present? && self.user.present?
    exptime = Setting.get_cached('page_views_active_user_exptime', 1.day.to_s).to_i
    bucket = PageView.user_count_bucket_for_time(self.created_at)
    Canvas.redis.sadd(bucket, self.user.global_id)
    Canvas.redis.expire(bucket, exptime)
  end

  # to_csv uses these methods, see lib/ext/array.rb
  def export_columns(format = nil)
    PageView::EXPORTED_COLUMNS
  end
  def to_row(format = nil)
    export_columns(format).map { |c| self.send(c) }
  end

  # utility class to migrate a postgresql/mysql/sqlite3 page_views table to cassandra
  class CassandraMigrator < Struct.new(:cutoff, :last_created_at, :last_request_id, :scope, :logger)
    def initialize(skip_deleted_accounts = true, cutoff = nil)
      self.cutoff = cutoff || 52.weeks.ago
      # summarized is either true or null for all page views, depending on plugin functionality
      self.logger = Rails.logger

      summarized = (Setting.get("page_views_migration_summarized", "false") == "true") || nil
      self.scope = PageView.scoped(:conditions => { :summarized => summarized },
                                   :order => 'created_at DESC, request_id ASC')
      if skip_deleted_accounts
        deleted_account_ids = Set.new(Account.root_accounts.all(:conditions => { :workflow_state => 'deleted' }).map(&:id))
        self.scope = self.scope.scoped(:conditions => ["account_id NOT IN (?)", deleted_account_ids])
      end
    end

    def run_once(batch_size = 1000)
      raise("Must configure page views to use cassandra first") if !PageView.cassandra?

      unless self.last_created_at
        self.last_created_at, self.last_request_id = PageView.cassandra.execute("SELECT last_created_at, last_request_id FROM page_views_migration_metadata WHERE shard_id = ?", Shard.current.id.to_s).fetch.try(:to_hash).try(:values_at, 'last_created_at', 'last_request_id')
        self.last_created_at = self.last_created_at.try(:in_time_zone)
        self.last_created_at ||= Time.zone.now
        self.last_request_id ||= ''
      end

      finder_sql = scope.scoped(:limit => batch_size,
                                :conditions => ["(created_at < ? OR (created_at = ? AND request_id > ?)) AND created_at > ?", last_created_at, last_created_at, last_request_id, cutoff]).construct_finder_sql({})
      # query just the raw attributes, don't instantiate AR objects
      rows = PageView.connection.execute(finder_sql).to_a

      return false if rows.empty?

      inserted = rows.count do |attrs|
        begin
          # now instantiate the AR object here, as a brand new record, so
          # it's saved to cassandra as if it was just created (though
          # created_at comes from the queried db attributes)
          # we're bypassing the redis queue here, just saving directly to cassandra
          PageView.create! { |pv| pv.send(:attributes=, attrs, false) }
          true
        rescue
          logger.error "failed migrating request id to cassandra: #{attrs['request_id']} : #{$!}"
          false
        end
      end

      logger.info "added #{inserted} page views starting at #{last_created_at} #{last_request_id}"

      self.last_created_at, self.last_request_id = rows.last.values_at('created_at', 'request_id')
      self.last_created_at = Time.zone.parse(last_created_at)
      PageView.cassandra.execute("UPDATE page_views_migration_metadata SET last_created_at = ?, last_request_id = ? WHERE shard_id = ?", last_created_at, last_request_id, Shard.current.id.to_s)
      true
    end

    def run
      while run_once
      end
    end
  end
end
