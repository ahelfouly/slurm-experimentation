Slurm
=========

This role is made to install slurm cluster composed of Control and Compute nodes.

Requirements
------------

This role is mainly tested for use with Rocky Linux 9. More distros to be tested and added.

You'll need to add  your control nodes to ansible group `slurm_controller` and your compute nodes to ansible group `slurm_compute` in your inventory.

Role Variables
--------------

Overridable variables

| Variable | Default Value |
| -------- | ------------- |
| slurm_munge_version | 0.5.18 |
| slurm_package_version | 25.11.3 |
| slurm_gid | 1500 |
| slurm_uid | 1500 |
| slurm_srun_ports.start | 60001 |
|  slurm_srun_ports.end | 63000 |

Dependencies
------------

| Collections |
| ----------- |
| ansible.posix |



License
-------

BSD
