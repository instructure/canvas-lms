namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:all) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end