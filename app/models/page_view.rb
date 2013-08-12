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

  attr_accessor :generated_by_hand
  attr_accessor :is_update

  attr_accessible :url, :user, :controller, :action, :session_id, :developer_key, :user_agent, :real_user, :context

  # note that currently we never query page views from the perspective of the course;
  # we simply don't record them for non-logged-in users in a public course
  # if we ever do either of the above, we'll need to remove this, and figure out
  # where such page views should belong (currently page views end up on the user's
  # shard)
  validates_presence_of :user_id

  def self.generate(request, attributes={})
    self.new(attributes).tap do |p|
      p.url = LoggingFilter.filter_uri(request.url)[0,255]
      p.http_method = request.method.to_s
      p.controller = request.path_parameters['controller']
      p.action = request.path_parameters['action']
      p.session_id = request.session_options[:id]
      p.user_agent = request.headers['User-Agent']
      p.interaction_seconds = 5
      p.created_at = Time.now
      p.updated_at = Time.now
      p.id = RequestContextGenerator.request_id
    end
  end

  def self.for_request_id(request_id)
    if PageView.page_view_method == :db
      find_by_request_id(request_id)
    else
      new{ |p| p.request_id = request_id }
    end
  end

  def url
    url = read_attribute(:url)
    url && LoggingFilter.filter_uri(url)
  end

  def ensure_account
    self.account_id ||= (self.context_type == 'Account' ? self.context_id : self.context.account_id) rescue nil
    self.account_id ||= (self.context.is_a?(Account) ? self.context : self.context.account) if self.context
  end

  def cap_interaction_seconds
    self.interaction_seconds = [self.interaction_seconds || 5, 10.minutes.to_i].min
  end

  # the list of columns we display to users, export to csv, etc
  EXPORTED_COLUMNS = %w(request_id user_id url context_id context_type asset_id asset_type controller action contributed interaction_seconds created_at user_request render_time user_agent participated account_id real_user_id http_method)

  def self.page_views_enabled?
    !!page_view_method
  end

  def self.page_view_method
    enable_page_views = Setting.get_cached('enable_page_views', 'false')
    return false if enable_page_views == 'false'
    enable_page_views = 'db' if enable_page_views == 'true' # backwards compat
    enable_page_views.to_sym
  end

  def after_initialize
    # remember the page view method selected at the time of creation, so that
    # we use the right method when saving
    if PageView.cassandra? && new_record?
      self.shard = Shard.birth
    end
  end

  def self.redis_queue?
    %w(cache cassandra).include?(page_view_method.to_s)
  end

  def self.cassandra?
    self.page_view_method == :cassandra
  end

  EventStream = ::EventStream.new do
    database_name :page_views
    table :page_views
    id_column :request_id
    record_type PageView

    add_index :user do
      table :page_views_history_by_context
      id_column :request_id
      key_column :context_and_time_bucket
      scrollback_setting 'page_views_scrollback_limit:users'

      # index by the page view's user, but use the user's global_asset_string
      # when writing the index
      entry_proc lambda{ |page_view| page_view.user }
      key_proc lambda{ |user| user.global_asset_string }
    end
  end

  def self.find_one(id, options)
    return super unless PageView.cassandra?
    find_some([id], options).first || raise(ActiveRecord::RecordNotFound, "Couldn't find PageView with ID=#{id}")
  end

  def self.find_some(ids, options)
    return super unless PageView.cassandra?
    raise(NotImplementedError, "options not implemented: #{options.inspect}") if options.present?
    PageView::EventStream.fetch(ids)
  end

  def self.find_every(options)
    return super unless PageView.cassandra?
    raise(NotImplementedError, "find_every not implemented")
  end

  def self.from_attributes(attrs, new_record=false)
    @blank_template ||= columns.inject({}) { |h,c| h[c.name] = nil; h }
    shard = PageView.cassandra? ? Shard.birth : Shard.current
    page_view = shard.activate do
      if new_record
        new{ |pv| pv.send(:attributes=, attrs, false) }
      else
        instantiate(@blank_template.merge(attrs))
      end
    end
    page_view
  end

  def store
    self.created_at ||= Time.zone.now
    return false unless user

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
    # nothing currently in the block is shard-sensitive, but to prevent
    # accidents in the future, we'll add the correct shard activation now
    shard = PageView.cassandra? ? Shard.default : Shard.current
    shard.activate do
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
  end

  def create_without_callbacks
    user.shard.activate do
      return super unless PageView.cassandra?
      self.created_at ||= Time.zone.now
      PageView::EventStream.insert(self)
      @new_record = false
      self.id
    end
  end

  def update_without_callbacks
    user.shard.activate do
      return super unless PageView.cassandra?
      PageView::EventStream.update(self)
      true
    end
  end

  scope :for_context, proc { |ctx| where(:context_type => ctx.class.name, :context_id => ctx) }
  scope :for_users, lambda { |users| where(:user_id => users) }

  # returns a collection with very limited functionality
  # basically, it responds to #paginate and returns a
  # WillPaginate::Collection-like object
  def self.for_user(user, options={})
    user.shard.activate do
      if PageView.cassandra?
        PageView::EventStream.for_user(user, options)
      else
        scope = self.where(:user_id => user).order('created_at desc')
        scope = scope.where("created_at >= ?", options[:oldest]) if options[:oldest]
        scope = scope.where("created_at <= ?", options[:newest]) if options[:newest]
        scope
      end
    end
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
        self.transaction do
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
      else
        page_view = self.from_attributes(attrs, true)
      end
      page_view.save
    end
  rescue ActiveRecord::StatementInvalid => e
    logger.error "[CRIT] Failed to record page view!"
    logger.error "#{e.class}: #{e.message}"
    e.backtrace.each{ |line| logger.error "\tfrom #{line}" }
  end

  class << self
    def transaction_with_cassandra_check(*args)
      if PageView.cassandra?
        yield
      else
        self.transaction_without_cassandra_check(*args) { yield }
      end
    end
    alias_method_chain :transaction, :cassandra_check
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
  class CassandraMigrator < Struct.new(:start_at, :logger, :migration_data)
    # if you interrupt and re-start the migrator, start_at cannot be changed,
    # since it's saved in cassandra to persist the migration state
    def initialize(skip_deleted_accounts = true, start_at = nil)
      self.start_at = start_at || 52.weeks.ago
      self.logger = Rails.logger

      if skip_deleted_accounts
        account_ids = Set.new(Account.root_accounts.active.pluck(:id))
      else
        account_ids = Set.new(Account.root_accounts.pluck(:id))
      end

      load_migration_data(account_ids)
    end

    def load_migration_data(account_ids)
      self.migration_data = {}
      account_ids.each do |account_id|
        data = self.migration_data[account_id] = {}
        data.merge!(cassandra.execute("SELECT last_created_at FROM page_views_migration_metadata_per_account WHERE shard_id = ? AND account_id = ?", Shard.current.id.to_s, account_id).fetch.try(:to_hash) || {})

        if !(data['last_created_at'])
          data['last_created_at'] = self.start_at
        end
        # cassandra returns Time not TimeWithZone objects
        data['last_created_at'] = data['last_created_at'].in_time_zone
      end
    end

    # this is the batch size per account, not the overall batch size
    # returns true if any progress was made (if it makes sense to run_once again)
    def run_once(batch_size = 3000)
      self.migration_data.inject(false) do |progress, (account_id,_)|
        run_once_for_account(account_id, batch_size) || progress
      end
    end

    def run_once_for_account(account_id, batch_size)
      data = self.migration_data[account_id]
      raise("not configured for account id: #{account_id}") unless data

      last_created_at = data['last_created_at']

      # this could run into problems if one account gets more than
      # batch_size page views created in the second on this boundary
      finder_sql = PageView.where("account_id = ? AND created_at >= ?", account_id, last_created_at).
          order("created_at asc").limit(batch_size).to_sql

      # query just the raw attributes, don't instantiate AR objects
      rows = PageView.connection.execute(finder_sql).to_a

      return false if rows.empty?

      inserted = rows.count do |attrs|
        begin
          created_at = Time.zone.parse(attrs['created_at'])
          # if the created_at is the same as the last_created_at,
          # we may have already inserted this page view
          # use to_i here to avoid sub-second precision problems
          if created_at.to_i == last_created_at.to_i
            exists = !!cassandra.select_value("SELECT request_id FROM page_views WHERE request_id = ?", attrs['request_id'])
          end

          # now instantiate the AR object here, as a brand new record, so
          # it's saved to cassandra as if it was just created (though
          # created_at comes from the queried db attributes)
          # we're bypassing the redis queue here, just saving directly to cassandra
          if exists
            false
          else
            # assumes PageView.cassandra? is true at this point
            page_view = PageView.from_attributes(attrs, true)
            page_view.save!
            true
          end
        rescue
          logger.error "failed migrating request id to cassandra: #{attrs['request_id']} : #{$!}"
          false
        end
      end

      logger.info "account #{Shard.current.id}~#{account_id}: added #{inserted} page views starting at #{last_created_at}"

      last_created_at = rows.last['created_at']
      last_created_at = Time.zone.parse(last_created_at)
      cassandra.execute("UPDATE page_views_migration_metadata_per_account SET last_created_at = ? WHERE shard_id = ? AND account_id = ?", last_created_at, Shard.current.id.to_s, account_id)
      data['last_created_at'] = last_created_at
      return inserted > 0
    end

    def cassandra
      user.shard.activate do
        PageView::EventStream.database
      end
    end

    def run
      while run_once
      end
    end
  end
end
