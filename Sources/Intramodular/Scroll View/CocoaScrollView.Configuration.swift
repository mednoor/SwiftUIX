//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if (os(iOS) && canImport(CoreTelephony)) || os(tvOS) || targetEnvironment(macCatalyst)

/// The properties of a `CocoaScrollView` instance.
public struct CocoaScrollViewConfiguration<Content: View>: ExpressibleByNilLiteral {
    var initialContentAlignment: Alignment?
    var axes: Axis.Set = [.vertical]
    var showsVerticalScrollIndicator: Bool = true
    var showsHorizontalScrollIndicator: Bool = true
    var scrollIndicatorInsets: (horizontal: EdgeInsets, vertical: EdgeInsets) = (.zero, .zero)
    var decelerationRate: UIScrollView.DecelerationRate = .normal
    var alwaysBounceVertical: Bool? = nil
    var alwaysBounceHorizontal: Bool? = nil
    var isDirectionalLockEnabled: Bool = false
    var isPagingEnabled: Bool = false
    var isScrollEnabled: Bool = true
    
    var scrollIndicatorScheme: UIScrollView.IndicatorStyle = .default
    var scrollToTop: Bool = true
    var bouncesZoom: Bool = false
    var scrollZoomScale: (minimum: CGFloat, maximum: CGFloat) = (1, 1)
    var panGestureRecognizer: (minNumberOfTouches: Int, maxNumberOfTouches: Int) = (1, Int.max)
    
    var onOffsetChange: ((ScrollView<Content>.ContentOffset) -> ())?
    var onDragEnd: (() -> Void)?
    var onZoom: ((_ zoomScale: CGFloat) -> Void)?
    var onZoomEnd: ((_ zoomScale: CGFloat) -> Void)?
    var contentOffset: Binding<CGPoint>? = nil
    var initialZoomScale: CGFloat = 1
    
    var contentInset: EdgeInsets = .zero
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior?
    var contentOffsetBehavior: ScrollContentOffsetBehavior = []
        
    var onRefresh: (() -> Void)?
    var isRefreshing: Bool?
    var refreshControlTintColor: UIColor?

    private var _keyboardDismissMode: Any?
    
    @available(tvOS, unavailable)
    var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get {
            _keyboardDismissMode.flatMap({ $0 as? UIScrollView.KeyboardDismissMode }) ?? .none
        } set {
            _keyboardDismissMode = newValue
        }
    }
    
    public init(nilLiteral: ()) {
        
    }
}

extension CocoaScrollViewConfiguration {
    mutating func update(from environment: EnvironmentValues) {
        if let initialContentAlignment = environment.initialContentAlignment {
            self.initialContentAlignment = initialContentAlignment
        }
        
        if !environment._isScrollEnabled {
            isScrollEnabled = false
        }
        
        #if os(iOS) || targetEnvironment(macCatalyst)
        contentInsetAdjustmentBehavior = environment.contentInsetAdjustmentBehavior
        keyboardDismissMode = environment.keyboardDismissMode
        #endif
        
        if let scrollIndicatorStyle = environment.scrollIndicatorStyle as?
            HiddenScrollViewIndicatorStyle {
            showsVerticalScrollIndicator = !scrollIndicatorStyle.vertical
            showsHorizontalScrollIndicator = !scrollIndicatorStyle.horizontal
        } else if let scrollIndicatorStyle = environment.scrollIndicatorStyle as? InsetScrollViewIndicatorStyle {
            scrollIndicatorInsets = scrollIndicatorStyle.insets
        } else if let scrollIndicatorStyle = environment.scrollIndicatorStyle as? SchemeScrollViewIndicatorStyle {
            scrollIndicatorScheme = scrollIndicatorStyle.style
        }
    }
}

// MARK: - Auxiliary

public struct ScrollContentOffsetBehavior: OptionSet {
    public static let maintainOnChangeOfBounds = Self(rawValue: 1 << 0)
    public static let maintainOnChangeOfContentSize = Self(rawValue: 1 << 1)
    public static let maintainOnChangeOfKeyboardFrame = Self(rawValue: 1 << 2)
    public static let smartAlignOnChangeOfContentSize = Self(rawValue: 1 << 3)
    
    public let rawValue: Int8
    
    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }
}

