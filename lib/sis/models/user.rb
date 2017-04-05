module SIS
  module Models
    class User
      attr_accessor :user_id, :login_id, :status, :first_name, :last_name,
                    :email, :password, :ssha_password, :integration_id,
                    :short_name, :full_name, :sortable_name,
                    :authentication_provider_id, :sis_batch_id

      def initialize(user_id:, login_id:, status:, first_name: nil, last_name: nil,
                     email: nil, password: nil, ssha_password: nil,
                     integration_id: nil, short_name: nil, full_name: nil,
                     sortable_name: nil, authentication_provider_id: nil,
                     sis_batch_id: nil)
        self.user_id = user_id
        self.login_id = login_id
        self.status = status
        self.first_name = first_name
        self.last_name = last_name
        self.email = email
        self.password = password
        self.ssha_password = ssha_password
        self.integration_id = integration_id
        self.short_name = short_name
        self.full_name = full_name
        self.sortable_name = sortable_name
        self.authentication_provider_id = authentication_provider_id
        self.sis_batch_id = sis_batch_id
      end

      def to_a
        [user_id.to_s, login_id.to_s, status, first_name, last_name, email,
         password.to_s, ssha_password.to_s, integration_id.to_s, short_name,
         full_name, sortable_name, authentication_provider_id]
      end
    end
  end
end


