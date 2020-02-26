module CdcFixtures
  def self.create_domain
    Csp::Domain.new(account_id: 1, domain: 'example.com', workflow_state: 'default')
  end
end
