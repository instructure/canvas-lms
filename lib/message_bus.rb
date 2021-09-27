# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

##
# MessageBus is really a wrapper for interacting with
# an Apache Pulsar cluster.  Most of the actual
# integration with pulsar protocols is (and should be!)
# in the client gem, "pulsar-client", and this is really the
# glue that uses normal canvas-lms channels for reading and caching
# config, and then uses that to bootstrap a pulsar client.
#
# As much as possible this class strives not to PROXY the pulsar-client
# so much as it tries to remove any guesswork from initializing it.
#
# Every canvas usage of the message bus should be within the same
# pulsar "tenant" ( https://pulsar.apache.org/docs/en/concepts-multi-tenancy/ )
# so the tenant will be loaded from the application config and does not need
# to be managed by the clients of this library.
#
# Each "area" of the codebase that uses the MessageBus should use it's
# own "namespace" ( https://pulsar.apache.org/docs/en/concepts-messaging/#namespaces )
# which is really just a known string that topics can be grouped under.
# They must be created in advance on the pulsar cluster, and they share
# things like data retention policies.
#
# The topic name you choose for a given use case can be generated because
# they're created lazily.  For very large canvas operating environments
# you may want to use some kind of partitioning key as part of the topic name
# like the shard id or event account id.
module MessageBus
  mattr_accessor :logger, :on_work_unit_end
  mattr_reader :max_mem_queue_size_lambda, :worker_process_interval_lambda

  ##
  # MessageBus has an in-memory queueing feature
  # to prevent writes the could be async from taking
  # up request/response time when writing to a struggling
  # pulsar instance.  Use a lambda for this attribute to
  # make it so this library can use whatever config
  # access path you want to read the max size out of.
  #
  # Expected return value from the lambda is an integer.
  # If the queue grows to this size, further attempts
  # to push messages will exhibit backpressure
  # by throwing errors.
  #
  # you would generally set this in a rails initializer
  def self.max_mem_queue_size=(size_lambda)
    @max_mem_queue_size_lambda = size_lambda
  end

  def self.max_mem_queue_size
    @max_mem_queue_size_lambda.call
  end

  ##
  # MessageBus has an in-memory queueing feature
  # to prevent writes the could be async from taking
  # up request/response time when writing to a struggling
  # pulsar instance.  Use a lambda for this attribute to
  # make it so this library can use whatever config
  # access path you want to read the max size out of.
  #
  # Expected return value from the lambda is an integer.
  # The asynchronous producer worker will sleep
  # for this many seconds in between publication runs.
  #
  # you would generally set this in a rails initializer
  def self.worker_process_interval=(interval_lambda)
    @worker_process_interval_lambda = interval_lambda
  end

  def self.worker_process_interval
    @worker_process_interval_lambda.call
  end

  ##
  # Use this when you want to write messages to a topic.
  # The returned object is a pulsar-client producer
  # ( https://github.com/instructure/pulsar-client-ruby#usage )
  # and will respond to the "send" method accepting a payload to
  # transmit.
  #
  # "namespace" should be an underscore delimited string.  Don't
  # use slashes, it will be confusing for constructing the entire
  # topic url.  A good example of a valid namespace might be "asset_user_access_log".
  # You don't need tons of these, and they should have been created in pulsar
  # already as part of your pulsar state management. Namespaces are NOT created lazily
  # so if you try to send a namespace that doesn't exist yet, it will error.
  #
  # "topic_name" is also a string without slashes.  Conventionally you'll want some kind of
  # prefix for the TYPE of topic this is, and some kind of partition key as the suffix.
  # An example might be "#{PULSAR_TOPIC_PREFIX}-#{root_account.uuid}" from the AUA subsystem
  # which evaluates to something like "view-increments-2yQwasdfm3dcNeoasdf4PYy9sgsasdf3qzasdf".
  # by using a partition key, you can make sure messages are being bucketed according to
  # how they're going to be processed which means one topic doesn't have to handle all messages
  # of a given type.  Topics are lazily created on pulsar, you don't have to do any
  # other work to make sure they're instantiated ahead of time.
  # Don't worry about prepending an environment like "production-" if you've seen that
  # before, that's taken care of internally in this library by reading the environment state.
  #
  # "force_fresh:", if you pass true, will make sure we authenticate
  # and build a new producer rather than using a process-cached one,
  # even if such a producer is available.
  #
  # WARNING: If you're using a long-lived producer directly, be aware
  # of the timeout issue that's being handled in the "send_one_message"
  # method below.  Rarely, operational changes on the pulsar side can put
  # producers into a state where they repeatedly timeout.  You may need to
  # catch that error and rebuild your producer from a fresh client if/when
  # that happens.
  def self.producer_for(namespace, topic_name, force_fresh: false)
    ns = MessageBus::Namespace.build(namespace)
    check_conn_pool(["producers", ns.to_s, topic_name], force_fresh: force_fresh) do
      Bundler.require(:pulsar)
      ::MessageBus::CaCert.ensure_presence!(self.config)
      topic = self.topic_url(ns, topic_name)
      self.client.create_producer(topic)
    end
  end

  ##
  # send_one_message is a convenience method for when you aren't trying
  # to standup a client and stream many messages through, but just
  # need to dispatch ONE THING.  If you don't care too much about strict ordering
  # (because the in-memory queue used may put messages that error on transmission
  #  back at the end if the FIFO queue) you can use this helper to have most
  # retries taken care of for you.
  #
  # If strict ordering is important, you are probably better off using ".producer_for"
  # and handling the error cases yourself for now.
  #
  # "namespace" and "topic_name" are exactly like their counterparts
  # documented in the ".producer_for" method, and are passed through
  # to that method.
  #
  # "message" should be a string object, often serialized json
  # will be the preferred structure.  This method performs no transformation on the
  # message for you, so if you have a hash and want to send it as json,
  # transform it to json before passing it as the message to this
  # method.
  def self.send_one_message(namespace, topic_name, message)
    production_worker.push(namespace, topic_name, message)
  end

  ##
  # Use consumer_for when you want to read messages from a topic.
  # The returned object is a pulsar-client consumer
  # ( https://github.com/instructure/pulsar-client-ruby#usage )
  # and will respond to the "receive" method to pulling messages
  #
  # "force_fresh:", if you pass true, will make sure we authenticate
  # and build a new consumer rather than using a process-cached one,
  # even if such a consumer is available.
  def self.consumer_for(namespace, topic_name, subscription_name, force_fresh: false)
    ns = MessageBus::Namespace.build(namespace)
    check_conn_pool(["consumers", ns.to_s, topic_name, subscription_name], force_fresh: force_fresh) do
      Bundler.require(:pulsar)
      ::MessageBus::CaCert.ensure_presence!(self.config)
      topic = topic_url(ns, topic_name)
      consumer_config = Pulsar::ConsumerConfiguration.new({})
      consumer_config.subscription_initial_position = :earliest
      self.client.subscribe(topic, subscription_name, consumer_config)
    end
  end

  def self.topic_url(namespace, topic_name, app_env = Canvas.environment)
    ns = MessageBus::Namespace.build(namespace)
    app_env = (app_env || "development").downcase
    conf_hash = self.config
    # by using the application env in the topic name, we can
    # share a non-prod pulsar instance between environments
    # like test/beta/edge whatever and not have to provision
    # other overhead to separate them or deal with the confusion of shared
    # data in a single topic.
    "persistent://#{conf_hash['PULSAR_TENANT']}/#{ns}/#{app_env}-#{topic_name}"
  end

  ##
  # an in memory data structure that should look like:
  #
  # {
  #  'thread_id' => {
  #   'producers' => {
  #     'namespace_1' => {
  #       'topic_1' => producer_obj_A,
  #       'topic_2' => producer_obj_B,
  #     },
  #     'namespace_2' => {
  #       'topic_3' => producer_obj_C,
  #       'topic_4' => producer_obj_D,
  #     }
  #   },
  #   'consumers' => {
  #     'namespace_1' => {
  #       'topic_1' => {
  #         'subscription_1' => consumer_obj_A,
  #         'subscription_2' => consumer_obj_B,
  #       },
  #       'topic_2' => {
  #         'subscription_3' => consumer_obj_C,
  #         'subscription_4' => consumer_obj_D,
  #       },
  #     },
  #     'namespace_2' => {
  #       'topic_3' => {
  #         'subscription_5' => consumer_obj_E,
  #         'subscription_6' => consumer_obj_F,
  #       },
  #       'topic_4' => {
  #         'subscription_7' => consumer_obj_G,
  #         'subscription_8' => consumer_obj_H,
  #       },
  #     }
  #   },
  #  }
  # }
  #
  # This means we can re-use connections rather than
  # building a new producer for each request to canvas,
  # etc.
  #
  # The "path" is expected to be an Array of all the keys
  # describing where the target object is going to be stored.
  # e.g. ["producers", "namespace_5", "subscription_2"]
  def self.check_conn_pool(path, force_fresh: false)
    # make sure if we ever go multi-threaded
    # that you can't wipe out the entire caching
    # data structure while we're actively traversing it.
    connection_mutex.synchronize do
      @connection_pool ||= {}
      # each thread gets it's own producers/consumers
      thread_path = [Thread.current.object_id] + path
      cached_object = @connection_pool.dig(*thread_path)
      if cached_object
        return cached_object unless force_fresh

        # if we're forcing fresh, we want to close our existing
        # connections as politely as possible
        begin
          cached_object.close()
        rescue ::Pulsar::Error::AlreadyClosed
          Rails.logger.warn("evicting an already-closed pulsar topic client for #{path}")
        end
      end
      object_to_cache = yield
      current_level = @connection_pool
      thread_path.each_with_index do |key, i|
        if i == (thread_path.size - 1)
          # last key in the path, this is where we cache
          # the actual built object
          current_level[key] = object_to_cache
        else
          current_level[key] ||= {}
          current_level = current_level[key]
        end
      end
      return object_to_cache
    end
  end

  def self.client
    return @client if @client

    Bundler.require(:pulsar)
    conf_hash = self.config
    token_vault_path = conf_hash['PULSAR_TOKEN_VAULT_PATH']
    if token_vault_path.present?
      conf_hash = conf_hash.dup
      # the canvas vault lib does some caching internally,
      # so we can just re-look this up each time.
      conf_hash['PULSAR_AUTH_TOKEN'] = Canvas::Vault.read(token_vault_path)[:data][:default]
    else
      Rails.logger.info "[MESSAGE_BUS] No token path found in config, assuming we have a non-auth pulsar cluster here."
    end
    client_config = Pulsar::ClientConfiguration.from_environment({}, conf_hash)
    broker_uri = conf_hash['PULSAR_BROKER_URI']
    @client = Pulsar::Client.new(broker_uri, client_config)
  end

  def self.enabled?
    hash = self.config
    hash['PULSAR_BROKER_URI'].present? && hash['PULSAR_TENANT'].present?
  end

  def self.config(shard = ::Switchman::Shard.current)
    cluster_id = shard.database_server.id
    settings = DynamicSettings.find(tree: :private, cluster: cluster_id)
    loaded_settings = (settings['pulsar.yml'] || '{}')
    current_hash_code = loaded_settings.hash
    @config_cache ||= {}
    # let's not re-parse the yaml on every config reference unless it's actually changed
    # for this particular cluster
    if @config_cache.key?(cluster_id) && @config_cache[cluster_id][:hash_code] == current_hash_code
      return @config_cache[cluster_id][:parsed_config]
    end

    parsed = YAML.safe_load(loaded_settings)
    @config_cache[cluster_id] = {
      hash_code: current_hash_code,
      parsed_config: parsed
    }
    parsed
  end

  def self.reset!
    connection_mutex.synchronize do
      close_and_reset_cached_connections!
      flush_message_bus_client!
    end
  end

  def self.process_all_and_reset!
    production_worker.stop!
    @production_worker = nil
    @launched_pid = nil
    reset!
  end

  # Internal: worker object (in a thread) for
  # sending out message that are written to the message bus
  # with the `send_one_message` method.
  def self.production_worker
    if !@launched_pid || @launched_pid != Process.pid
      if @launched_pid
        logger.warn "Starting new MessageBus worker thread due to fork."
      end

      @production_worker = MessageBus::AsyncProducer.new
      @launched_pid = Process.pid
    end
    @production_worker
  end

  def self.rescuable_pulsar_errors
    [
      ::Pulsar::Error::AlreadyClosed,
      ::Pulsar::Error::BrokerPersistenceError,
      ::Pulsar::Error::ConnectError,
      ::Pulsar::Error::ServiceUnitNotReady,
      ::Pulsar::Error::Timeout
    ]
  end

  ##
  # Internal: drop all instance variable state for talking to pulsar.
  # This appears to be useful to get over the hump when a maintenance event
  # redistributes brokers among hosts in the pulsar cluster.
  # Only should be invoked within a successfully obtained connection mutex, which is
  # why it's private and only invoked by the ".reset!" method.
  def self.flush_message_bus_client!
    begin
      @client&.close()
    rescue ::Pulsar::Error::AlreadyClosed
      # we need to make sure the client actually gets cleared out if the close fails,
      # otherwise we'll keep trying to use it
      Rails.logger.warn("while resetting, closing client was found to already be closed")
    end
    @client = nil
    @config_cache = nil
  end
  private_class_method :flush_message_bus_client!

  ##
  # Internal: closes all producers and consumers in the process pool.
  # This should only be called within a successfully obtained connection mutex, which is
  # why it's private and only invoked by the ".reset!" method.
  def self.close_and_reset_cached_connections!
    return if @connection_pool.blank?

    @connection_pool.each do |_thread_id, thread_conn_pool|
      if thread_conn_pool['producers'].present?
        thread_conn_pool['producers'].each do |_namespace, topic_map|
          topic_map.each do |topic, producer|
            producer.close()
          rescue Pulsar::Error::AlreadyClosed
            Rails.logger.warn("while resetting, closing an already-closed pulsar producer for #{topic}")
          end
        end
      end

      next unless thread_conn_pool['consumers'].present?

      thread_conn_pool['consumers'].each do |_namespace, topic_map|
        topic_map.each do |topic, subscription_map|
          subscription_map.each do |sub_name, consumer|
            consumer.close()
          rescue Pulsar::Error::AlreadyClosed
            Rails.logger.warn("while resetting, closing an already-closed pulsar subscription (#{sub_name}) to #{topic}")
          end
        end
      end
    end
    @connection_pool = nil
  end
  private_class_method :close_and_reset_cached_connections!

  def self.connection_mutex
    @connection_mutex ||= Mutex.new
  end
  private_class_method :connection_mutex
end
