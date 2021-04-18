#/bin/bash
certs_dir="/etc/pki_1/"
home_dir=$(pwd)

value_subj="/C=RU/ST=Moscow\
/L=Moscow/O=InfoWatch\
/OU=IT/CN=?\
/emailAddress=support@demo.lab"

value_SAN="DNS:?,DNS:?.demo.lab,email:support@demo.lab"

if ! [[ -d $certs_dir ]]; then
  mkdir -p $certs_dir
  cd $certs_dir
else
  echo "directory exists"
  exit 1
fi

create_certificate () {
  export SAN=${value_SAN//\?/${2}}
  
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

certs=(CA intermediate iwtm demolab)

for cert in ${certs[@]}; do
	work_dir="$(pwd)/${cert}"
	
	mkdir $work_dir && cd $work_dir
	cp ${home_dir}/openssl.cnf .
	create_files
	openssl genrsa -out private.pem &> /dev/null
	
	if [[ $cert = "CA" ]]; then
		create_certificate "v3_ca" "CA" "-x509"
	elif [[ $cert = "intermediate" ]]; then
		create_certificate "v3_intermediate_ca" "intermediate" "-new"
		cd ../CA
		sign_certificate "v3_intermediate_ca"
	elif [[ $cert = "iwtm" ]]; then
		create_certificate "server_cert" $cert "-new"
		cd ../intermediate
		sign_certificate "server_cert"
	else
		create_certificate "usr_cert" $cert "-new"
		cd ../intermediate
		sign_certificate "usr_cert"
	fi
	
	cd $certs_dir
	
done
