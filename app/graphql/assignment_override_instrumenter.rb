class AssignmentOverrideInstrumenter
  # NOTES ON THIS INSTRUMENTER:
  #
  # This thing is amazing because it provides the foundation
  # overriding assignments only when necessary (for example, when the
  # due date is requested).  Thoughts/potential issues/caveats:
  #
  # * I love that this automatically applies to assignments no matter
  # where they appear in the schema.  I don't love that this is
  # modifying the resolver of every item in the schema.  The best
  # case scenario of suckage is that this now appears in the stack
  # trace of all graphql queries.  The worst case would be that this
  # adds measurable overhead (maybe if #typed_children is expensive
  # and not called otherwise?).
  #
  # We could be more selective about when we override a resolver, but
  # then the instrumenter will need to be modified whenever
  # assignments are introduced in a new area of the schema.  It seems
  # like this could be made into a general purpose instrumenter that
  # we hook into for other uses as well (we probably shouldn't add
  # any more instrumenters that modify all fields as this one does).
  def instrument(type, field)
    old_resolver = field.resolve_proc
    field.redefine do
      resolve ->(obj, args, ctx) {
        assignment_selections = ctx.irep_node.typed_children[CanvasSchema.types["Assignment"]]
        if assignment_selections &&
            AssignmentOverrideInstrumenter.needs_overriding?(assignment_selections)
          assignment_or_promise = old_resolver.call(obj, args, ctx)
          assignment_overrider = ->(assignment) {
            Loaders::AssociationLoader.
              for(Assignment, :assignment_overrides).
              load(assignment).then {
                assignment.overridden_for(ctx[:current_user])
              }
          }

          case assignment_or_promise
          when Assignment
            assignment_overrider.call(assignment_or_promise)
          when GraphQL::Batch::Promise
            assignment_or_promise.then(assignment_overrider)
          else
            raise "unexpected assignment type!"
          end
        else
          old_resolver.call(obj, args, ctx)
        end
      }
    end
  end

  ATTRIBUTES_NEED_OVERRIDING = %w[dueAt allDay dallDayDate unlockAt lockAt].freeze

  # assignments are automatically overridden in graphql whenever one of the
  # dueAt/lockAt/unlockAt fields are requested *UNLESS* the user is also
  # requesting the list of assignment_overrides.  The rationale is that the
  # user won't have a way of seeing the assignment's default due date if it's
  # overriden
  def self.needs_overriding?(selections)
    ATTRIBUTES_NEED_OVERRIDING.any? { |attr| selections.key?(attr) } &&
      !selections.key?("assignmentOverrides")
  end
end
