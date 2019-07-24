//
//  Auth.swift
//  Tunnels
//
//  Copyright © 2018 Confirmed, Inc. All rights reserved.
//
//  This class is a placeholder for adding an Openly Operated VPN for users that want additional privacy. All methods currently don't execute.

import Alamofire
import CocoaLumberjackSwift
import PromiseKit

//MARK: - COOKIE RETRIER
//should we re-do using promises?
class CookieHandler : RequestRetrier {
    
    static let cookieSemaphore = DispatchSemaphore(value: 1)
    static var cookieAuthenticated = false //use this variable to prevent multiple requests of re-auth if expired. Is it necessary?
    
    public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        
        completion(false, 0.0)
        return; //inactive for launch
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == Global.kInvalidAuth {
            DDLogWarn("401 response \(request.retryCount)")
            //for 401 (invalid login), re-sign in
            CookieHandler.cookieAuthenticated = false
            if request.retryCount < 3 {
                
                let delay = 0.1 //1.0 + pow(2.0, Double(request.retryCount)) //exponentially delay retry
                CookieHandler.cookieSemaphore.wait(timeout: DispatchTime.now() + 4)
                if CookieHandler.cookieAuthenticated {
                    CookieHandler.cookieSemaphore.signal()
                    completion(true, 0.1)
                    return
                }
                
                Auth.signInForCookie() { (status, code) in
                    CookieHandler.cookieSemaphore.signal()
                    if status {
                        completion(true, 0)
                        CookieHandler.cookieAuthenticated = true
                    }
                    else {
                        completion(true, delay)
                    }
                }
            }
            else {
                completion(false, 0.0)
            }
        } else {
            completion(false, 0.0) // don't retry other codes yet
        }
    }
}

class Auth: NSObject {
    
    public static var signInError = 0
    static var cookieQueue = OperationQueue.init()
    static let cookieSemaphore = DispatchSemaphore(value: 1)
    
    //MARK: - COOKIE METHODS
    /*
     * switch API version
     * primarily to cycle through deprecated API servers if primary one fails
     * need to clear p12 & User ID as they are API specific
     * when switching, always increases version of API & then reset (v1 -> v2 -> v3 -> v1)
     */
    public static func incrementAPIVersion() {
        
        return; //inactive for launch
        
        if Global.isVersion(version: .v1API) {
            UserDefaults.standard.set(APIVersionType.v2API, forKey: Global.kConfirmedAPIVersion)
            UserDefaults.standard.synchronize()
        }
        else if Global.isVersion(version: APIVersionType.v2API) {
            UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion)
            UserDefaults.standard.synchronize()
        }
        else {
            UserDefaults.standard.set(APIVersionType.v1API, forKey: Global.kConfirmedAPIVersion)
            UserDefaults.standard.synchronize()
        }
        
        NotificationCenter.post(name: .switchingAPIVersions)
        
