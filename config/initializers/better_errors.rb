# monkey patch to always allow other ip addresses in development mode
if Rails.env.development? && !ENV['DISABLE_BETTER_ERRORS']
  module BetterErrors
    class Middleware
      def allow_ip?(_)
        true
      end
    end
  end
end
