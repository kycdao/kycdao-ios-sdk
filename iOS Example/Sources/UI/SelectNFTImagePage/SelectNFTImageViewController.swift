//
//  SelectNFTImageViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 18..
//

import Foundation
import UIKit
import WalletConnectSwift
import web3
import KycDao

class SelectNFTImageViewController: UIViewController, UIScrollViewDelegate {
    
    let containerView = UIView()
    let imageTitle = UILabel()
    let pageControl = UIPageControl()
    let svgWebView1 = NFTPreviewImage()
    let svgWebView2 = NFTPreviewImage()
    let svgWebView3 = NFTPreviewImage()
    let scrollView = UIScrollView()
    let scrollContentView = UIView()
    let selectNFTButton = SimpleButton()
    
    private var walletSession: WalletConnectSession
    private var verificationSession: VerificationSession
    private var nftImages: [TokenImage] = []
    private let membershipDuration: UInt32
    
    init(walletSession: WalletConnectSession, verificationSession: VerificationSession, membershipDuration: UInt32) {
        self.walletSession = walletSession
        self.verificationSession = verificationSession
        self.membershipDuration = membershipDuration
        super.init(nibName: nil, bundle: nil)
        
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray5
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageChanged()
        
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        Task { @MainActor in
            do {
                
                nftImages = verificationSession.getNFTImages()
                
                guard nftImages.count >= 3 else { throw KycDaoError.genericError }
                
                let nftImage1 = nftImages[0]
                let nftImage2 = nftImages[1]
                let nftImage3 = nftImages[2]
                
                svgWebView1.setImageURL(imageURL: nftImage1.url)
                svgWebView2.setImageURL(imageURL: nftImage2.url)
                svgWebView3.setImageURL(imageURL: nftImage3.url)
                
            } catch {
                print("Failed to receive NFT image")
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        imageTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        
        containerView.clipsToBounds = true
        
        scrollView.bounces = false
        scrollView.alwaysBounceHorizontal = true
        
        scrollView.clipsToBounds = false
        scrollContentView.clipsToBounds = false
        
        containerView.addSubview(imageTitle)
        containerView.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        containerView.addSubview(pageControl)
        view.addSubview(containerView)
        scrollContentView.addSubview(svgWebView1)
        scrollContentView.addSubview(svgWebView2)
        scrollContentView.addSubview(svgWebView3)
        containerView.addSubview(selectNFTButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        svgWebView1.translatesAutoresizingMaskIntoConstraints = false
        svgWebView2.translatesAutoresizingMaskIntoConstraints = false
        svgWebView3.translatesAutoresizingMaskIntoConstraints = false
        imageTitle.translatesAutoresizingMaskIntoConstraints = false
        selectNFTButton.translatesAutoresizingMaskIntoConstraints = false
        
        let spacingQuarter = (UIScreen.main.bounds.width - UIScreen.main.bounds.width * 0.8) / 4
        let spacingSixteenth = (UIScreen.main.bounds.width - UIScreen.main.bounds.width * 0.8) / 16
        
        NSLayoutConstraint.activate([
            
            imageTitle.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageTitle.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            imageTitle.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: imageTitle.bottomAnchor, constant: 32),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacingSixteenth * 7),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacingQuarter * 2),
            scrollView.heightAnchor.constraint(equalTo: scrollContentView.heightAnchor),
            
            scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 18),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            pageControl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: pageControl.size(forNumberOfPages: 3).height),
            pageControl.widthAnchor.constraint(equalToConstant: pageControl.size(forNumberOfPages: 3).width),
            
            svgWebView1.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            svgWebView1.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: spacingSixteenth),
            svgWebView1.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor),
            svgWebView1.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - spacingQuarter * 4),
            
            svgWebView2.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            svgWebView2.leadingAnchor.constraint(equalTo: svgWebView1.trailingAnchor, constant: spacingSixteenth),
            svgWebView2.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor),
            svgWebView2.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - spacingQuarter * 4),
            
            svgWebView3.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            svgWebView3.leadingAnchor.constraint(equalTo: svgWebView2.trailingAnchor, constant: spacingSixteenth),
            svgWebView3.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor),
            svgWebView3.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -spacingSixteenth),
            svgWebView3.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - spacingQuarter * 4),
            
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            selectNFTButton.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 32),
            selectNFTButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            selectNFTButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            selectNFTButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            selectNFTButton.heightAnchor.constraint(equalToConstant: 40),
            selectNFTButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            selectNFTButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        imageTitle.text = "Choose your kycDAO NFT"
        
        selectNFTButton.setTitle("Select", for: .normal)
        selectNFTButton.addTarget(self, action: #selector(selectNFTTap(_:)), for: .touchUpInside)
        
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        pageControl.transform = CGAffineTransform(scaleX: 2, y: 2)
        
        svgWebView2.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        svgWebView3.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
    }
    
    @objc func selectNFTTap(_ sender: Any) {
        
        Task {
            
            if nftImages.count >= pageControl.currentPage {
                let selectedImage = nftImages[pageControl.currentPage]
                Page.currentPage.send(.authorizeMinting(walletSession: walletSession,
                                                        verificationSession: verificationSession,
                                                        selectedImage: selectedImage,
                                                        membershipDuration: membershipDuration))
            }
            
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        transformNFTPreviews()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = Int(currentPage)
        pageChanged()
        transformNFTPreviews()
    }
    
    @objc func changePage() {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x:x, y:0), animated: true)
        pageChanged()
    }
    
    private func pageChanged() {
        
        if #available(iOS 14.0, *) {
        
            let notSelectedImage = UIImage(systemName: "circle")
            let selectedImage = UIImage(systemName: "checkmark.circle.fill")
            
            (0..<pageControl.numberOfPages).forEach { page in
                if page == pageControl.currentPage {
                    pageControl.setIndicatorImage(selectedImage, forPage: page)
                } else {
                    pageControl.setIndicatorImage(notSelectedImage, forPage: page)
                }
            }
        }
        
    }
    
    private func viewForPage(page: Int) -> UIView? {
        switch page {
        case 0:
            return svgWebView1
        case 1:
            return svgWebView2
        case 2:
            return svgWebView3
        default:
            return nil
        }
    }
    
    private func transformNFTPreviews() {
        let currentScroll = scrollView.contentOffset.x / scrollView.frame.size.width
        var currentPage = pageControl.currentPage
        
        //Correcting currentPage when fast scrolling
        if CGFloat(currentPage + 1) <= currentScroll {
            currentPage = Int(floor(currentScroll))
        } else if CGFloat(currentPage - 1) >= currentScroll {
            currentPage = Int(ceil(currentScroll))
        }
        
        if CGFloat(currentPage) < currentScroll {
        
            let nextPage = currentPage + 1
            let currentProgressFrom = currentScroll - CGFloat(currentPage)
            let currentProgressTo = CGFloat(nextPage) - currentScroll
            
            let scaleFrom = 1 - (1 - 0.9) * currentProgressFrom
            let scaleTo = 1 - (1 - 0.9) * currentProgressTo
            
            viewForPage(page: currentPage)?.transform = CGAffineTransform(scaleX: scaleFrom, y: scaleFrom)
            viewForPage(page: nextPage)?.transform = CGAffineTransform(scaleX: scaleTo, y: scaleTo)
            
            (0..<pageControl.numberOfPages).forEach { page in
                if page != currentPage && page != nextPage {
                    viewForPage(page: page)?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            }
            
        } else {
            
            let previousPage = currentPage - 1
            let currentProgressFrom = CGFloat(currentPage) - currentScroll
            let currentProgressTo = currentScroll - CGFloat(previousPage)
            
            let scaleFrom = 1 - (1 - 0.9) * currentProgressFrom
            let scaleTo = 1 - (1 - 0.9) * currentProgressTo
            
            viewForPage(page: currentPage)?.transform = CGAffineTransform(scaleX: scaleFrom, y: scaleFrom)
            viewForPage(page: previousPage)?.transform = CGAffineTransform(scaleX: scaleTo, y: scaleTo)
            
            (0..<pageControl.numberOfPages).forEach { page in
                if page != currentPage && page != previousPage {
                    viewForPage(page: page)?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            }
        }
    }
}


