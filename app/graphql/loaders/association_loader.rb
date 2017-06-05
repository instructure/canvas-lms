class Loaders::AssociationLoader < GraphQL::Batch::Loader
  def initialize(_model, associations)
    @associations = associations
  end

  def perform(objects)
    ActiveRecord::Associations::Preloader.new.preload(objects, @associations)
    objects.each { |o| fulfill(o, o) }
  end
end
