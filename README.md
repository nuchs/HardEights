# Hard Eights

This is a record of my attempts to build a hardened kubernetes cluster from
scratch

## Cluster 

The plan is to create a high availability control plane with linux worker
nodes. The cluster should have a single point of ingress and should make use of
egress to call an external resource. The cluster will also make use of an
external CA to aovid keeping the CA private key in the cluster and an external
private image registry.
