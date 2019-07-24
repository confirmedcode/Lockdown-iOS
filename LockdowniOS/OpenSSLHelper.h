//
//  helper.h
//  Confirmed VPN
//
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

#ifndef helper_h
#define helper_h

int processP12(const char *p12Data, int p12DataLength, unsigned char **caCert, unsigned int *caCertLength, unsigned char **clCert, unsigned int *clCertLength, unsigned char **privateKey, unsigned int *privateKeyLength);

#endif /* helper_h */
