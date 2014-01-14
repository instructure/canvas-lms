module Canvas
  class APISerializer < ActiveModel::Serializer
    extend Forwardable

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

    # Override `ActiveModel::Serializer`s serializable_object to stringify_ids
    # and ids in relationships if necessary.
    #
    # Stringifies your ids if:
    #   * Endpoint has the "Accept: application/vnd.api+json" header
    #   * Has the stringify json ids header
    def serializable_object(options={})
      hash = super(options)
      return hash unless accepts_jsonapi? || stringify_json_ids?
      Api.stringify_json_ids(hash)
      if (links = hash['links']).present?
        links.each do |key, value|
          links[key] = value.is_a?(Array) ? value.map(&:to_s) : value.to_s
        end
      end
      hash
    end

    # Creates a method alias for the "object" method based on the name of your
    # serializer. For example, if your class is `QuizSerializer`, you will
    # have a method named "quiz" available to your class, so you don't have to
    # use object if you don't want to.
    def self.inherited(klass)
      super(klass)
      resource_name = klass.name.underscore.downcase.split('_serializer').first
      klass.send(:alias_method, resource_name.to_sym, :object)
    end
  end
end

