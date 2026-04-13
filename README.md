# slurm-experimentation

This repo documents my experimentation with deploying slurm to understand the components, the architecture and the failure points.


## Deployment and Challenges

All the documents are stored in [docs](./docs/) directory.

The [first document](./docs/00-slurm-manual-installation.md) describes the installation of slurm on a group of Rocky Linux 9 machines.
The [second document](./docs/01-creating-k8s-cluster.md) describes the creation of the kubernetes cluster to test Slurm Operator by [Project Slinky](https://slurm.schedmd.com/slinky.html)
The [third document](./docs/02-slinky-installation.md) describes my installation of the Slurm operator and the Slurm cluster created.

## Ansible Roles

All ansible roles are currently stored in the directory [roles](./roles/), the only current available role is [slurm](./roles/slurm/) for the regular installation of slurm.