extension UIScrollView {
    var isScrolling: Bool {
        layer.animation(forKey: "bounds") != nil
    }
    
    func configure<Content: View>(
        with configuration: CocoaScrollViewConfiguration<Content>
    ) {
        if configuration.axes != [.vertical] {
            if configuration.axes == [.horizontal] {
                _assignIfNotEqual(true, to: \.isDirectionalLockEnabled)
            }
        } else {
            _assignIfNotEqual(false, to: \.isDirectionalLockEnabled)
        }
        
        if let alwaysBounceVertical = configuration.alwaysBounceVertical {
            _assignIfNotEqual(alwaysBounceVertical, to: \.alwaysBounceVertical)
        }
        
        if let alwaysBounceHorizontal = configuration.alwaysBounceHorizontal {
            _assignIfNotEqual(alwaysBounceHorizontal, to: \.alwaysBounceHorizontal)
        }
           
        if alwaysBounceVertical || alwaysBounceHorizontal {
            bounces = true
        } else if !alwaysBounceVertical && !alwaysBounceHorizontal {
            bounces = false
        }
        
        _assignIfNotEqual(configuration.isDirectionalLockEnabled, to: \.isDirectionalLockEnabled)
        _assignIfNotEqual(configuration.isScrollEnabled, to: \.isScrollEnabled)
        _assignIfNotEqual(configuration.showsVerticalScrollIndicator, to: \.showsVerticalScrollIndicator)
        _assignIfNotEqual(configuration.showsHorizontalScrollIndicator, to: \.showsHorizontalScrollIndicator)
        _assignIfNotEqual(.init(configuration.scrollIndicatorInsets.horizontal), to: \.horizontalScrollIndicatorInsets)
        _assignIfNotEqual(.init(configuration.scrollIndicatorInsets.vertical), to: \.verticalScrollIndicatorInsets)
        _assignIfNotEqual(configuration.decelerationRate, to: \.decelerationRate)
        _assignIfNotEqual(.init(configuration.contentInset), to: \.contentInset)
        
        _assignIfNotEqual(configuration.scrollIndicatorScheme, to: \.indicatorStyle)
        _assignIfNotEqual(configuration.bouncesZoom, to: \.bouncesZoom)
        _assignIfNotEqual(configuration.scrollToTop, to: \.scrollsToTop)
        _assignIfNotEqual(configuration.scrollZoomScale.minimum, to: \.minimumZoomScale)
        _assignIfNotEqual(configuration.scrollZoomScale.maximum, to: \.maximumZoomScale)
        _assignIfNotEqual(configuration.panGestureRecognizer.minNumberOfTouches, to: \.panGestureRecognizer.minimumNumberOfTouches)
        _assignIfNotEqual(configuration.panGestureRecognizer.maxNumberOfTouches, to: \.panGestureRecognizer.maximumNumberOfTouches)
        
        
        if let contentInsetAdjustmentBehavior = configuration.contentInsetAdjustmentBehavior {
            self.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        } else {
            self.contentInsetAdjustmentBehavior = .automatic
        }
        
        #if os(iOS) || targetEnvironment(macCatalyst)
        isPagingEnabled = configuration.isPagingEnabled
        #endif
        
        #if os(iOS) || targetEnvironment(macCatalyst)
        keyboardDismissMode = configuration.keyboardDismissMode
        #endif
        
        if let contentOffset = configuration.contentOffset?.wrappedValue {
            if self.contentOffset.ceil != contentOffset.ceil {
                setContentOffset(contentOffset, animated: true)
            }
        }
        
        #if !os(tvOS)
        if configuration.onRefresh != nil || configuration.isRefreshing != nil {
            let refreshControl: _UIRefreshControl
            
            if let _refreshControl = self.refreshControl as? _UIRefreshControl {
                _refreshControl.onRefresh = configuration.onRefresh ?? { }
                
                refreshControl = _refreshControl
            } else {
                refreshControl = _UIRefreshControl(onRefresh: configuration.onRefresh ?? { })
                
                self.alwaysBounceVertical = true
                self.refreshControl = refreshControl
                
                if refreshControl.superview == nil {
                    addSubview(refreshControl)
                }
            }
            
            refreshControl.tintColor = configuration.refreshControlTintColor
            
            if let isRefreshing = configuration.isRefreshing, refreshControl.isRefreshing != isRefreshing {
                if isRefreshing {
                    if !configuration.contentOffsetBehavior.contains(.maintainOnChangeOfContentSize) {
                        refreshControl.beginRefreshingWithoutUserInput(adjustContentOffset: !(configuration.initialContentAlignment == .bottom))
                    }
                } else {
                    refreshControl.endRefreshing()
                }
            }
        }
        #endif
    }
    
