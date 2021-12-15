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
		+ usr_cert
    + subj - specifying the values of the certificate subject fields
    + key - path to private key
    + out - path where to save the request
+ ca
    + config - specifies the config file to use
    + extensions:
        + v3_ca
        + v3_intermediate_ca
        + server_cert
		+ usr_cert
    + in - request for signing
    + out - path where to save the signed certificate    

## Sample script    
Often, to quickly generate a large number of certificates, it would be much more reasonable to use a self-written script. Here is a small example of generating a root certificate.    
```bash
#/bin/bash
certs_dir="/etc/pki/"
home_dir=$(pwd)

value_subj="/C=RU/ST=Moscow\
/L=Moscow/O=WunderWafli\
/OU=IT/CN=?\
/emailAddress=your@mail.com" #!

if ! [[ -d $certs_dir ]]; then
  mkdir -p $certs_dir
  cd $certs_dir
else
  echo "directory exists"
  exit 1
fi

param777315="[a-zA-Z]{3}-((([0-9]|\d{2}|[1245]\d{2}|3([02-9]\d|1[0-46-9]))-[А-ЯЁ]{1,3})|([689]\d{2}|7([0-68-9]\d|7[0-68-9])|1000)-\d{2})"

paramDate31="(0[1-9]|[12]\d|3[01])\.(0[13578]|10)\.(19|2[01])"
paramDate30="(0[1-9]|[12]\d|30)\.(0[469]|11)\.(19|2[01])"

paramFebrual="(0[1-9]|1\d|2[0-8])\.02\.(19|21)|(0[1-9]|[12]\d)\.02\.20"

paramDecabr="(1[6-9]|2\d|3[01])\.12\.18|(0[1-9]|1[0-46-9]|2\d|3[01])\.12\.(19|20)|(0[1-9]|1[0-4])\.12\.21"

paramAllData1="Дата:\s?((0[1-9]|[12]\d|3[01])\.(0[13578]|10)\.(19|2[01])|(0[1-9]|[12]\d|30)\.(0[469]|11)\.(19|2[01])|(0[1-9]|1\d|2[0-8])\.02\.(19|21)|(0[1-9]|[12]\d)\.02\.20|(1[6-9]|2\d|3[01])\.12\.18|(0[1-9]|1[0-46-9]|2\d|3[01])\.12\.(19|20)|(0[1-9]|1[0-4])\.12\.21)"

paraAllData2="(0[1-9]|[12]\d|3[01])\.(0[13578]|10)\.20(19|2[01])|(0[1-9]|[12]\d|30)\.(0[469]|11)\.20(19|2[01])|(0[1-9]|1\d|2[0-8])\.02\.20(19|21)|(0[1-9]|[12]\d)\.02\.2020|(1[6-9]|2\d|3[01])\.12\.2018|(0[1-9]|1[0-46-9]|2\d|3[01])\.12\.20(19|20)|(0[1-9]|1[0-4])\.12\.2021"


create_certificate () {
  export SSLSAN="email:your@mail.com,DNS:${2},DNS:${2}.mail.com" #!
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

create_files () {
  mkdir crl certs requests newcerts
  touch index.txt index.txt.attr
  echo 01 > serial
}

 #!

for cert in ${certs[@]}
do
  work_dir="$(pwd)/${cert}"
  mkdir $work_dir && cd $work_dir
  cp ${home_dir}/openssl.cnf .
  create_files
  openssl genrsa -out private.pem &> /dev/null

  if [[ $cert == "CA" ]]; then
    create_certificate "v3_ca" "CA" "-x509"
  elif [[ $cert == "intermediate" || $cert == "squid" ]]; then
    create_certificate "v3_intermediate_ca" ${cert} "-new"
    cd ../CA
    sign_certificate "v3_intermediate_ca"
  else
    create_certificate "server_cert" ${cert} "-new"
    cd ../intermediate
    sign_certificate "server_cert"
  fi

  cd $certs_dir
done
```
