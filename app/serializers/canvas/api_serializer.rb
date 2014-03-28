module Canvas
  class APISerializer < ActiveModel::Serializer
    extend Forwardable
    include Canvas::APISerialization

    attr_reader :controller, :session
    alias_method :user, :scope
    alias_method :current_user, :user
    def_delegators :@controller, :stringify_json_ids?, :polymorphic_url,
      :accepts_jsonapi?, :session, :context

    # See ActiveModel::Serializer's documentation for options.
    #
    # object - thing to serialize, e.g. quiz, assignment
    # options - see AMS documentation, however, you must pass a :controller
    # key with a controller.
    #
    # methods available on your instance:
    #
    # session - controller's session
    # controller - controller
    # accepts_jsonapi? - if jsonapi header is present
    # polymorphic_url - for good ole' rails URL helpers
    # context - if your controller has a @context, it'll be that. Otherwise,
    # nil.
    # stringify_json_ids? - whether the stringify_json_ids? header is present
    # user - whatever you passed as options[:scope]
    # current_user - alias for user
    def initialize(object, options={})
      super(object, options)
      @controller = options[:controller]
      unless controller
        raise ArgumentError.new("You must pass a controller to APISerializer!")
      end
    end

    # Overriding to allow for "links" hash.
    # You should probably NOT override this method in your own serializer.
    # This will be going away once ActiveModel::Serializer has support for
    # the "links" style.
    def associations
      associations = self.class._associations
      included_associations = filter(associations.keys)
      associations.each_with_object({}) do |(name, association), hash|
        if included_associations.include? name
          if association.embed_ids?
            hash['links'] ||= {}
            hash['links'][association.name] = serialize_ids association
          elsif association.embed_objects?
            hash['links'] ||= {}
            hash['links'][association.embedded_key] = serialize association
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
    def as_json(options={})
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
      resource_name = klass.name.demodulize.underscore.downcase.split('_serializer').first
      klass.send(:alias_method, resource_name.to_sym, :object)
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
      # We want to use `empty?` instead of `present?` for has_many associations
      # so that we don't attempt to load all records into the database.
      # Unfortunately, `empty?` doesn't exist for
      # ActiveRecord::Associations::BelongsToAssociation, so we'll fall back
      # to using `present?` for has_one associations, which won't overload
      # app memory or the database with a large query.
      if instance && association.is_a?(ActiveModel::Serializer::Association::HasMany)
        send("#{name}_url".to_sym) unless instance.empty?
      elsif instance.present?
        send("#{name}_url".to_sym)
      end
    end
  end
end
