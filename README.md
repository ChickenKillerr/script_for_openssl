# Generating self-signed certificates    
## Openssl command and its parameters     
The openssl cryptographic library built into Linux has tools to generate RSA private keys and Certificate Singing Requests (CSRs), manage certificates, and perform encoding / decoding.    
To create certificates you need directories: `crl`, `certs`, `requests`, `newcerts`. And also the files `index.txt` and `index.txt.attr`. And another file `serial` with entry 01.    
We use the openssl utility to generate a key, request and sign certificates. To generate a key, there is a `genrsa` option, for a `req` request, for a signing `ca`.    

openssl:
+ genrsa
    + out - indicates the path to save the key
    + aes256 - encryption key
    + 4096 - key length
+ req
    + config - specifies the config file to use
    + new / x509 -  certificate for CA or not?
    + nodes - no encryption
    + extensions:
        + v3_ca
        + v3_intermediate_ca
        + server_cert
    + subj - specifying the values of the certificate subject fields
    + key - path to private key
    + out - path where to save the request
+ ca
    + config - specifies the config file to use
    + extensions:
        + v3_ca
        + v3_intermediate_ca
        + server_cert
    + in - request for signing
    + out - path where to save the signed certificate    

## Sample script    
Often, to quickly generate a large number of certificates, it would be much more reasonable to use a self-written script. Here is a small example of generating a root certificate.    
```bash
#/bin/bash
certs_dir="/etc/pki/"
home_dir=$(pwd)

value_subj="/C=RU/ST=Moscow\
/L=Moscow/O=InfoWatch\
/OU=IT/CN=?\
/emailAddress=name@your.domain"

if ! [[ -d $certs_dir ]]; then
  mkdir -p $certs_dir
  cd $certs_dir
fi

create_certificate () {

  openssl req \
    -config openssl.cnf \
    ${3} \
    -nodes \
    -extensions $1 \
    -subj ${value_subj/\?/${2}} \
    -key private.pem \
    -out public.pem
}

sign_certificate () {
  openssl ca \
    -config openssl.cnf \
    -notext \
    -extensions $1 \
    -in "${work_dir}/public.pem" \
    -out "${work_dir}/public.pem"
}


work_dir="$(pwd)/${cert}"

mkdir $work_dir && cd $work_dir
cp ${home_dir}/openssl.cnf .
openssl genrsa -out private.pem &> /dev/null

create_certificate "v3_ca" "CA" "-x509"

cd $certs_dir
```
