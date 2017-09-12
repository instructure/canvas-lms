class Loaders::IDLoader < GraphQL::Batch::Loader
  def initialize(scope)
    @scope = scope
  end

  def load(key)
    # since we might load an id that is a number or a string, we need to coerce
    # here to keep things consistent
    super(key.to_s)
  end

  def perform(ids)
    @scope.where(id: ids).each { |o| fulfill(o.id.to_s, o) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