    func maintainScrollContentOffsetBehavior(
        _ behavior: ScrollContentOffsetBehavior,
        animated: Bool,
        _ update: () -> Void
    ) {
        if behavior.contains(.maintainOnChangeOfContentSize) {
            if isScrolling {
                setContentOffset(contentOffset, animated: false)
            }
        }
        
        let beforeVerticalAlignment = currentVerticalAlignment
        let beforeContentSize = contentSize
        
        update()
        
        let afterContentSize = contentSize
        
        if behavior.contains(.maintainOnChangeOfContentSize) {
            guard afterContentSize != beforeContentSize else {
                return
            }
            
            var deltaX = contentOffset.x + (afterContentSize.width - beforeContentSize.width)
            var deltaY = contentOffset.y + (afterContentSize.height - beforeContentSize.height)
            
            deltaX = beforeContentSize.width == 0 ? 0 : max(0, deltaX)
            deltaY = beforeContentSize.height == 0 ? 0 : max(0, deltaY)
            
            let newOffset = CGPoint(
                x: contentOffset.x + deltaX,
                y: contentOffset.y + deltaY
            )
            
            if contentOffset != newOffset {
                setContentOffset(newOffset, animated: animated)
            }
        } else if behavior.contains(.smartAlignOnChangeOfContentSize) {
            if beforeVerticalAlignment == .bottom {
                setContentAlignment(.bottom, animated: animated)
            }
        }
    }
}

#if !os(tvOS)

final class _UIRefreshControl: UIRefreshControl {
    var onRefresh: () -> Void
    
    var isRefreshingWithoutUserInteraction: Bool = false
    var lastContentInset: UIEdgeInsets?
    var lastContentOffset: CGPoint?
    
    init(onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh
        
        super.init()
        
        addTarget(
            self,
            action: #selector(self.refreshChanged),
            for: .valueChanged
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginRefreshing() {
        if let superview = superview as? UIScrollView {
            lastContentInset = superview.contentInset
            lastContentOffset = superview.contentOffset
        }
        
        super.beginRefreshing()
    }
    
    func beginRefreshingWithoutUserInput(adjustContentOffset: Bool) {
        beginRefreshing()
        
        isRefreshingWithoutUserInteraction = true
        
        if let superview = superview as? UIScrollView {
            if adjustContentOffset {
                superview.setContentOffset(CGPoint(x: 0, y: superview.contentOffset.y - frame.height), animated: true)
            } else {
                self.lastContentOffset = nil
            }
        }
        
        sendActions(for: .valueChanged)
    }
    
    override func endRefreshing() {
        defer {
            isRefreshingWithoutUserInteraction = false
        }
        
        super.endRefreshing()
        
        if let superview = superview as? UIScrollView {
            if let lastContentInset = lastContentInset, superview.contentInset != lastContentInset {
                superview.contentInset = lastContentInset
            }
            
            if let lastContentOffset = lastContentOffset, isRefreshingWithoutUserInteraction {
                superview.setContentOffset(lastContentOffset, animated: true)
                
                self.lastContentOffset = nil
            }
        }
    }
    
    @objc func refreshChanged(_ sender: UIRefreshControl) {
        guard !isRefreshingWithoutUserInteraction else {
            return
        }
        
        onRefresh()
    }
}

#endif

extension EnvironmentValues {
    struct _ScrollViewConfiguration: EnvironmentKey {
        static let defaultValue: CocoaScrollViewConfiguration<AnyView> = nil
    }
    
    var _scrollViewConfiguration: CocoaScrollViewConfiguration<AnyView> {
        get {
            var result = self[_ScrollViewConfiguration.self]
            
            result.update(from: self)
            
            return result
        } set {
            self[_ScrollViewConfiguration.self] = newValue
        }
    }
}

#endif
