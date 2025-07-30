Canvas LMS
======

Canvas is a modern, open-source [LMS](https://en.wikipedia.org/wiki/Learning_management_system)
developed and maintained by [Instructure Inc.](https://www.instructure.com/) It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)

---

Important commands to take note:

- To deploy new code:
  1. Go to `/var/canvas/` and then run `sudo -u canvasuser {command}`. For example, `sudo -u canvasuser git pull`.
    - This is required because the folder is owned by `canvasuer`, as part of the setup process.
  2. Restart canvas using passenger `sudo passenger-config restart-app /var/canvas`
  3. Reinitialize canvas `sudo /etc/init.d/canvas_init restart`
  4. Restart apache2 `sudo service apache2 restart`

- If there are any issues, try these:
  - If you just deployed new Ruby code and it crashes the application, check logs:
    - `cat /var/log/apache2/error.log`
  - For general issues, check apache logs and restart
    - `sudo tail -f /var/log/apache2/canvas-dev-error.log`
    - `cat /var/log/apache2/error.log`
    - `sudo service apache2 restart`
  - Check Redis status and restart:
    - `sudo systemctl status redis-server`
    - `sudo systemctl restart redis-server`
   
- To rebuild assets (in case of broken CSS or Ruby dependencies issues)
  - `cd /var/canvas` then run `sudo -u canvasuser bundle install`
  - When done, run `sudo -u canvasuser RAILS_ENV=production bundle exec rake canvas:compile_assets`
  - If issues persist, please read the output and check what went wrong.
      
- To check postgres details:
  - `cat /var/canvas/config/database.yml`
 
- If there are still issues, read through the 'Production Start' link above, and look for potential issues.
