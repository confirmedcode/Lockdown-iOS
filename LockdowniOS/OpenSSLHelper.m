//
//  helper.c
//  
//
//

#include <stdio.h>
//#include <openssl/pkcs12.h>
#include <stdio.h>
#include <string.h>
//#include <openssl/err.h>

/*#include <openssl/evp.h>
#include <openssl/x509v3.h>
#include <openssl/bn.h>
#include <openssl/asn1.h>
#include <openssl/x509.h>
#include <openssl/x509_vfy.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/sha.h>*/

/*
#include <openssl/evp.h>
#include <openssl/pkcs12.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>
*/

/*
int processP12(const char *p12Data, int p12DataLength, unsigned char **caCert, unsigned int *caCertLength, unsigned char **clCert, unsigned int *clCertLength, unsigned char **privateKey, unsigned int *privateKeyLength) {
    PKCS12 *p12 = NULL;
    EVP_PKEY *pkey = EVP_PKEY_new();
    X509 *usercert = X509_new();
    STACK_OF(X509) * ca = NULL;
    
    //****************************
    // INITIALIZE OPENSSL
    //****************************
    if (OPENSSL_init_crypto(OPENSSL_INIT_ADD_ALL_DIGESTS
                           | OPENSSL_INIT_ADD_ALL_CIPHERS | OPENSSL_INIT_LOAD_CRYPTO_STRINGS | OPENSSL_INIT_LOAD_SSL_STRINGS, NULL) == 0) {
        return 1;
    }
    
    if (OPENSSL_init_ssl(0, NULL) == 0) {
        return 2;
    }
    
    //****************************
    // PROCESS & PARSE P12
    //****************************
    
    BIO *bp = NULL;
    bp = BIO_new(BIO_s_mem());
    BIO_write(bp, p12Data, p12DataLength);
    p12 = d2i_PKCS12_bio(bp, NULL);
    if (p12 == NULL) {
        return 4;
    }
    
    if (PKCS12_parse(p12, NULL, &pkey, &usercert, &ca) == 0) {
        return ERR_get_error();
    }
    
    //****************************
    // PROCESS CA CERT
    //****************************
    X509 *topX509 = sk_X509_pop(ca);
    
    do {
        unsigned char *x509Out = NULL;
        long x509Len = 0;
        BIO *caBio = NULL;
        caBio = BIO_new(BIO_s_mem());
        PEM_write_bio_X509(caBio, topX509);
        topX509 = sk_X509_pop(ca);
        x509Len = BIO_get_mem_data(caBio, &x509Out);
        
        if (x509Len == 0) {
            return 6;
        }
        
        *caCertLength = (unsigned int)x509Len;
        *caCert = x509Out;
        
    } while (topX509 != NULL);
    
    //****************************
    // PROCESS CL CERT
    //****************************
    /*unsigned char *x509Out = NULL;
    int x509Len = i2d_X509(usercert, &x509Out);*/
/*    unsigned char *x509Out = NULL;
    long x509Len = 0;
    BIO *clBio = NULL;
    clBio = BIO_new(BIO_s_mem());
    PEM_write_bio_X509(clBio, usercert);
    topX509 = sk_X509_pop(ca);
    x509Len = BIO_get_mem_data(clBio, &x509Out);
    if (x509Len == 0) {
        return 7;
    }
    *clCert = x509Out;
    *clCertLength = x509Len;
    
    //****************************
    // PROCESS PRIVATE KEY
    //****************************
    unsigned char *pkeyOut = NULL;
    BIO *privateBio = NULL;
    int privateLen = 0;
    privateBio = BIO_new(BIO_s_mem());
    
    PEM_write_bio_PrivateKey(privateBio, pkey, NULL, NULL, 0, NULL, NULL);
    privateLen = BIO_get_mem_data(privateBio, &pkeyOut);
    if (privateKey == 0) {
        return 8;
    }
    *privateKey = pkeyOut;
    *privateKeyLength = privateLen;
    
    return 0;
}
*/
