module GraphQLHelpers
  # this function allows an argument to take ids in the graphql global form or
  # standard canvas ids. the resolve function for fields using this preparer
  # will get a standard canvas id
  def self.relay_or_legacy_id_prepare_func(expected_type)
    Proc.new do |relay_or_legacy_id, ctx|
      begin
        self.parse_relay_or_legacy_id(relay_or_legacy_id, expected_type)
      rescue InvalidIDError => e
        GraphQL::ExecutionError.new(e.message)
      end
    end
  end

  def self.relay_or_legacy_ids_prepare_func(expected_type)
    Proc.new do |relay_or_legacy_ids, ctx|
      begin
        relay_or_legacy_ids.map { |relay_or_legacy_id, ctx|
          self.parse_relay_or_legacy_id(relay_or_legacy_id, expected_type)
        }
      rescue InvalidIDError => e
        GraphQL::ExecutionError.new(e.message)
      end
    end
  end

  def self.parse_relay_or_legacy_id(relay_or_legacy_id, expected_type)
    if relay_or_legacy_id =~ /\A\d+\Z/
      relay_or_legacy_id
    else
      type, id = GraphQL::Schema::UniqueWithinType.decode(relay_or_legacy_id)
      if (type != expected_type || id.nil?)
        raise InvalidIDError.new("expected an id for #{expected_type}")
      else
        id
      end
    end
  end

  class InvalidIDError < StandardError; end
end
