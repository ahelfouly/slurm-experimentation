# Installing Slurm from project Slinky

Following [Slinky Installation Guide](https://slinky.schedmd.com/projects/slurm-operator/en/release-1.0/installation.html)


Installing Slurm Operator
--------------------------

For simplicity installing the CRDs as subchart of the operator and the Operator without cert-manager.

```
helm install slurm-operator oci://ghcr.io/slinkyproject/charts/slurm-operator --set 'crds.enabled=true' \
    --set 'certManager.enabled=false' --namespace=slinky --create-namespace
```

Example of post installation pods

```
[root@ctrl01 ~]# kubectl -n slinky get pods
NAME                                      READY   STATUS    RESTARTS       AGE
slurm-operator-6474946b5f-kh96c           1/1     Running   4 (153m ago)   2d18h
slurm-operator-webhook-569bf58d94-4mz44   1/1     Running   4 (153m ago)   2d18h
```

Installing Slurm
----------------

Deploy slurm cluster with helm, since we're not doing accounting, and this is POC/lab, controller persistence is disabled.

```
helm install slurm oci://ghcr.io/slinkyproject/charts/slurm --set 'controller.persistence.enabled=false' \
    --set 'nodesets.slinky.replicas=2'  --namespace=slurm --create-namespace
```


Example of installed cluster

```
[root@ctrl01 ~]# kubectl get -n slurm pods
NAME                             READY   STATUS    RESTARTS        AGE
slurm-controller-0               3/3     Running   12 (3h7m ago)   2d18h
slurm-restapi-5668d54b45-hxhx4   1/1     Running   4 (3h7m ago)    2d18h
slurm-worker-slinky-0            2/2     Running   12 (3h7m ago)   2d18h
slurm-worker-slinky-1            2/2     Running   6 (3h7m ago)    2d18h
```

Test job

```
[root@ctrl01 ~]# kubectl -n slurm exec -it pods/slurm-controller-0 -- srun -N 2 hostname
slinky-0
slinky-1
```
