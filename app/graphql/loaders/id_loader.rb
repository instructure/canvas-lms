class Loaders::IDLoader < GraphQL::Batch::Loader
  def initialize(scope)
    @scope = scope
  end

  def perform(ids)
    @scope.where(id: ids).each { |o| fulfill(o.id.to_s, o) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
