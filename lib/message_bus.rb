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

  ##
  # Use this when you want to write messages to a topic.
  # The returned object is a pulsar-client producer
  # ( https://github.com/instructure/pulsar-client-ruby#usage )
  # and will respond to the "send" method accepting a payload to
  # transmit.
  #
  # "force_fresh:", if you pass true, will make sure we authenticate
  # and build a new producer rather than using a process-cached one,
  # even if such a producer is available.
  def self.producer_for(namespace, topic_name, force_fresh: false)
    check_conn_pool(["producers", namespace, topic_name], force_fresh: force_fresh) do
      Bundler.require(:pulsar)
      ::MessageBus::CaCert.ensure_presence!(self.config)
      topic = self.topic_url(namespace, topic_name)
      self.client.create_producer(topic)
    end
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
    check_conn_pool(["consumers", namespace, topic_name, subscription_name], force_fresh: force_fresh) do
      Bundler.require(:pulsar)
      ::MessageBus::CaCert.ensure_presence!(self.config)
      topic = topic_url(namespace, topic_name)
      consumer_config = Pulsar::ConsumerConfiguration.new({})
      consumer_config.subscription_initial_position = :earliest
      self.client.subscribe(topic, subscription_name, consumer_config)
    end
  end

  def self.topic_url(namespace, topic_name, app_env=Canvas.environment)
    app_env = (app_env || "development").downcase
    conf_hash = self.config
    # by using the application env in the topic name, we can
    # share a non-prod pulsar instance between environments
    # like test/beta/edge whatever and not have to provision
    # other overhead to separate them or deal with the confusion of shared
    # data in a single topic.
    "persistent://#{conf_hash['PULSAR_TENANT']}/#{namespace}/#{app_env}-#{topic_name}"
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
        cached_object.close()
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

  def self.config(shard=::Switchman::Shard.current)
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
    close_and_reset_cached_connections!
    connection_mutex.synchronize do
      @client&.close()
      @client = nil
    end
    @config_cache = nil
  end

  def self.close_and_reset_cached_connections!
    connection_mutex.synchronize do
      return if @connection_pool.blank?

      @connection_pool.each do |_thread_id, thread_conn_pool|
        if thread_conn_pool['producers'].present?
          thread_conn_pool['producers'].each do |_namespace, topic_map|
            topic_map.each do |_topic, producer|
              producer.close()
            end
          end
        end

        if thread_conn_pool['consumers'].present?
          thread_conn_pool['consumers'].each do |_namespace, topic_map|
            topic_map.each do |_topic, subscription_map|
              subscription_map.each do |_sub_name, consumer|
                consumer.close()
              end
            end
          end
        end
      end
      @connection_pool = nil
    end
  end
  private_class_method :close_and_reset_cached_connections!

  def self.connection_mutex
    @connection_mutex ||= Mutex.new
  end
  private_class_method :connection_mutex
end