# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Canvas
  # Canvas extensions to the base AMS. All instances of this class require a
  # Controller instance to operate.
  #
  # Serializers inherting from this class will be equipped with several helper
  # methods as well as runtime options.
  #
  # Methods available on your instance:
  #
  # @method session
  # @return [ActiveRecord::Base] The controller's session.
  #
  # @method controller
  # @return [ApplicationController]
  #   The controller instance the serializer is bound to.
  #
  # @method accepts_jsonapi?
  # @return [Boolean] Whether jsonapi header is present.
  #
  # @method polymorphic_url
  # @return [String] good ole' rails URL helpers
  #
  # @method context
  # @return [ActiveRecord::Base|NilClass]
  #   If your controller has a @context, it'll be that. Otherwise, nil.
  #
  # @method stringify_json_ids?
  # @return [Boolean]
  #   Whether the stringify_json_ids? header is present.
  #
  # @method user
  # @alias  current_user
  # @return [ActiveRecord::Base|Hash|NilClass]
  #   Whatever you pass in as options[:scope] to the serializer initializer.
  class APISerializer < ActiveModel::Serializer
    extend Forwardable
    include Canvas::APISerialization

    attr_reader :controller, :session

    # Array of strings that can be passed by the controller to signal which
    # associations to embed in the serializer output. You can test this array
    # in your own serializer to figure out what to include, e.g
    #
    #   has_one :post, embed: :object
    #
    #   def filter(keys)
    #     case keys
    #     # ...
    #     when :post then @sideloads.include?('post')
    #     end
    #   end
    #
    # The strings are parsed from options[:includes] when initializing the
    # serializer.
    attr_reader :sideloads

    alias_method :user, :scope
    alias_method :current_user, :user

    def_delegators :@controller,
                   :polymorphic_url,
                   :accepts_jsonapi?,
                   :session,
                   :context

    # See ActiveModel::Serializer's documentation for options.
    #
    # object - thing to serialize, e.g. quiz, assignment
    # options - see AMS documentation, however, you must pass a :controller
    # key with a controller.
    #
    # @param [Hash] options[:serializer_options]
    #   Implementation-specific options you can pass from controller to the
    #   serializer instance. Useful for customizing output based on request
    #   or controller state (i.e, minimal output in index views, but full in
    #   show views).
    #
    #   Use these options in your serializer implementation using
    #   #serializer_option(key)
    def initialize(object, options = {})
      super(object, options)
      @controller = options[:controller]
      @sideloads = options.fetch(:includes, []).map(&:to_s)
      @serializer_options = options.fetch(:serializer_options, {})
      unless controller
        raise ArgumentError, "You must pass a controller to APISerializer!"
      end
    end

    def stringify_json_ids?
      @controller.send(:stringify_json_ids?)
    end

    # Overriding to build the "links" hash how we want.
    # You should probably NOT override this method in your own serializer.
    def associations(options = {})
      associations = self.class._associations
      included_associations = filter(associations.keys)
      associations.each_with_object({}) do |(name, association), hash|
        if included_associations.include? name
          if association.embed_ids?
            hash["links"] ||= {}
            hash["links"][association.name] = serialize_ids association
          elsif association.embed_objects? && association.embed_in_root?
            hash[association.embedded_key] = serialize association, options
          elsif association.embed_objects?
            hash["links"] ||= {}
            hash["links"][association.embedded_key] = serialize association, options
          end
        end
      end
    end

    # Overriding *ONLY* to add our own stringify logic in here.
    # You should not override as_json in your own subclass.
    # Override `ActiveModel::Serializer`s serializable_object to stringify_ids
    # and ids in relationships if necessary.
    #
    # You can override when to stringify by implementing the "stringify_ids?"
    # method.
    def as_json(options = {})
      root = options[:root]
      hash = super(options)
      response = root ? (hash[root] || hash) : hash
      response = response[self.root] || response
      stringify!(response)
      hash
    end

    # Creates a method alias for the "object" method based on the name of your
    # serializer. For example, if your class is `QuizSerializer`, you will
    # have a method named "quiz" available to your class, so you don't have to
    # use object if you don't want to.
    def self.inherited(klass)
      super(klass)
      resource_name = klass.name.demodulize.underscore.downcase.split("_serializer").first
      klass.send(:alias_method, resource_name.to_sym, :object)
    end

    # Overriding to pass the controller and required context to association
    # serializers. Necessary when embedding objects as opposed to IDs only.
    #
    # You can specify an association option :wrap_in_array to tell whether
    # the embedded object should be wrapped in an array or not in has_one
    # assocs (AMS defaults to true).
    def build_serializer(association)
      object = send(association.name)
      options = { controller: @controller, scope: }
      association.build_serializer(object, options).tap do |serializer|
        if association.options.key?(:wrap_in_array)
          serializer.instance_variable_set(:@wrap_in_array,
                                           association.options[:wrap_in_array])
        end
      end
    end

    private

    # Overwrite AMS's serialize_id's function until it has support
    # for serializing a url for "links".
    # You can opt into this behavior by using `embed: :ids`
    #
    # ```ruby
    # has_one :assignment_group, embed: :ids
    # ```
    #
    # Will give you a response like:
    #
    # ```json
    # {
    #   "quizzes": [
    #     {
    #       "id": 1,
    #       "links": {
    #         "assignment_group": "http://canvas.example.com/api/v1/path/to/assignment_group"
    #       }
    #     }
    #   ]
    # }
    # ```
    #
    # Note that using `embed_in_root: true` will default to serializing ids, e.g.:
    #
    # ```ruby
    # has_one :assignment_group, embed: ids, embed_in_root: true
    # ```
    #
    # ```json
    # {
    #   "quizzes": [
    #     {
    #       "id": "1",
    #       "links": {
    #         "assignment_group": "1"
    #       }
    #     }
    #   ],
    #   "assignment_groups": [
    #     {
    #       "id": "1"
    #     }
    #   ]
    # }
    # ```
    def serialize_ids(association)
      return super unless association.embed_ids? && !association.embed_in_root

      name     = association.name
      instance = send(name)
      # We want to use `exists?` instead of `present?` for has_many associations
      # so that we don't attempt to load all records into the database.
      # Unfortunately, `exists?` doesn't exist for
      # ActiveRecord::Associations::BelongsToAssociation, so we'll fall back
      # to using `present?` for has_one associations, which won't overload
      # app memory or the database with a large query.
      if instance && association.is_a?(ActiveModel::Serializer::Association::HasMany)
        # fall back to empty? for plain old arrays
        instance_does_not_exist = if instance.respond_to?(:exists?)
                                    !instance.exists?
                                  else
                                    instance.empty?
                                  end
        send(:"#{name}_url") unless instance_does_not_exist
      elsif instance.present?
        send(:"#{name}_url")
      end
    end

    def serializer_option(key)
      @serializer_options[key]
    end
  end
end
