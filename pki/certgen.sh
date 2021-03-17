#!/bin/bash

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
rootCA="root"

kubeIntCA="kubernetes-ca"
etcdIntCA="etcd-ca"
frontProxyIntCA="kubernetes-front-proxy-ca"

kubeEtcdServer="kube-etcd"
kubeEtcdPeerServer="kube-etcd-peer"
kubeApiServer="kube-apiserver"

kubeEtcdHealthClient="kube-healthcheck-client"
kubeApiServerEtcdClient="kube-apiserver-etcd-client"
kubeApiServerKubletClient="kube-apiserver-kubelet-client"
frontProxyClient="front-proxy-client"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# For ease of testing these keys don't have a password, don't do this for real
function GeneratePrivateKey {
  echo "---------- Generating private key for $1 under $2 ----------"
  openssl genrsa -out $2/private/$1.key -passout pass: 4096
}

function GenerateCsr {
  echo "---------- Generating CSR for $1 under $2 ----------"

  K8_CA_NAME=$2 K8_SAN=$4 openssl req \
    -config openssl.cnf \
    -key $2/private/$1.key \
    -outform PEM -out $2/csr/$1.csr \
    -new -sha256 -subj "/CN=$1"
}

function SignCsr {
  echo "---------- $2 signing $1.csr ----------"
  K8_CA_NAME=$2 K8_SAN=$5 openssl ca \
    -config openssl.cnf -batch \
    -in $2/csr/$1.csr -out $2/certs/$1.crt \
    -days $4 -extensions $3 -notext -md sha256
}

function SetupCaDirectory {
  mkdir -p $1/certs $1/crl $1/newcerts $1/private $1/csr
  chmod 700 $1/private
  touch $1/index
  echo 1000 > $1/serial
  echo 1000 > $1/crlnumber
}

function CollectKeyMat {
  mv $2/private/$1.key $1/private/
  mv $2/certs/$1.crt $1/certs
  cat $1/certs/$1.crt $2/certs/$2.crt > $1/certs/chain.crt
}

function CreateCA {
  echo "---------- Creating $1 CA ----------"

  SetupCaDirectory $1
  GeneratePrivateKey $1 $1 

  K8_CA_NAME=$1 K8_SAN="dummy" openssl req \
    -config openssl.cnf \
    -key $1/private/$1.key \
    -outform PEM -out $1/certs/$1.crt \
    -new -x509 -days 3650 -subj "/CN=$1" -extensions v3_ca
}

function CreateCert {
  echo "---------- Creating cert $1 ----------"
  GeneratePrivateKey $1 $2
  GenerateCsr $1 $2 $3
  SignCsr $1 $2 $3 $4 $5
}

function CreateIntermediateCA {
  echo "---------- Creating intermediate CA $1 ----------"

  SetupCaDirectory $1
  CreateCert $1 $rootCA v3_intermediate_ca 1825
  CollectKeyMat $1 $rootCA 
}


# -----------------------------------------------------------------------------
# Script
# -----------------------------------------------------------------------------

CreateCA $rootCA

CreateIntermediateCA $kubeIntCA
CreateIntermediateCA $etcdIntCA       $rootCA
CreateIntermediateCA $frontProxyIntCA $rootCA

CreateCert $kubeApiServer $kubeIntCA "server" 365 "IP:127.0.0.1,DNS:localhost"
CreateCert $kubeEtcdServer $etcdIntCA "server" 365 "IP:127.0.0.1,DNS:localhost"
CreateCert $kubeEtcdPeerServer $etcdIntCA "server" 365 "IP:127.0.0.1,DNS:localhost"

CreateCert $kubeEtcdHealthClient      $etcdIntCA       "client" 365
CreateCert $kubeApiServerEtcdClient   $etcdIntCA       "client" 365
CreateCert $kubeApiServerKubletClient $kubeIntCA       "client" 365
CreateCert $frontProxyClient          $frontProxyIntCA "client" 365
