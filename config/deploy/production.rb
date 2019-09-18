# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

# Use private IPs since the server is behind a firewall and public IPs don't work there.
role :app, %w{deploy@172.31.12.39}
role :web, %w{deploy@172.31.12.39}
role :db,  %w{deploy@172.31.12.39}

set :branch, 'bz-master'

# Default value for keep_releases is 5
# Set it to 2 to free up space (2-3GB per release, plus 2-3GB overhead to compile npm assets on an 16GB server fills it up fast)
# and realistically, we don't release until we're sure it's good.  
set :keep_releases, 2


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

# server 'portal.bebraven.org', user: 'deploy', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
  set :ssh_options, {
    keys: %w(/home/braven-admin/agentkeys/id_rsa)
#    forward_agent: false,
#    auth_methods: %w(password)
  }
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
