[Archived] IATI-Websites
=============

This directory is for templates, configuration and issues that relate to IATI websites generally, and don't fit into any of the more specific repositories. e.g:

* The GitHub issues on this repository are used to report for any issue that relates to a website operated by the IATI Tech Team, but which doesn't fit into a more specific repository

* Themeing of IATI websites (part of the reason this is not in the SSOT repository is so that if someone else builds a copy of the Standard documentation it won't have the IATI branding)

* Apache redirect configs

* Salt states, and a salt config appropriate for using salt-ssh to deploy to our servers


Using salt-ssh
--------------

Note: the instructions here assume a recent version of Salt. Although many linux distributions now package salt in the default repositories, the packages are likely to be out of date. It's recommended to install the most recent version of salt from http://docs.saltstack.com/en/latest/topics/installation/

The ``salt`` directory in repository contains salt states, whereas ``salt-config`` contains our config for using these with salt-ssh. The ``Saltfile`` ensures that is a salt-ssh command is run in the IATI-Websites directory, then salt-config is used as the config directory.

Because the number of IATI servers is relatively small, we use the slower but easier method of salt provisioning, salt-ssh. Unlike some of the other approaches to salt provisioning where you need a publicly accessible server as the "master", salt-ssh can be run from your local machine.

In the IATI-Websites directory you can run:

.. code-block::

    salt-ssh --priv ~/.ssh/id_rsa <servername> <salt command>

Where ``~/.ssh/id_rsa`` is the private key you use for connecting to thes servers.

Runing as a non-root user
^^^^^^^^^^^^^^^^^^^^^^^^^

By default salt needs to be run as the root user, but this can be avoided by creating ``salt-config/master.d/localuser.conf`` (first do ``mkdir salt-config/master.d``) with the following content (with the parts in angle brackets replaced):

.. code-block::

    cachedir: <path of IATI-Websites directory>/cache/
    log_file: <path of IATI-Websites directory>/log/
    pki_dir: <path of IATI-Websites directory>/salt-config/pki/
    user: <your user name>

Avoid specifying the private key each time
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To avoid having to specify a key on the command line, I add symlinks from the default location:

.. code-block:: bash

    mkdir -p salt-config/pki/ssh
    ln -s ~/.ssh/id_rsa salt-config/pki/ssh/salt-ssh.rsa
    ln -s ~/.ssh/id_rsa.pub salt-config/pki/ssh/salt-ssh.rsa.pub

You should then be able to run simply:

.. code-block::

    salt-ssh <servername> <salt command>

Example Commands
^^^^^^^^^^^^^^^^

<servername> is defined in the roster (https://github.com/IATI/IATI-Websites/blob/master/salt-config/roster)

<salt command> may be:

test.ping
    check that servers are there, and set up correctly.

    As with any salt command, we can use a glob to run this against all servers.

    .. code-block::

        salt-ssh '*' test.ping

state.highstate
    this deploys the states as defined in the top.sls file, e.g.

    .. code-block::

        salt-ssh <servername> state.highstate

state.sls
    this can be used to specify a single state explicitly, e.g.

    .. code-block::

        salt-ssh <servername> state.sls <statename> [<environment name>]``

pkg.upgrade
    to update the packages on the server. This is equivalent to ssh’ing in and running apt-get/aptitude update/upgrade manually.

    This is something we might want to run against all dev servers at once, and then live servers. We can use globs for this

    .. code-block:: 

        salt-ssh '*-dev' pkg.upgrade
        salt-ssh '*-backups' pkg.upgrade
        salt-ssh '*-live' pkg.upgrade

file.file_exists
    Check whether a file exists on the server. This is useful for seeing whether the server needs a reboot. e.g.

    .. code-block:: 

        salt-ssh '*' file.file_exists '/var/run/reboot-required'

system.reboot
    reboots the server.

We have two salt environments defined, base and dev. These currently point to the same state files, but these state files may behave differently if the environment is dev. (ie. using ``{% if saltenv == 'dev' %}``).

Top file and high state
^^^^^^^^^^^^^^^^^^^^^^^

The top file (salt/top.sls) assigns each server to the base or dev environment, and lists the states that should be set up when highstate is run.

Currently not all our servers are listed in top.sls, so not all can successfully run highstate. This is because we are not yet managing these servers with salt states. However, we can still use salt for other routine tasks on these servers, like package updates.

Therefore, to set up/update the live dashboard server, we can do:

.. code-block:: bash

    salt-ssh 'iati-dashboard-live' state.highstate

This is current equivalent to:

.. code-block:: bash

    salt-ssh 'iati-dashboard-live' state.sls dashboard

(no environment name is specified as this is defined as dev)

Similarly to set up the dev dashboard server, we can do:

.. code-block:: bash

    salt-ssh  'iati-dashboard-dev' state.highstate

Which is currently equivalent to:

.. code-block:: bash

    salt-ssh 'iati-dashboard-dev' state.sls dashboard dev

(which needs to explicitly specify the dev environment!)

Using IATI's states on your own servers
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to use IATI's states to set up your own server, you can create your own roster file for your servers, and then use the ``--roster-file`` option to tell salt-ssh, e.g.

.. code-block::

    salt-ssh --roster-file my_roster '*' test.ping
