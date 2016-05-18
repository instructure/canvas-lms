class Favorite < ActiveRecord::Base
  # These are basically now "Unfavorites"
  # totes not confusing

  belongs_to :context, polymorphic: [:course, :group]
  belongs_to :user
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Group'].freeze
  scope :by, ->(type) { where(:context_type => type.to_s) }
  scope :hidden, -> { where(hidden: true) }
  scope :not_hidden, -> { where.not(hidden: true) }

  attr_accessible :context, :context_id, :context_type, :hidden

  # Set whether or not the specified context is considered to be one of the user's favorites. Returns the corresponding
  # Favorite object, which may not actually be persisted in the database if it was just deleted or didn't exist.
  def self.show_context(user, context)
    context_id = Shard.relative_id_for(context.id, Shard.current, user.shard)

    fave = user.favorites.where(context_type: context.class.to_s, context_id: context_id).take
    if fave
      if fave.hidden?
        fave.hidden = false
        fave.save!
      end
      fave
    else
      # Return an anonymous favorite if we didn't actually have one because the old API used to do that
      user.shard.activate do
        Favorite.new do |f|
          f.user = user
          f.context = context
          f.readonly!
        end
      end
    end
  end

  # returns nil if it was already hidden
  def self.hide_context(user, context)
    context_id = Shard.relative_id_for(context.id, Shard.current, user.shard)

    Favorite.unique_constraint_retry do
      fave = user.favorites.where(context_type: context.class.to_s, context_id: context_id).first
      if fave
        return nil if fave.hidden? # return nil here if it was already hidden - again because the old API used to do that :/

        fave.hidden = true
        fave.save!
        fave
      else
        user.favorites.create!(context: context, hidden: true)
      end
    end
  end

  def self.reset(user, context_type)
    user.favorites.hidden.by(context_type).update_all(:hidden => false)
  end
end
