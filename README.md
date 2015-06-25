rsync
=====

[![Ansible Galaxy](https://img.shields.io/badge/galaxy-kbrebanov.rsync-660198.svg)](https://galaxy.ansible.com/list#/roles/3303)

Installs rsync.  Optionally [as a daemon][1] with `/etc/rsyncd.conf` and `/etc/xinetd.d/rsync`.

Requirements
------------

This role requires Ansible 1.9 or higher.

Role Variables
--------------

The default role variables in `defaults/main.yml` are:

    ---
    # defaults file for rsync
    
    rsync_install_daemon: false
    
    # Only install rsync by default, (xinetd daemon is only needed if rsync_install_daemon is set)
    rsync_packages:
      - rsync
    
    # Changing this to 'yes' will disable the rsync service, so you probably want to leave
    # this alone...
    rsync_disable: "no"
    
    # See rsync(1) man page for details on how to set the server arguments
    # http://linux.die.net/man/1/rsync
    rsync_server_args: "--daemon"
    
    # See xinetd.conf(5) man page for details on how to set the xinetd service arguments
    # http://linux.die.net/man/5/xinetd.conf
    rsync_log_on_failure: "USERID"
    rsync_flags: IPv6
    rsync_socket_type: stream
    rsync_port: 873
    rsync_protocol: tcp
    rsync_wait: no
    rsync_user: root
    rsync_server: /usr/bin/rsync
    
    rsync_daemon_manage_config: true
    rsync_daemon_lock_file: /var/run/rsync.lock
    rsync_daemon_log_file: /var/log/rsyncd.log
    rsync_daemon_pid_file: /var/run/rsyncd.pid


  - `rsync_install_daemon` - Install [rsync in `--daemon` mode managed by xinetd][1].
  - `rsync_disable` - Disables `xinetd` `rsync` daemon service (in `/etc/xinetd.d/rsync`).  Changing this to 'yes' will disable the `rsync` service.
  - `rsync_daemon_manage_config` - Default `true` (Boolean).  Determines whether or not this Ansible role will manage the `/etc/rsyncd.conf` file via the provided template.  If this is `false`, you must provide your own `/etc/rsyncd.conf` file.
  - `rsync_daemon_user_secrets` - A [Dict][5] (a.k.a: [Hash][6]) of `key: value` pairs in the form: `user: password`.  To avoid having to specify these vars in your playbook in plaintext, you may want to use [Ansible Vault][7].  These will be used as [`user:password` lines to write to `/etc/rsyncd.secrets`][4].  If set, the file `/etc/rsyncd.secrets` will be managed by the template provided in this role.  **Note**:  If `rsync_daemon_user_secrets` is set, the global `/etc/rsyncd.secrets` file will be used for **all** shares specified in `rsync_daemon_shares`, and all users specified will be used as the `auth users` parameter.  This role's behavior is set in this way so as to provide a minimum level of guaranteed security.  The format for this Dict / Hash is as follows (please use more secure passwords!):

        rsync_daemon_user_secrets:
          myuser: mypassword
          myuser2: mypassword2
          vagrant: vagrant

  - `rsync_daemon_shares` - A [Dict][5] (a.k.a: [Hash][6]) of folder shares ([`rsyncd.conf(5)`][4] man page calls these "`modules`").  These will be iterated over and placed in the `/etc/rsyncd.conf` file in the following format:

        rsync_daemon_shares:
          mymodule:
            path: /tmp/somefolder/
            comment: things to share as mymodule
            uid: myuser
            gid: mygroup
            read only: "no"
            list: "yes"
            hosts allow: 127.0.0.1/255.255.255.0

    - The format for the resulting rendered template would be (assuming users: `myuser`, `myuser2`, and `vagrant` were specified in `rsync_daemon_user_secrets`, and defaults for `rsync_daemon_lock_file`, `rsync_daemon_log_file`, and `rsync_daemon_pid_file`):

          lock file = /var/run/rsync.lock
          log file = /var/log/rsyncd.log
          pid file = /var/run/rsyncd.pid

          [mymodule]
              comment = things to share as mymodule
              uid = myuser
              list = yes
              hosts allow = 127.0.0.1/255.255.255.0
              gid = mygroup
              path = /tmp/somefolder/
              read only = no
              auth users = myuser, myuser2, vagrant
              secrets file = /etc/rsyncd.secrets

  - `rsync_daemon_max_connections` - [`max connections` rsyncd.conf parameter][4].  This parameter allows you to specify the maximum number of simultaneous connections you will allow. Any clients connecting when the maximum has been reached will receive a message telling them to try later. **The default is `0`**, which means no limit. A negative value disables the module. See also the `lock file` parameter.
  - `rsync_daemon_lock_file` - [`lock file` rsyncd.conf parameter][4].  This parameter specifies the file to use to support the `max connections` parameter. The `rsync` daemon uses record locking on this file to ensure that the `max connections` limit is not exceeded for the modules sharing the lock file. **The default is `/var/run/rsync.lock`**.
  - `rsync_daemon_log_file` - [`log file` rsyncd.conf parameter][4].  When the `log file` parameter is set to a non-empty string, the `rsync` daemon will log messages to the indicated file rather than using `syslog`.  If the daemon fails to open the specified file, it will fall back to
using `syslog` and output an error about the failure.  **The default is `/var/log/rsyncd.log`**.
  - `rsync_daemon_pid_file` - [`pid file` rsyncd.conf parameter][4].  This parameter tells the `rsync` daemon to write its process ID to that file. If the file already exists, the `rsync` daemon will abort rather than overwrite the file.  **The default is `/var/run/rsyncd.pid`**.
  - `rsync_server_args` - Arguments to pass the rsync process that is spawned by `xinetd` as a daemon.  See [rsync(1) man page][2] for details on server args.
  - `rsync_log_on_failure` - [`log_on_failure` xinetd.conf service argument][3] for `rsync` daemon.  Determines what information is logged.
  - `rsync_flags` - [`flags` xinetd.conf service argument][3] for `rsync` daemon.  See xinetd.conf(5) man page for details on how to set this xinetd service attribute.
  - `rsync_socket_type` - [`socket_type` xinetd.conf service argument][3] for `rsync` daemon.  Type of socket to use.  See xinetd.conf(5) man page for details on how to set this xinetd service attribute.
  - `rsync_port` - [`port` xinetd.conf service argument][3] for `rsync` daemon.  Optional if service is defined in `/etc/services`.  Determines the service port. If this attribute is specified for a service listed in /etc/services, it must be equal to the port number listed in that file.
  - `rsync_protocol` - [`protocol` xinetd.conf service argument][3] for `rsync` daemon.  Optional.  Determines the protocol that is employed by the service.  The protocol must exist in `/etc/protocols`. **If this attribute is not defined, the default protocol employed by the service will be used.**
  - `rsync_wait` - [`wait` xinetd.conf service argument][3] for `rsync` daemon.  This attribute determines if the service is single-threaded or multi-threaded and whether or not xinetd accepts the connection or the server program accepts the connection. If its value is `yes`, the service is single-threaded; this means that `xinetd` will start the server and then it will stop handling requests for the service until the server dies and that the server software will accept the connection. If the attribute value is `no`, the service is multi-threaded and `xinetd` will keep handling new service requests and `xinetd` will accept the connection. It should be noted that `udp/dgram` services normally expect the value to be `yes` since `udp` is not connection oriented, while `tcp/stream` servers normally expect the value to be `no`.
  - `rsync_user` - [`user` xinetd.conf service argument][3] for `rsync` daemon.  Determines the `uid` for the server process. The `user` attribute can either be numeric or a name. If a name is given (recommended), the user name must exist in `/etc/passwd`. This attribute is ineffective if the effective user ID of `xinetd` is not super-user.
  - `rsync_server` - [`server` xinetd.conf service argument][3] for `rsync` daemon.  Determines the program to execute for this service.


[1]: http://www.jveweb.net/en/archives/2011/01/running-rsync-as-a-daemon.html
[2]: http://linux.die.net/man/1/rsync
[3]: http://linux.die.net/man/5/xinetd.conf
[4]: http://linux.die.net/man/5/rsyncd.conf
[5]: http://docs.ansible.com/YAMLSyntax.html#yaml-basics
[6]: https://en.wikipedia.org/?title=YAML#cite_note-Vartype000-4
[7]: http://docs.ansible.com/playbooks_vault.html

Dependencies
------------

None

Example Playbook
----------------

Install `rsync` package without daemon:

```
- hosts: all
  roles:
    - { role: kbrebanov.rsync }
```

Install `rsync` with `xinetd`-managed daemon:

```
---
# This playbook deploys the rsync role with xinetd-managed daemon

- hosts: my-host
  user: root
  vars:
    rsync_install_daemon: true
    # Enable these example folder shares (a.k.a: "modules")
    rsync_daemon_shares:
      kitchen:
        path: /tmp/foo
        comment: foo files
        uid: vagrant
        gid: vagrant
        read only: "no"
        list: "yes"
        hosts allow: 127.0.0.1/255.255.255.0
        # "auth users" are auto-generated by template from rsync_daemon_user_secrets
        # auth users: vagrant, kitchen
        # secrets file: /etc/rsyncd.secrets
    # Normally these vars should be in Ansible Vault
    # But for the purpose of this example they are shown.
    # Define this as `user: password` pairs:
    rsync_daemon_user_secrets:
      vagrant: vagrant
      kitchen: kitchen

  roles:
    - rsync
```

License
-------

BSD

Author Information
------------------

Kevin Brebanov

James Cuzella ([@trinitronx](https://github.com/trinitronx))
