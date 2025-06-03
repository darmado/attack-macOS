# Error Reference

### Overview
This document lists status codes and error messages for Apple devices and services, focusing on CSSM (Common Security Services Manager) errors. These codes are from an older version of macOS and may not be fully applicable to macOS 13 and above.

##

### Purpose
This error reference aims to:
1. Describe error codes clearly and concisely.
2. Link error codes to official Apple Developer documentation where possible.
3. Help developers quickly diagnose and solve issues, especially when working with older systems or legacy code.

##

### Assumptions
- This list is based on CSSM version 57336.1.9, which is not current for modern macOS versions (13+).
- These codes may not be fully applicable or documented in current Apple systems.
- Some codes may have different meanings or be deprecated in newer versions of macOS.

##

## CSSM Error Reference

| Status Code | Error Constant | Description |
|-------------|----------------|-------------|
| 0 | - | Success – The operation was successful. |
| -67000 | CSSMERR_TP_CERT_REVOKED | Certificate has been revoked. |
| -67001 | CSSMERR_TP_CERT_SUSPENDED | Certificate is temporarily invalid. |
| -67002 | CSSMERR_TP_CERT_EXPIRED | Certificate is expired. |
| -67003 | CSSMERR_TP_CERT_NOT_VALID_YET | Certificate is not yet valid. |
| -67004 | CSSMERR_TP_CERT_REQUIRED | Certificate is required. |
| -67005 | CSSMERR_TP_CERT_NOT_VALID_YET | Certificate is not yet valid. |
| -67006 | CSSMERR_TP_CERT_INVALID | Certificate is invalid. |
| -67007 | CSSMERR_TP_CERT_UNABLE_TO_CHECK_REVOCATION | Unable to check certificate revocation status. |
| -67008 | CSSMERR_TP_CERT_REVOCATION_STATUS_UNKNOWN | Certificate revocation status is unknown. |
| -67009 | CSSMERR_TP_CERT_REVOKED_REASON_UNSPECIFIED | Certificate was revoked for an unspecified reason. |
| -67010 | CSSMERR_TP_INVALID_CERTIFICATE | Certificate format or data is invalid. |
| -67011 | CSSMERR_TP_CERT_REVOKED | Certificate has been revoked. |
| -67012 | CSSMERR_TP_CERT_POLICY_FAIL | Certificate does not meet policy requirements. |
| -67013 | CSSMERR_TP_CERTIFICATE_CANT_VERIFY | Certificate cannot be verified. |
| -67014 | CSSMERR_TP_CERTIFICATE_UNKNOWN | Certificate is unknown to the verifier. |
| -67015 | CSSMERR_TP_CERT_INVALID_POLICY_IDENTIFIERS | Certificate has invalid policy identifiers. |
| -67016 | CSSMERR_TP_NOT_TRUSTED | Certificate is not trusted by the system. |
| -67017 | CSSMERR_TP_TRUST_SETTING_DISALLOWS | Trust setting does not allow validation. |
| -67018 | CSSMERR_TP_INVALID_ANCHOR_CERT | Invalid anchor certificate. |
| -67019 | CSSMERR_TP_INVALID_POLICY_CONSTRAINTS | Invalid policy constraints. |
| -67020 | CSSMERR_TP_INVALID_NAME_CONSTRAINTS | Invalid name constraints. |
| -67021 | CSSMERR_TP_INVALID_BASIC_CONSTRAINTS | Invalid basic constraints. |
| -67022 | CSSMERR_TP_INVALID_AUTHORITY_KEY_ID | Invalid authority key identifier. |
| -67023 | CSSMERR_TP_INVALID_SUBJECT_KEY_ID | Invalid subject key identifier. |
| -67024 | CSSMERR_TP_INVALID_KEY_USAGE | Invalid key usage. |
| -67025 | CSSMERR_TP_INVALID_EXTENDED_KEY_USAGE | Invalid extended key usage. |
| -67026 | CSSMERR_TP_INVALID_ID_LINKAGE | Invalid ID linkage. |
| -67027 | CSSMERR_TP_PATH_LEN_CONSTRAINT | Path length constraint violated. |
| -67028 | CSSMERR_TP_INVALID_ROOT | Invalid root certificate. |
| -67029 | CSSMERR_TP_NAME_CONSTRAINTS_VIOLATED | Name constraints violated. |
| -67030 | CSSMERR_TP_CERT_CHAIN_TOO_LONG | Certificate chain is too long. |
| -67031 | CSSMERR_TP_INVALID_EXTENSION | Invalid certificate extension. |
| -67032 | CSSMERR_TP_INVALID_POLICY_MAPPING | Invalid policy mapping. |
| -67033 | CSSMERR_TP_INVALID_POLICY_CONSTRAINTS | Invalid policy constraints. |
| -67034 | CSSMERR_TP_INVALID_SUBJECT_ALT_NAME | Invalid subject alternative name. |
| -67035 | CSSMERR_TP_INCOMPLETE_REVOCATION_CHECK | Revocation check incomplete; certificate status unknown. |
| -67036 | CSSMERR_TP_NETWORK_FAILURE | Network failure during certificate verification. |
| -67037 | CSSMERR_TP_OCSP_UNAVAILABLE | OCSP service is unavailable. |
| -67038 | CSSMERR_TP_OCSP_BAD_RESPONSE | Bad OCSP response. |
| -67039 | CSSMERR_TP_OCSP_STATUS_UNRECOGNIZED | Unrecognized OCSP status. |
| -67040 | CSSMERR_TP_OCSP_NOT_TRUSTED | OCSP response is not trusted. |
| -67041 | CSSMERR_TP_OCSP_INVALID_SIGNATURE | Invalid OCSP response signature. |
| -67042 | CSSMERR_TP_OCSP_NONCE_MISMATCH | OCSP nonce mismatch. |
| -67043 | CSSMERR_TP_OCSP_SERVER_ERROR | OCSP server error. |
| -67044 | CSSMERR_TP_OCSP_REQUEST_NEEDS_SIG | OCSP request needs signature. |
| -67045 | CSSMERR_TP_OCSP_UNAUTHORIZED_REQUEST | Unauthorized OCSP request. |
| -67046 | CSSMERR_TP_OCSP_UNKNOWN_RESPONSE_STATUS | Unknown OCSP response status. |
| -67047 | CSSMERR_TP_OCSP_UNKNOWN_CERT | Unknown certificate in OCSP response. |
| -67048 | CSSMERR_TP_OCSP_INVALID_CERT_STATUS | Invalid certificate status in OCSP response. |
| -67049 | CSSMERR_TP_OCSP_INVALID_TIME | Invalid time in OCSP response. |
| -67050 | CSSMERR_TP_NOT_TRUSTED | Signature is untrusted or invalid. |
| -67051 | CSSMERR_TP_INVALID_CRL | Invalid CRL. |
| -67052 | CSSMERR_TP_CRL_EXPIRED | CRL has expired. |
| -67053 | CSSMERR_TP_CRL_NOT_VALID_YET | CRL is not yet valid. |
| -67054 | CSSMERR_TP_CERT_EXPIRED | The signing certificate has expired. |
| -67055 | CSSMERR_TP_CRL_NOT_FOUND | CRL not found. |
| -67056 | CSSMERR_TP_CRL_SERVER_DOWN | CRL server is down. |
| -67057 | CSSMERR_TP_CRL_BAD_URI | Bad CRL URI. |
| -67058 | CSSMERR_TP_UNKNOWN_CERT_AUTHORITY | Unknown certificate authority. |
| -67059 | CSSMERR_TP_UNKNOWN_SIGNER | Unknown signer. |
| -67060 | CSSMERR_TP_CERT_BAD_ACCESS_LOCATION | Bad certificate access location. |
| -67061 | CSSMERR_TP_UNKNOWN | A general or unspecified error occurred with the trust policy. |
| -67062 | CSSMERR_TP_INCOMPLETE | The operation is incomplete due to missing data or resources. |
| -67063 | CSSMERR_TP_INVALID_POLICY_MAPPING | Invalid policy mapping. |
| -67064 | CSSMERR_TP_INVALID_POLICY_CONSTRAINTS | Invalid policy constraints. |
| -67065 | CSSMERR_TP_INVALID_INHIBIT_ANY_POLICY | Invalid inhibit any policy. |
| -67066 | CSSMERR_TP_INVALID_SUBJECT_ALT_NAME | Invalid subject alternative name. |
| -67067 | CSSMERR_TP_INVALID_EMPTY_SUBJECT | Invalid empty subject. |
| -67068 | CSSMERR_TP_HOSTNAME_MISMATCH | The certificate hostname does not match the expected hostname. |
| -67069 | CSSMERR_TP_INVALID_POLICY_IDENTIFIERS | Invalid policy identifiers. |
| -67070 | CSSMERR_TP_INVALID_BASIC_CONSTRAINTS | Invalid basic constraints. |
| -67071 | CSSMERR_TP_INVALID_NAME_CONSTRAINTS | Invalid name constraints. |
| -67072 | CSSMERR_TP_CERTIFICATE_UNKNOWN | The certificate is unknown or unrecognized. |
| -67073 | CSSMERR_TP_VERIFY_ACTION_FAILED | Verification of the specified action failed. |
| -67074 | CSSMERR_TP_INVALID_CRL_DIST_POINT | Invalid CRL distribution point. |
| -67075 | CSSMERR_TP_INVALID_CRL_DIST_POINT_NAME | Invalid CRL distribution point name. |
| -67076 | CSSMERR_TP_INVALID_CRL_REASON | Invalid CRL reason. |
| -67077 | CSSMERR_TP_INVALID_CRL_ISSUER | Invalid CRL issuer. |
| -67078 | CSSMERR_TP_INVALID_ANCHOR_CERT | The anchor certificate is invalid or untrusted. |
| -67079 | CSSMERR_TP_INVALID_SIGNATURE | The certificate signature is invalid. |
| -67080 | CSSMERR_TP_NO_DEFAULT_KEYCHAIN | No default keychain is available for validation. |


## References

- [Apple Open Source: cssmerr.h](https://opensource.apple.com/source/Security/Security-57336.1.9/OSX/libsecurity_cssm/lib/cssmerr.h.auto.html)
- [Apple Developer Documentation: Security Framework](https://developer.apple.com/documentation/security)
