# PKI Time

To prevent certs being issued by someone who has access to the cluster an
external CA will be used as trust anchor for the cluster and the private keys
for the intermediate CA's will not be stored on cluster. 

For the purposes of this experiment the trust anchor will be a cert on the host
generated using openssl and to preserve my sanity  the creation of the certs is
all scripted in the pki/certgen.sh script. 

- The details of what certs need tobe generated can be found at [^1]
- The config file used by the script was generated based on the descriptions in
  [^2], [^3] & [^4]

## Generating certificates

Run:

```
$ cd pki
$ ./certgen.sh
```

The generated files will not be tracked in the git repo.

## Copying the certs to the cluster

[^1]: https://kubernetes.io/docs/setup/best-practices/certificates/
[^2]: https://www.openssl.org/docs/man1.0.2/man5/config.html
[^3]: https://www.openssl.org/docs/manmaster/man5/x509v3_config.html
[^4]: https://www.openssl.org/docs/man1.0.2/man1/x509.html
[^5]: https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
