//
//  ViewController.swift
//  testewultra
//
//  Created by Aron Uchoa Bruno on 21/01/22.
//

import UIKit
import WultraSSLPinning

class ViewController: UIViewController {
    
    var session = URLSession.shared
    var dataTask: URLSessionDataTask?
    
    var certStore: CertStore? = nil
    
    override func viewWillAppear(_ animated: Bool) {
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        doRequest()
    }
    
    func buildCert() {
        let configuration = CertStoreConfiguration(
            serviceUrl: URL(string: "https://gist.githubusercontent.com/hvge/7c5a3f9ac50332a52aa974d90ea2408c/raw/d2ea7150639e1269b9fd54a746e876fa35ed239c/ssl-pinning-signatures.json")!,
            publicKey: "BC3kV9OIDnMuVoCdDR9nEA/JidJLTTDLuSA2TSZsGgODSshfbZg31MS90WC/HdbU/A5WL5GmyDkE/iks6INv+XE=",
            useChallenge: false
        )
        self.certStore = CertStore.powerAuthCertStore(configuration: configuration)
    }

    func doRequest() {
        let sessionConfiguration = URLSessionConfiguration.default
        // disable the caching
        sessionConfiguration.urlCache = nil
        // initialize the URLSession
        self.session = URLSession(configuration: sessionConfiguration, delegate: ViewController(), delegateQueue: nil)
        dataTask?.cancel()
        // create a request with the given URL and initialize a URLSessionDataTask
        if let url = URL(string: "https://github.com") {
            dataTask = self.session.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil || data == nil {
                    print("Client error!")
                    print(error.debugDescription)
                }
                let requestResponse = response as? HTTPURLResponse
                if let response = requestResponse, (200...299).contains(response.statusCode) {
                    print("Suceess")
                } else {
                    if let requestResponse = requestResponse {
                        print("requestResponse")
//                        validateResult = (String(requestResponse.statusCode), "Server error!")
                    } else {
                        print("Server Error!")
//                        validateResult = ("000", "Server error!")
                    }
                }
            })
            dataTask?.resume()
        }
    }
    
    func validadeCert(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?)? {
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            guard let certStore = self.certStore else {
                disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
                credential = Optional.none
                return (disposition, credential)
            }
            certStore.update { (result, error) in
                if result == .ok {
                    // everything's OK,
                    // No action is required, or silent update was started
                } else if result == .storeIsEmpty {
                    // Update succeeded, but it looks like the remote list contains
                    // already expired fingerprints. The certStore will probably not be able
                    // to validate the fingerprints.
                } else {
                    // Other error. See `CertStore.UpdateResult` for details.
                    // The "error" variable is set in case of a network error.
                }
            }
            let validationResult = certStore.validate(challenge: challenge)
            switch validationResult {
            case .trusted:
                disposition = URLSession.AuthChallengeDisposition.useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                print("Cert Trusted")
            case .untrusted:
                disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
                credential = Optional.none
                print("Cert Untrusted")
            case .empty:
                disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
                credential = Optional.none
                print("Cert Empty")
            }
            return (disposition, credential)
        }
}

extension ViewController: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Entrou na session")
        buildCert()
        print(certStore)
        let dispositionAndCredential = self.validadeCert(challenge: challenge)
        completionHandler(dispositionAndCredential!.0, dispositionAndCredential?.1)
    }
}