        //clear defaults in case of a version API
        Global.keychain[Global.kConfirmedID] = nil
        Global.keychain[Global.kConfirmedP12Key] = nil
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Global.vpnSavedRegionKey)
        defaults.set(Global.vpnDomain, forKey: Global.kLastEnvironment)
        defaults.synchronize()
    }
    
    /*
     * accept headers from /signin response
     * return true if cookie headers are there
     * return false if cookie headers are absent
     * remove P12 & UserID in case there is an API version switch
     */
    public static func processCookiesForHeader(response : DataResponse<Any>) -> Bool {
        
        return false; //inactive for launch
        
        if let headerFields = response.response?.allHeaderFields as? [String: String],
            let URL = response.request?.url
        {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies(cookies, for: URL, mainDocumentURL: nil)
            
            //put in a method later
            Global.keychain[Global.kConfirmedID] = nil
            Global.keychain[Global.kConfirmedP12Key] = nil
            let defaults = UserDefaults.standard
            defaults.set(Global.vpnDomain, forKey: Global.kLastEnvironment)
            defaults.synchronize()
            
            return true
        }
        
        return false
    }
    
    public static func processPartnerCode() -> String? {
        
        return nil; //inactive for launch
        
        let pasteboard = UIPasteboard.general
        if let partnerCodeData = pasteboard.data(forPasteboardType: Global.kPartnerCodePasteboardType), let partnerCode = String.init(data: partnerCodeData, encoding: .utf8)
        {
            var components = partnerCode.split(separator: "-")
            if components.count == 3 && components[0] == Global.kConfirmedUniquePartnerCode { //check for Confirmed unique prefix
                Global.sharedUserDefaults().set(partnerCode, forKey: Global.kPartnerCodePasteboardType)
                Global.sharedUserDefaults().synchronize()
            }
        }
        
        if let partnerCode = Global.sharedUserDefaults().value(forKey: Global.kPartnerCodePasteboardType) as? String {
            var components = partnerCode.split(separator: "-")
            if components.count == 3 && components[0] == Global.kConfirmedUniquePartnerCode { //check for Confirmed unique prefix
                components.remove(at: 0)
                let output = components.joined(separator: "-")
                return output
            }
        }
        
        return nil
    }
    
    /*
     * /signin for cookie only returns 200 on success
     * reject promise for any other, pass error up
     * after successful cookie, test with get-key
     * need to separate V1 as it does not return JSON on success
     */
    public static func signInForCookieInternal(parameters : Dictionary<String, Any>) -> Promise<Bool> {
        
        return Promise.value(false); //inactive for launch
        
        let sessionManager = Alamofire.SessionManager.default
        sessionManager.retrier = nil
        Auth.clearCookies()
        
        var signinParams = parameters
        if let partnerCode = processPartnerCode() {
            signinParams["partner"] = partnerCode
        }
        
        return Promise { seal in
            sessionManager.request(Global.signinURL, method: .post, parameters : signinParams).responseJSON { response in
                switch response.result {
                case .success:
                    if response.response?.statusCode == 200 {
                        let serverResponse = processServerResponse(data: response.data)
                        if let eCode = serverResponse.code, eCode != 0 {
                            seal.reject(NSError.init(domain: "Sign In Error", code: eCode, userInfo:serverResponse.dictionary))
                        }
                        else if processCookiesForHeader(response: response) {
                            seal.fulfill(true) //credentials are valid without 401
                        }
                        else {
                            seal.reject(NSError.init(domain: "Sign In Error", code: Global.kInvalidAuth, userInfo: nil))
                        }
                    }
                    else {
                        let serverResponse = processServerResponse(data: response.data)
                        
                        if let eCode = serverResponse.code, eCode != 0 {
                            seal.reject(NSError.init(domain: "Sign In Error", code: eCode, userInfo: serverResponse.dictionary))
                        }
                        else if let respCode = response.response?.statusCode {
                            seal.reject(NSError.init(domain: "Sign In Error", code: respCode, userInfo: nil))
                        }
                        else {
                            seal.reject(NSError.init(domain: "Sign In Error", code: Global.kUnknownError, userInfo: nil))
                        }
                    }
                case .failure(let error):
                    
                    if Global.isVersion(version: .v1API) && processCookiesForHeader(response: response) { //deprecated V1 does not return valid JSON, so catch false positive error case here
                        seal.fulfill(true)
                        return
                    }
                    
                    if error is AFError, let statusCode = (error as! AFError).responseCode {
                        seal.reject(NSError.init(domain: "Sign In Error", code: statusCode, userInfo: nil))
                    }
                    else if error is NSError {
                        let statusCode = (error as NSError).code
                        seal.reject(NSError.init(domain: "Sign In Error", code: statusCode, userInfo: nil))
                    }
                    else {
                        seal.reject(NSError.init(domain: "Sign In Error", code: Global.kUnknownError, userInfo: nil))
                    }
                }
            }
        }
        
    }
    
    static func extractP12Cert() {
        
        return; //inactive for launch
        
        if let userP12B64 = Global.keychain[Global.kConfirmedP12Key],
            let p12Data = Data(base64Encoded: userP12B64)
        {
            let p12DataBytes = Int32(p12Data.count)
            p12Data.withUnsafeBytes({ (bytes: UnsafePointer<Int8>) -> Void in
                var caCert : UnsafeMutablePointer<UInt8>?
                var caCertLen : UInt32 = 0
                var clCert : UnsafeMutablePointer<UInt8>?
                var clCertLen : UInt32 = 0
                var privateKey : UnsafeMutablePointer<UInt8>?
                var privateKeyLength : UInt32 = 0
                
                //processP12(bytes, p12DataBytes, &caCert, &caCertLen, &clCert, &clCertLen, &privateKey, &privateKeyLength)
                
                let privateKeyString = String(cString: privateKey!)
                let caCertString = String(cString: caCert!)
                let clCertString = String(cString: clCert!)
                Global.keychain[Global.kConfirmedPrivateKey] = privateKeyString.trimAfterPhrase(phrase: "-----END PRIVATE KEY-----")
                Global.keychain[Global.kConfirmedCACertKey] = caCertString.trimAfterPhrase(phrase: "-----END CERTIFICATE-----")
                Global.keychain[Global.kConfirmedCLCertKey] = clCertString.trimAfterPhrase(phrase: "-----END CERTIFICATE-----")
            })
        }
        else {
            //unable to extract, force IPSEC
            Utils.setActiveProtocol(activeProtocol: IPSecV3.protocolName)
        }
    }
    /*
     * attempt /signin for supplied e-mail credentials (if inputted)
     * this is only from sign in, so no need to try other authentication
     * attempt /signin for saved email credentials (if available)
     * if this is 401, we should clear credentials
     * attempt /signin for receipt auth (if iOS & available)
     * fail only if all methods fail
     */
    public static func attemptAllAuthForVersion(email: String? = nil, password: String? = nil) -> Promise<Bool> {
        
        return Promise.value(false); //inactive for launch
        
        if let userEmail = email, let userPassword = password {
            return signInForCookieInternal(parameters: parametersForValues(email: userEmail, password: userPassword))
                .then { promise -> Promise<Bool> in
                    //save parameters
                    Global.keychain[Global.kConfirmedEmail] = userEmail
                    Global.keychain[Global.kConfirmedPassword] = userPassword
                    return Promise.value(promise)
            }
        }
        
        return firstly { () -> Promise<Bool> in //firstly try with supplied email/password
            if let userEmail = Global.keychain[Global.kConfirmedEmail], let userPassword = Global.keychain[Global.kConfirmedPassword] {
                DDLogInfo("Signing in with saved email: \(userEmail)")
                return signInForCookieInternal(parameters: parametersForValues(email: userEmail, password: userPassword))
            }
            else {
                throw NSError(domain: "Invalid credentials", code: 1, userInfo: nil)
            }
            }.recover { error -> Promise<Bool> in
                #if os(iOS)
                    if let receipt = Global.keychain[Global.kConfirmedReceiptKey], receipt.count > 10 {
                        DDLogInfo("Signing in with receipt")
                        return signInForCookieInternal(parameters: parametersForValues(platform: Global.kPlatformiOS, authType: Global.kPlatformiOS, authReceipt: receipt))
                    }
                    else {
                        throw NSError(domain: "error", code: (error as NSError)._code, userInfo: nil)
                    }
                #else
                    throw NSError(domain: "error", code: (error as NSError)._code, userInfo: nil)
                #endif
        }
    }
    
    /*
     * parent cookie retrieval method
     * check if cookie is available (from another thread) before requesting cookie
     * request is serial in operation queue to not have users help DDoS our server
     * attempt /signin for all possible credential methods
     * if fails, switch to alternative version API (will deprecate V1 soon) and try again
     * need to clear P12 & ID on API version switch
     */
    public static func signInForCookie(email: String? = nil, password: String? = nil, forceReceiptAuth: Bool? = false, cookieCallback: @escaping (_ status: Bool, _ errorCode: Int) -> Void) {
        
        cookieCallback(false, 0);
        return; //inactive for launch
        
        cookieQueue.maxConcurrentOperationCount = 1
        cookieQueue.addOperation {
            DDLogInfo("Signing in for cookie")
            Auth.cookieSemaphore.wait(timeout: DispatchTime.now() + 10) //rate limit sign in
            
            if hasCookie() {
                Auth.cookieSemaphore.signal()
                cookieCallback(true, 0)
                return
            }
            
            if email == nil || password == nil {
                //reset to v3 version for receipt only as they are universal
                UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion)
                UserDefaults.standard.synchronize()
            }
            
            
            //try active API version first
            attemptAllAuthForVersion(email: email, password: password)
                .recover { error -> Promise<Bool> in
                    let eCode = (error as NSError).code
                    if eCode == -1200 || eCode == -1001 || eCode == -1009 { //propagate bad Internet instead of switching API
                        return Promise.init(error: NSError.init(domain: (error as NSError).domain, code: Global.kInternetDownError, userInfo: nil))
                    }
                    if eCode == Global.kEmailNotConfirmed && !Global.isVersion(version: .v1API) { //don't switch API version on e-mail not confirmed if on V2 (V1 deprecated so no longer confirming accounts)
                        return Promise.init(error: NSError.init(domain: (error as NSError).domain, code: Global.kEmailNotConfirmed, userInfo: nil))
                    }
                    Auth.incrementAPIVersion()
                    return attemptAllAuthForVersion(email: email, password: password)
                }
                .recover { error -> Promise<Bool> in
                    let eCode = (error as NSError).code
                    if eCode == -1200 || eCode == -1001 || eCode == -1009 { //propagate bad Internet instead of switching API
                        return Promise.init(error: NSError.init(domain: (error as NSError).domain, code: Global.kInternetDownError, userInfo: nil))
                    }
                    if eCode == Global.kEmailNotConfirmed && !Global.isVersion(version: .v1API) { //don't switch API version on e-mail not confirmed if on V2 (V1 deprecated so no longer confirming accounts)
                        return Promise.init(error: NSError.init(domain: (error as NSError).domain, code: Global.kEmailNotConfirmed, userInfo: nil))
                    }
                    Auth.incrementAPIVersion()
                    return attemptAllAuthForVersion(email: email, password: password)
                }
                .done {_ in
                    Auth.cookieSemaphore.signal()
                    cookieCallback(true, 0)
                }
                .catch { error in //fallback to previous API version
                    let eCode = error as NSError
                    if error is AFError, let statusCode = (error as! AFError).responseCode, statusCode == Global.kInvalidAuth {
                        Global.keychain[Global.kConfirmedEmail] = nil
                        Global.keychain[Global.kConfirmedPassword] = nil
                    }
                    Auth.cookieSemaphore.signal()
                    cookieCallback(false, eCode.code) //invalid login
            }
        }
    }
    
    /*
     * method to check for cookie in local storage
     */
    public static func hasCookie() -> Bool {
        return false; //inactive for launch
        var hasCookie = false
        let cstorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage
        if let cookies = cstorage?.cookies {
            for cookie in cookies {
                if let timeUntilExpire = cookie.expiresDate?.timeIntervalSinceNow {
                    if !Global.isVersion(version: .v3API) && UserDefaults.standard.bool(forKey: Global.kIsOnFinalDeprecatedV1V2) {
                        if cookie.domain.contains("confirmedvpn.co") && timeUntilExpire > 120.0 {
                            hasCookie = true
                        }
                    }
                    
                    if cookie.domain.contains("confirmedvpn.com") && timeUntilExpire > 120.0 {
                        hasCookie = true
                    }
                }
            }
        }
        
        if !hasCookie {
            Auth.clearCookies()
        }
        
        return hasCookie
    }
    
    /*
     * method to check for cookie before every request
     * if has cookie, continue call
     * if no cookie, return cookie
     * if retrieved cookie, continue call
     * if no cookie, error out
     */
    public static func getCookie() -> Promise<Bool> {
        
        return Promise { seal in
            seal.fulfill(true)
            return; //inactive for launch
            if hasCookie() {
                seal.fulfill(true)
            }
            else {
                signInForCookie(cookieCallback: { (status, code) in
                    if status {
                        return seal.fulfill(true)
                    }
                    else {
                        seal.reject(NSError.init(domain: "Confirmed Error", code: code, userInfo: nil))
                    }
                })
            }
        }
    }
    
    //MARK: - CREATE USER (macOS only)
    public static func createUser(email : String, password : String, passwordConfirmation : String, createUserCallback: @escaping (_ status: Bool, _ reason: String, _ errorCode: Int) -> Void) {
        
        createUserCallback(false, "", 0)
        return; //inactive for launch
        
        UserDefaults.standard.set(APIVersionType.v3API, forKey: Global.kConfirmedAPIVersion) //force upgrade to latest API version on create user
        UserDefaults.standard.synchronize()
        NotificationCenter.post(name: .switchingAPIVersions)
        
        if let result = Utils.validateCredentialFormat(email: email, password: password, passwordConfirmation: passwordConfirmation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { //add delays to allow animation
                createUserCallback(false, result, Global.kRequestFieldValidationError)
            }
            return
        }
        
        let parameters: Parameters = parametersForValues(email: email, password: password, passwordConfirmation: passwordConfirmation)
        Alamofire.request(Global.createUserURL, method: .post, parameters : parameters).responseJSON { response in
            let serverResponse = processServerResponse(data: response.data)
            if let status = response.response?.statusCode, let eCode = serverResponse.code, status == 200, eCode == Global.kEmailNotConfirmed {
                DDLogInfo("User created")
                Global.keychain[Global.kConfirmedEmail] = email
                Global.keychain[Global.kConfirmedPassword] = password
                
                Auth.clearCookies()
                
                signInForCookie(email: email, password: password, cookieCallback: {(_ status: Bool, _ errorCode: Int) -> Void in
                    createUserCallback(status, "Unknown error.", errorCode)
                })
            }
            else if let eCode = serverResponse.code, eCode != 0 {
                signInError = eCode
                createUserCallback(false, serverResponse.message != nil ? serverResponse.message! : Global.errorMessageForError(eCode: Global.kUnknownError), eCode)
            }
            else {
                DDLogError("Error creating user")
                if let status = response.response?.statusCode {
                    signInError = status
                    createUserCallback(false, serverResponse.message != nil ? serverResponse.message! : Global.errorMessageForError(eCode: Global.kUnknownError), status)
                    return
                }
                else {
                    createUserCallback(false, Global.errorMessageForError(eCode: Global.kUnknownError), Global.kUnknownError)
                }
            }
        }
    }
    
    //MARK: - RECEIPT METHOD (iOS Only)
    /*
     * internal method for uploading receipt
     * contains actual call
     * upload latest receipt to server
     * enesures e-mail has latest receipt
     */
    public static func uploadNewReceipt(uploadReceiptCallback: @escaping (_ status: Bool, _ reason: String, _ errorCode: Int) -> Void) {
        
        return; //inactive for launch
        
        let sessionManager = Alamofire.SessionManager.default
        sessionManager.retrier = CookieHandler()
        var parameters: Parameters = parametersForValues(authType: Global.kPlatformiOS, authReceipt: Global.keychain[Global.kConfirmedReceiptKey] as String!)
        
        if Global.isVersion(version: .v1API) {
            parameters = parametersForValues(platform: Global.kPlatformiOS, receipt: Global.keychain[Global.kConfirmedReceiptKey] as String!)
        }
        
        getCookie()
            .then { promise in
                sessionManager.request(Global.subscriptionReceiptUploadURL, method: .post, parameters : parameters).validate().responseJSON()
            }
            .done { json, response in
                
                if response.response?.statusCode == 200 {
                    uploadReceiptCallback(true, "Success", 0)
                }
                else {
                    uploadReceiptCallback(false, "Unknown error", 1)
                    DDLogError("Error with upload: \(response.response?.statusCode)")
                }
            }
            .catch { error in
                if signInError == Global.kEmailNotConfirmed {
                    uploadReceiptCallback(false, Global.errorMessageForError(eCode: Global.kEmailNotConfirmed), Global.kEmailNotConfirmed)
                }
                else {
                    uploadReceiptCallback(false, Global.errorMessageForError(eCode: Global.kUnknownError), Global.kUnknownError)
                    signInError = Global.kUnknownError
                }
        }
    }
    
    //MARK: - ADD EMAIL METHODS (iOS Only)
    /*
     * method to add an e-mail to a user
     */
    public static func convertShadowUser(email : String, password : String, passwordConfirmation : String, createUserCallback: @escaping (_ status: Bool, _ reason: String) -> Void)  {
        
        return; //inactive for launch
        
        if let result = Utils.validateCredentialFormat(email: email, password: password, passwordConfirmation: passwordConfirmation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { //add delays to allow animation
                createUserCallback(false, result)
            }
            return
        }
        
        let parameters = parametersForValues(newEmail: email, newPassword: password)
        let sessionManager = Alamofire.SessionManager.default
        sessionManager.retrier = CookieHandler()
        let waitAtLeast = after(seconds: 1.0)
        
        getCookie()
            .then { promise in
                sessionManager.request(Global.addEmailToUserURL, method: .post, parameters : parameters).responseJSON()
            }
            .then { json, response in
                waitAtLeast.then { return Promise<(json: Any, response: PMKAlamofireDataResponse)>.value((json, response)) }
            }
            .done { json, response in
                let serverResponse = processServerResponse(data: response.data)
                if response.response?.statusCode == 200 && serverResponse.code == Global.kEmailNotConfirmed {
                    Global.keychain[Global.kConfirmedEmail] = email
                    Global.keychain[Global.kConfirmedPassword] = password
                    
                    getKey(callback: {(_ status: Bool, _ reason: String, _errorCode: Int) -> Void in
                        createUserCallback(true, "")
                    })
                }
                else {
                    DDLogError("Response \(String(describing: String.init(data: response.data!, encoding: .utf8)))")
                    
                    if let eCode = serverResponse.code {
                        switch eCode {
                        case Global.kEmailAlreadyUsed:
                            createUserCallback(false, Global.errorMessageForError(eCode: eCode))
                        case Global.kReceiptAlreadyUsed:
                            createUserCallback(false, Global.errorMessageForError(eCode: eCode))
                        case Global.kRequestFieldValidationError:
                            createUserCallback(false, serverResponse.message ?? "Unknown error")
                        default:
                            createUserCallback(false, Global.errorMessageForError(eCode: eCode))
                            print("Unrecognized error")
                        }
                    }
                    else {
                        if let message = serverResponse.message {
                            createUserCallback(false, message)
                        }
                        else {
                            createUserCallback(false, Global.errorMessageForError(eCode: Global.kUnknownError))
                        }
                    }
                }
            }
            .catch { error in
                if signInError == Global.kEmailNotConfirmed {
                    createUserCallback(false, Global.errorMessageForError(eCode: Global.kEmailNotConfirmed))
                }
                else {
                    createUserCallback(false, Global.errorMessageForError(eCode: Global.kUnknownError))
                    signInError = Global.kUnknownError
                }
        }
    }
    
    
    //MARK: - GET KEY METHODS
    /*
     * method to get b64 encoded p12 & user id
     */
    
    public static func getKey(callback: @escaping (_ status: Bool, _ reason: String, _ errorCode: Int) -> Void) {
        
        callback(false, "", 0);
        return; //inactive for launch
        let sessionManager = Alamofire.SessionManager.default
        sessionManager.retrier = CookieHandler()
        
        #if os(iOS)
            let parameters: Parameters = parametersForValues(platform: Global.kPlatformiOS, certSource: Utils.getSource())
        #else
            let parameters: Parameters = parametersForValues(platform: Global.kPlatformMac, certSource: Utils.getSource())
        #endif
        
        
        getCookie()
            .then { promise in
                sessionManager.request(Global.getKeyURL, method: .post, parameters : parameters).responseJSON()
            }
            .done { json, response in
                
                let resp = processServerResponse(data: response.data)
                
                if !Global.isVersion(version: APIVersionType.v3API) { //set for users who have the .co
                    UserDefaults.standard.set(true, forKey: Global.kIsOnFinalDeprecatedV1V2)
                    UserDefaults.standard.synchronize()
                }
                
                if response.response?.statusCode == 200, let userB64 = resp.b64, let userID = resp.id {
                    NotificationCenter.default.post(name: .userSignedIn, object: nil)
                    Global.keychain[Global.kConfirmedP12Key] = userB64
                    Global.keychain[Global.kConfirmedID] = userID
                    if Global.isVersion(version: .v3API) {
                        Auth.extractP12Cert()
                    }
                    signInError = Global.kNoError
                    callback(true, "", 0)
                }
                else if let errorCode = resp.code {
                    signInError = errorCode
                    callback(false, Global.errorMessageForError(eCode: errorCode), errorCode)
                }
                else if let code = response.response?.statusCode, code != 200 {
                    callback(false, Global.errorMessageForError(eCode: code), code)
                }
                else {
                    signInError = Global.kUnknownError
                    callback(false, Global.errorMessageForError(eCode: signInError), signInError)
                }
            }
            .catch { error in
                let eCode = (error as NSError).code
                if eCode == -1200 || eCode == -1001 || eCode == -1009 || eCode == -1004 { //propagate bad Internet instead of switching API
                    callback(false, error.localizedDescription, Global.kInternetDownError)
                    signInError = Global.kInternetDownError
                }
                else if eCode == Global.kEmailNotConfirmed {
                    callback(false, Global.errorMessageForError(eCode: Global.kEmailNotConfirmed), Global.kEmailNotConfirmed)
                }
                else {
                    callback(false, Global.errorMessageForError(eCode: Global.kUnknownError), signInError)
                    signInError = Global.kUnknownError
                }
        }
    }
    
    //MARK: - ACCOUNT INFORMATION METHODS
    /*
     * API to get subscription tier from server
     */
    public static func getActiveSubscriptions( callback: @escaping (_ status: Bool, _ didCompleteCall: Bool, _ reason: String, _ response : Array<Dictionary<String, Any>>?) -> Void) {
        
        callback(false, false, "", nil);
        return; //inactive for launch
        
        let sessionManager = Alamofire.SessionManager.default
        sessionManager.retrier = CookieHandler()
        
        getCookie()
            .then {_ in
                sessionManager.request(Global.activeSubscriptionInformationURL, method: .post).validate().responseJSON()
            }
            .done { json, response in
                if let sub = json as? Array<Dictionary<String, Any>>, !sub.isEmpty {
                    callback(true, true, "", sub)
                }
                else {
                    callback(false, false, "No active subscriptions.", nil)
                }
            }
            .catch { error in
                if signInError == Global.kEmailNotConfirmed {
                    callback(false, false, Global.errorMessageForError(eCode: Global.kEmailNotConfirmed), nil)
                }
                else {
                    callback(false, false, Global.errorMessageForError(eCode: Global.kUnknownError), nil)
                    signInError = Global.kUnknownError
                }
        }
    }
    
    
    //MARK: - CLEAR DATA METHODS
    
    /*
     * On signout, clear all keychain data, cookies, and turn VPN off
     * cycle through all API versions & clear data
     * clear v1/v2/v3 choice
     */
    public static func signoutUser() {
        return; //inactive for launch
        
        for i in 1...3 {
            
            Global.keychain[Global.kConfirmedEmail] = nil
            Global.keychain[Global.kConfirmedID] = nil
            Global.keychain[Global.kConfirmedP12Key] = nil
            Global.keychain[Global.kConfirmedPassword] = nil
            #if os(iOS)
                Global.keychain[Global.kConfirmedReceiptKey] = nil
                TunnelsSubscription.isSubscribed = .NotSubscribed
            #endif
            
            Auth.incrementAPIVersion() //switch to clear other API as well
        }
        
        UserDefaults.standard.removeObject(forKey:Global.kConfirmedAPIVersion)
        if let defaults = UserDefaults(suiteName: SharedUtils.userDefaultsSuite) {
            defaults.removeObject(forKey: Utils.kActiveProtocol)
            defaults.synchronize()
        }
        VPNController.shared.forceVPNOff()
        Auth.clearCookies()
    }
    
    /*
     * Clear out cookies from local storage
     * Clear cached responses (otherwise cookie response from server may be cached instead of re-generated)
     * This catches rare case of cookie being removed before expiration on server
     * Often used if sign in failed, can force regeneration of cookies
     */
    public static func clearCookies() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        
        if let cookieStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage {
            for cookie in cookieStorage.cookies ?? [] {
                cookieStorage.deleteCookie(cookie as HTTPCookie)
            }
        }
        
        let cstorage = HTTPCookieStorage.shared
        if let cookies = cstorage.cookies(for: URL.init(string: "confirmedvpn.com")!) {
            for cookie in cookies {
                cstorage.deleteCookie(cookie)
            }
        }
        
        //deprecated v1/v2 code
        if let cookies = cstorage.cookies(for: URL.init(string: "confirmedvpn.co")!) {
            for cookie in cookies {
                cstorage.deleteCookie(cookie)
            }
        }
        
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.removeCookies(since: Date.init(timeIntervalSinceNow: -1000))
        
        CookieHandler.cookieAuthenticated = false
    }
    
    
    //MARK: - HELPER FUNCTIONS
    
    /*
     * Single place for creating post data
     */
    private static func parametersForValues(email : String? = nil, password : String? = nil, passwordConfirmation : String? = nil, platform : String? = nil, authType : String? = nil, authReceipt : String? = nil, receipt : String? = nil, newEmail : String? = nil, newPassword : String? = nil, certSource : String? = nil) -> Parameters {
        var parameters: Parameters = [:]
        
        if email != nil { parameters["email"] = email }
        if password != nil { parameters["password"] = password }
        if passwordConfirmation != nil { parameters["passwordConfirmation"] = passwordConfirmation }
        if platform != nil { parameters["platform"] = platform }
        if authType != nil { parameters["authtype"] = authType }
        if authReceipt != nil { parameters["authreceipt"] = authReceipt }
        if receipt != nil { parameters["receipt"] = receipt }
        if newEmail != nil { parameters["newemail"] = newEmail }
        if newPassword != nil { parameters["newpassword"] = newPassword }
        if certSource != nil { parameters["source"] = certSource }
        
        return parameters
    }
    
    /*
     * Convert JSON to a structure
     */
    private static func processServerResponse(data : Data?) -> ServerResponse {
        if let serverData = data {
            let decoder = JSONDecoder()
            do {
                let resp = try decoder.decode(ServerResponse.self, from: serverData)
                return resp
            }
            catch let parsingError {
                print("Error", parsingError)
            }
        }
        
        let resp = ServerResponse.init(code: Global.kUnknownError, message: nil, b64: nil, id: nil)
        return resp
    }
}

