class Loaders::ForeignKeyLoader < GraphQL::Batch::Loader
  def initialize(scope, fk)
    @scope = scope
    @column = fk
  end

  def load(key)
    super(key.to_s)
  end

  def perform(ids)
    records = @scope.where(@column => ids).group_by { |o| o.send(@column).to_s }
    ids.each { |id|
      fulfill(id, records[id])
    }
  end
end
