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
module MessageBus

  def self.producer_for(namespace, topic_name)
    Bundler.require(:pulsar)
    topic = self.topic_url(namespace, topic_name)
    self.client.create_producer(topic)
  end

  def self.consumer_for(namespace, topic_name, subscription_name)
    Bundler.require(:pulsar)
    topic = topic_url(namespace, topic_name)
    consumer_config = Pulsar::ConsumerConfiguration.new({})
    consumer_config.subscription_initial_position = :earliest
    self.client.subscribe(topic, subscription_name, consumer_config)
  end

  def self.topic_url(namespace, topic_name, rails_env=Rails.env)
    conf_hash = self.config
    # by using the rails env in the topic name, we can
    # share a non-prod pulsar instance between environments
    # like test/beta/edge whatever and not have to provision
    # other overhead to separate them or deal with the confusion of shared
    # data in a single topic.
    "persistent://#{conf_hash['PULSAR_TENANT']}/#{namespace}/#{rails_env}-#{topic_name}"
  end

  def self.client
    return @client if @client

    conf_hash = self.config
    client_config = Pulsar::ClientConfiguration.from_environment({}, conf_hash)
    broker_uri = conf_hash['PULSAR_BROKER_URI']
    @client = Pulsar::Client.new(broker_uri, client_config)
  end

  def self.enabled?
    hash = self.config
    hash['PULSAR_BROKER_URI'].present? && hash['PULSAR_TENANT'].present?
  end

  def self.config(shard=::Switchman::Shard.current)
    settings = DynamicSettings.find(tree: :private, cluster: shard.database_server.id)
    YAML.safe_load(settings['pulsar.yml'] || '{}')
  end

  def self.reset!
    @client = nil
  end
end
