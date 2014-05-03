module BasicLTI
  module VariableSubstitution
    module Person
      class Name < AbstractSubstitutor
        # $Person.name.full
        def full
          user.name
        end

        # $Person.name.family
        def family
          user.last_name
        end

        # $Person.name.given
        def given
          user.first_name
        end
      end

      class Address < AbstractSubstitutor
        def timezone
          Time.zone.tzinfo.name
        end
      end
    end
  end
end