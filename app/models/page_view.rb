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
  self.primary_key = 'request_id'

  belongs_to :developer_key
  belongs_to :user
  belongs_to :account
  belongs_to :real_user, :class_name => 'User'
  belongs_to :asset_user_access

  before_save :ensure_account
  before_save :cap_interaction_seconds
  belongs_to :context, polymorphic: [:course, :account, :group, :user, :user_profile], polymorphic_prefix: true

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
      p.http_method = request.request_method.downcase
      p.controller = request.path_parameters[:controller]
      p.action = request.path_parameters[:action]
      p.session_id = request.session_options[:id].to_s.force_encoding(Encoding::UTF_8).presence
      p.user_agent = request.user_agent
      p.remote_ip = request.remote_ip
      p.interaction_seconds = 5
      p.created_at = Time.now
      p.updated_at = Time.now
      p.id = RequestContextGenerator.request_id
      p.export_columns.each do |c|
        v = p.send(c)
        if !v.nil? && v.respond_to?(:force_encoding)
          p.send("#{c}=", v.force_encoding(Encoding::UTF_8))
        end
      end
    end
  end

  def self.find_for_update(request_id)
    if PageView.updates_enabled? && (self.db? || self.cassandra?)
      begin
        # not using find_by_id or where(..).first because the cassandra
        # codepath doesn't support it
        find(request_id)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    else
      new { |p| p.request_id = request_id }
    end
  end

  def token
    Canvas::Security.create_jwt({
      i: request_id,
      u: Shard.global_id_for(user_id),
      c: created_at.try(:utc).try(:iso8601, 2)
    })
  end

  def self.decode_token(token)
    data = Canvas::Security.decode_jwt(token)
    return nil unless data
    return {
      request_id: data[:i],
      user_id: data[:u],
      created_at: data[:c]
    }
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
  EXPORTED_COLUMNS = %w(request_id user_id url context_id context_type asset_id asset_type controller action interaction_seconds created_at user_request render_time user_agent participated account_id real_user_id http_method remote_ip)

  def self.page_views_enabled?
    !!page_view_method
  end

  def self.page_view_method
    enable_page_views = Setting.get('enable_page_views', 'false')
    return false if enable_page_views == 'false'
    enable_page_views = 'db' if %w[true cache].include?(enable_page_views) # backwards compat
    enable_page_views.to_sym
  end

  after_initialize :initialize_shard

  def initialize_shard
    # remember the page view method selected at the time of creation, so that
    # we use the right method when saving
    if PageView.cassandra? && new_record?
      self.shard = Shard.birth
    end
  end

  def self.db?
    self.page_view_method == :db
  end

  def self.cassandra?
    page_view_method == :cassandra
  end

  def self.pv4?
    page_view_method == :pv4 || Setting.get('read_from_pv4', 'false') == 'true'
  end

  def self.global_storage_namespace?
    cassandra? || pv4?
  end

  EventStream = EventStream::Stream.new do
    database -> { Canvas::Cassandra::DatabaseBuilder.from_config(:page_views) }
    table :page_views
    id_column :request_id
    record_type PageView
    read_consistency_level -> { Canvas::Cassandra::DatabaseBuilder.read_consistency_setting(:page_views) }

    add_index :user do
      table :page_views_history_by_context
      id_column :request_id
      key_column :context_and_time_bucket
      scrollback_limit -> { Setting.get('page_views_scrollback_limit:users', 52.weeks) }

      # index by the page view's user, but use the user's global_asset_string
      # when writing the index
      entry_proc lambda{ |page_view| page_view.user }
      key_proc lambda{ |user| user.global_asset_string }
    end

    self.raise_on_error = Rails.env.test?

    on_error do |operation, record, exception|
      Canvas::EventStreamLogger.error('PAGEVIEW', identifier, operation, record.to_json, exception.message.to_s)
    end
  end

  def self.find(ids)
    return super unless PageView.cassandra?

    case ids
    when Array
      result = PageView::EventStream.fetch(ids)
      raise ActiveRecord::RecordNotFound, "Couldn't find all PageViews with IDs (#{ids.join(',')}) (found #{result.length} results, but was looking for #{ids.length})" unless ids.length == result.length
      result
    else
      find([ids]).first
    end
  end

  def self.find_all_by_id(ids)
    if PageView.cassandra?
      PageView::EventStream.fetch(ids)
    elsif PageView.pv4?
      []
    else
      where(request_id: ids).to_a
    end
  end

  def self.find_by_id(id)
    if PageView.cassandra?
      PageView::EventStream.fetch([id]).first
    elsif PageView.pv4?
      nil
    else
      where(request_id: id).first
    end
  end

  def self.from_attributes(attrs, new_record=false)
    @blank_template ||= columns.inject({}) { |h,c| h[c.name] = nil; h }
    attrs = attrs.slice(*@blank_template.keys)
    shard = PageView.global_storage_namespace? ? Shard.birth : Shard.current
    page_view = shard.activate do
      if new_record
        new{ |pv| pv.assign_attributes(attrs, :without_protection => true) }
      else
        instantiate(@blank_template.merge(attrs))
      end
    end
    page_view
  end

  def self.updates_enabled?
    Setting.get('skip_pageview_updates', 'false') != 'true'
  end

  def store
    self.created_at ||= Time.zone.now
    return false unless user
    return false if self.is_update && !PageView.updates_enabled?

    result = case PageView.page_view_method
    when :log
      Rails.logger.info "PAGE VIEW: #{self.attributes.to_json}"
    when :db, :cassandra
      self.save
    end

    self.store_page_view_to_user_counts

    result
  end

  def do_update(params = {})
    # nothing currently in the block is shard-sensitive, but to prevent
    # accidents in the future, we'll add the correct shard activation now
    shard = PageView.db? ? Shard.current : Shard.default
    shard.activate do
      updated_at = params['updated_at'] || self.updated_at || Time.now
      updated_at = Time.parse(updated_at) if updated_at.is_a?(String)
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

  def _create_record(*args)
    return super unless PageView.cassandra?
    self.created_at ||= Time.zone.now
    user.shard.activate do
      run_callbacks(:create) do
        PageView::EventStream.insert(self)
        @new_record = false
        self.id
      end
    end
  end

  def _update_record(*args)
    return super unless PageView.cassandra?
    user.shard.activate do
      run_callbacks(:update) do
        PageView::EventStream.update(self)
        true
      end
    end
  end

  scope :for_context, proc { |ctx| where(:context_type => ctx.class.name, :context_id => ctx) }
  scope :for_users, lambda { |users| where(:user_id => users) }

  def self.pv4_client
    @pv4_client ||= begin
      config = ConfigFile.load('pv4')
      raise "Page Views v4 not configured!" unless config
      Pv4Client.new(config['uri'], config['access_token'])
    end
  end

  def self.reset_pv4_client
    @pv4_client = nil
  end

  Canvas::Reloader.on_reload do
    reset_pv4_client
  end

  # returns a collection with very limited functionality
  # basically, it responds to #paginate and returns a
  # WillPaginate::Collection-like object
  def self.for_user(user, options={})
    user.shard.activate do
      if PageView.pv4?
        pv4_client.for_user(user.global_id, **options)
      elsif PageView.cassandra?
        PageView::EventStream.for_user(user, options)
      else
        scope = self.where(:user_id => user).order('created_at desc')
        scope = scope.where("created_at >= ?", options[:oldest]) if options[:oldest]
        scope = scope.where("created_at <= ?", options[:newest]) if options[:newest]
        scope
      end
    end
  end

  class << self
    def transaction_with_cassandra_check(*args)
      if PageView.cassandra?
        # Rails 3 autosave associations re-assign the attributes;
        # for sharding to work, the page view's shard has to be
        # active at that point, but it's not cause it's normally
        # done by the transaction, which we're skipping. so
        # manually do that here
        if current_scope
          current_scope.activate do
            yield
          end
        else
          yield
        end
      else
        self.transaction_without_cassandra_check(*args) { yield }
      end
    end
    alias_method_chain :transaction, :cassandra_check
  end

  def add_to_transaction
    super unless PageView.cassandra?
  end

  def self.user_count_bucket_for_time(time)
    utc = time.in_time_zone('UTC')
    # round down to the last 5 minute mark -- so 03:43:28 turns into 03:40:00
    utc = utc - ((utc.min % 5) * 60) - utc.sec
    "active_users:#{utc.as_json}"
  end

  # this is not intended to be called often; only from console as a debugging measure
  def self.active_user_counts_by_shard(time = Time.now)
    members = Set.new
    time = time..time unless time.is_a?(Range)
    bucket_time = time.begin
    while (time.cover?(bucket_time))
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
    return unless Setting.get('page_views_store_active_user_counts', 'false') == 'redis' && Canvas.redis_enabled?
    return unless self.created_at.present? && self.user.present?
    exptime = Setting.get('page_views_active_user_exptime', 1.day.to_s).to_i
    bucket = PageView.user_count_bucket_for_time(self.created_at)
    Canvas.redis.sadd(bucket, self.user.global_id)
    Canvas.redis.expire(bucket, exptime)
  end

  # to_csv uses these methods, see lib/ext/array.rb
  def export_columns(format = nil)
    PageView::EXPORTED_COLUMNS
  end

  def to_row(format = nil)
    export_columns(format).map { |c| self.send(c).presence }
  end

  def app_name
    DeveloperKey.find_cached(developer_key_id).try(:name) if developer_key_id
  end

  # utility class to migrate a postgresql/sqlite3 page_views table to cassandra
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
      rows = PageView.connection.select_all(finder_sql).to_a

      return false if rows.empty?

      inserted = rows.count do |attrs|
        begin
          created_at = attrs['created_at']
          created_at = Time.zone.parse(created_at) unless created_at.is_a?(Time)
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
      last_created_at = Time.zone.parse(last_created_at) unless last_created_at.is_a?(Time)
      cassandra.execute("UPDATE page_views_migration_metadata_per_account SET last_created_at = ? WHERE shard_id = ? AND account_id = ?", last_created_at, Shard.current.id.to_s, account_id)
      data['last_created_at'] = last_created_at
      return inserted > 0
    end

    def cassandra
      PageView::EventStream.database
    end

    def run
      while run_once
      end
    end
  end
end
