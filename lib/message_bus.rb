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
  def self.producer_for(namespace, topic_name)
    Bundler.require(:pulsar)
    ::MessageBus::CaCert.ensure_presence!(self.config)
    topic = self.topic_url(namespace, topic_name)
    self.client.create_producer(topic)
  end

  def self.consumer_for(namespace, topic_name, subscription_name)
    Bundler.require(:pulsar)
    ::MessageBus::CaCert.ensure_presence!(self.config)
    topic = topic_url(namespace, topic_name)
    consumer_config = Pulsar::ConsumerConfiguration.new({})
    consumer_config.subscription_initial_position = :earliest
    self.client.subscribe(topic, subscription_name, consumer_config)
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
    @client = nil
    @config_cache = nil
  end
end
