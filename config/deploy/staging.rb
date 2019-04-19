# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

# Use private IPs since the server is behind a firewall and public IPs don't work there.
role :app, %w{deploy@172.31.3.79}
role :web, %w{deploy@172.31.3.79}
role :db,  %w{deploy@172.31.3.79}

set :branch, 'bz-staging'

# On staging, we reinstallled npm using nvm. So use the capistrano-nvm gem
# We did this under the "deploy" user since that's the user capistrano runs as.
# We also edited /home/deploy/.bashrc to move the NVM related stuff to the top of 
# the file so that it would run in non-interactive shells (which capistrano deploys use)
set :nvm_node, 'v0.12.14'
set :nvm_map_bins, %w{node npm}

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

# server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
  set :ssh_options, {
    keys: %w(/home/braven-admin/keys/id_rsa)
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
