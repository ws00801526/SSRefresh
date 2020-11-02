//
//  Language.swift
//  SSRefresh
//
//  Created by XMFraker on 2020/10/19.
//

#if canImport(UIKit)

import UIKit

public class Language: RawRepresentable {
    public typealias RawValue = String
    public var rawValue: RawValue
    required public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public var type: String = "lproj"
}

public extension Language {

    static let system: Language                  = .init(rawValue: "system")
    static let english: Language                 = .init(rawValue: "en")
    static let japanses: Language                = .init(rawValue: "ja")

    static let korean: Language                  = .init(rawValue: "ko")
    static let chineseSimplified: Language       = .init(rawValue: "zh-Hans")
    static let chineseTraditional: Language      = .init(rawValue: "zh-Hant")
}

extension Language {
    public struct Key: RawRepresentable {
        public typealias RawValue = String
        public var rawValue: Key.RawValue
        public init(rawValue: Key.RawValue) {
            self.rawValue = rawValue
        }
        
        public var locaizedString: String {
            return Language.bundle.localizedString(forKey: rawValue, value: nil, table: nil)
        }
    }
}

public extension Language {
    static var languageBundleKey: Int = 100
    static func setPreferredLanguage(_ language: Language) {
        
        if language == .system {
            bundle =  Bundle(for: Language.self)
        } else {
            let theBundle =  Bundle(for: Language.self)
            guard let path = theBundle.path(forResource: language.rawValue, ofType: language.type) else { return }
            guard let newBundle = Bundle(path: path) else { return }
            bundle = newBundle
        }
    }
    
    static var bundle: Bundle {
        set {
            objc_setAssociatedObject(self, &languageBundleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let bundle = objc_getAssociatedObject(self, &languageBundleKey) as? Bundle { return bundle }
            let bundle =  Bundle(for: Language.self)
            objc_setAssociatedObject(self, &languageBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bundle
        }
    }
}

public extension Language.Key {
    static let HeaderIdleText: Language.Key = .init(rawValue: "下拉即可刷新数据")
    static let HeaderReadyText: Language.Key = .init(rawValue: "松开立即刷新")
    static let HeaderRefreshingText: Language.Key = .init(rawValue: "正在刷新数据中...")
    
    static let FooterIdleText: Language.Key = .init(rawValue: "上拉加载更多数据")
    static let FooterReadyText: Language.Key = .init(rawValue: "松开加载更多数据")
    static let FooterEmptyText: Language.Key = .init(rawValue: "已加载完所有数据")
    static let FooterRefreshingText: Language.Key = .init(rawValue: "正在加载更多数据...")
}


public extension UIScrollView {
    
    /// The contentInset of the scrollView, iOS 11+ use adjustedContentInset, other use contentInset
    var sr_contentInset: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return adjustedContentInset
        } else {
            return contentInset
        }
    }
}

#endif
