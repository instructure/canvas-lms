module BasicLTI
  module VariableSubstitution
    module Canvas
      class Api < AbstractSubstitutor
        def domain
          root_account.domain
        end
      end

      class Assignment < AbstractSubstitutor
        # $Canvas.assignment.id
        def id
          assignment.id if assignment
        end

        def title
          assignment.title if assignment
        end

        def points_possible
          assignment.points_possible if assignment
        end
      end

      class Context < AbstractSubstitutor
        def id
          context.id if context
        end

        def sis_source_id
          context.sis_source_id if context
        end
      end

      class Enrollment < AbstractSubstitutor
        def enrollment_state
          launch.user_data['enrollment_state'] if launch.user_data
        end
      end

      class Membership < AbstractSubstitutor
        # returns the same LIS Role values as the default 'roles' parameter,
        # but for concluded enrollments
        # $Canvas.membership.concludedRoles
        def concluded_roles
          launch.user_data['concluded_role_types'] ? launch.user_data['concluded_role_types'].join(',') : nil if launch.user_data
        end
      end

      class User < AbstractSubstitutor
        def id
          user.id if user
        end

        def login_id
          pseudonym.unique_id if pseudonym
        end
      end
    end
  end
end

