//
//  PPVC.swift
//  SwiftDemo
//
//

import UIKit
import WebKit
import AnyThinkSDK

class PPVC: UIViewController {

    private enum DisplayMode {
        case list           // SDK 管理列表
        case privacyPolicy  // 隐私政策
    }

    // MARK: - Constants
    private static let hasShownKey = "HasShownSDKManagement"
    private static let initializedKey = "IsSDKInitialized"
    private static let personalizedKey = "IsPersonalizedAdEnabled"
    /// 隐私政策页面地址 - 请替换为您自己的隐私政策 URL
    private static let privacyPolicyURL = "https://www.takuad.com/zh-cn/privacy-policy"

    // MARK: - Properties
    private var agreementCallback: (() -> Void)?
    private var presentWindow: UIWindow?
    private var displayMode: DisplayMode = .list
    private var containerView: UIView?
    private var tableView: UITableView?
    private var personalizedAdSwitch: UISwitch?
    private var webView: WKWebView?
    private var isSDKInitialized = false
    private var isPersonalizedAdEnabled = false

    // MARK: - Entry

    /// 展示SDK管理页面
    /// - Parameter agreementCallback: 用户点击「展示广告」后的回调
    static func showSDKManagement(agreementCallback: (() -> Void)? = nil) {

        if UserDefaults.standard.bool(forKey: hasShownKey) { return }

        let ppvc = PPVC()
        ppvc.agreementCallback = agreementCallback
        ppvc.displayMode = .list

        // 创建新的 window 来展示SDK管理页面，兼容 Scene 方式
        let window = createPresentationWindow()
        window.windowLevel = .alert
        window.backgroundColor = .clear
        window.rootViewController = ppvc
        ppvc.presentWindow = window
        window.makeKeyAndVisible()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard
        isSDKInitialized = defaults.bool(forKey: PPVC.initializedKey)
        isPersonalizedAdEnabled = defaults.bool(forKey: PPVC.personalizedKey)

        setupContainerView()

        if displayMode == .list {
            setupListUI()
        } else {
            setupPrivacyPolicyUI()
            loadPrivacyPolicy()
        }
    }

    // MARK: - UI

    private func setupContainerView() {
        let container = UIView()
        container.backgroundColor = .white
        container.translatesAutoresizingMaskIntoConstraints = false
        containerView = container

        if displayMode == .list {
            // SDK管理页面 - 全屏显示
            view.backgroundColor = .white
            view.addSubview(container)
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        } else {
            // 隐私政策页面 - 居中弹窗显示
            view.backgroundColor = UIColor(white: 0, alpha: 0.5)
            container.layer.cornerRadius = 12
            container.layer.masksToBounds = true
            view.addSubview(container)

            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            NSLayoutConstraint.activate([
                container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                container.widthAnchor.constraint(equalToConstant: screenWidth * 0.85),
                container.heightAnchor.constraint(equalToConstant: screenHeight * 0.7)
            ])
        }
    }

    private func setupListUI() {
        guard let container = containerView else { return }

        let titleLabel = UILabel()
        titleLabel.text = "Swift Demo"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .white
        table.separatorStyle = .singleLine
        table.rowHeight = 80
        table.translatesAutoresizingMaskIntoConstraints = false
        tableView = table
        container.addSubview(table)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),

            table.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            table.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func setupPrivacyPolicyUI() {
        guard let container = containerView else { return }

        let titleLabel = UILabel()
        titleLabel.text = "隐私政策"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.navigationDelegate = self
        web.backgroundColor = .white
        web.translatesAutoresizingMaskIntoConstraints = false
        webView = web
        container.addSubview(web)

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonContainer)

        let agreeButton = UIButton(type: .system)
        agreeButton.setTitle("同意", for: .normal)
        agreeButton.setTitleColor(.white, for: .normal)
        agreeButton.backgroundColor = .systemBlue
        agreeButton.layer.cornerRadius = 8
        agreeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        agreeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(agreeButton)

        let rejectButton = UIButton(type: .system)
        rejectButton.setTitle("拒绝", for: .normal)
        rejectButton.setTitleColor(.black, for: .normal)
        rejectButton.backgroundColor = .lightGray
        rejectButton.layer.cornerRadius = 8
        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        rejectButton.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(rejectButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),

            web.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            web.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            web.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            web.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: -10),

            buttonContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            buttonContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            buttonContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),

            agreeButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            agreeButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            agreeButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            agreeButton.widthAnchor.constraint(equalTo: buttonContainer.widthAnchor, multiplier: 0.45),

            rejectButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            rejectButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            rejectButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            rejectButton.widthAnchor.constraint(equalTo: buttonContainer.widthAnchor, multiplier: 0.45)
        ])
    }

    private func loadPrivacyPolicy() {
        guard let url = URL(string: PPVC.privacyPolicyURL) else {
            NSLog("隐私政策URL格式错误: %@", PPVC.privacyPolicyURL)
            webView?.loadHTMLString("<html><body><h1>加载失败</h1><p>隐私政策页面无法加载，请检查网络连接或联系开发者。</p></body></html>", baseURL: nil)
            return
        }
        webView?.load(URLRequest(url: url))
    }

    // MARK: - Actions

    private func initializeSDK() {
        if isSDKInitialized {
            showAlert("提示", message: "SDK已经初始化完成")
            return
        }

        // 切换到隐私政策页面
        displayMode = .privacyPolicy
        containerView?.subviews.forEach { $0.removeFromSuperview() }
        setupPrivacyPolicyUI()
        loadPrivacyPolicy()
    }

    private func showAdvertisement() {
        if !isSDKInitialized {
            showAlert("提示", message: "请先进行SDK初始化")
            return
        }

        dismissSDKManagement()
        agreementCallback?()
    }

    @objc private func personalizedAdSwitchChanged(_ sender: UISwitch) {
        isPersonalizedAdEnabled = sender.isOn

        let defaults = UserDefaults.standard
        defaults.set(isPersonalizedAdEnabled, forKey: PPVC.personalizedKey)
        defaults.synchronize()

        AdSDKManager.shared.applyPersonalizedAdState(isPersonalizedAdEnabled)

        let status = isPersonalizedAdEnabled ? "开" : "关"
        tableView?.cellForRow(at: IndexPath(row: 2, section: 0))?.detailTextLabel?.text = "当前状态：\(status)"
    }

    @objc private func agreeButtonTapped() {
        // 用户点击同意按钮，保存已展示SDK管理的标记和SDK初始化状态
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: PPVC.hasShownKey)
        defaults.set(true, forKey: PPVC.initializedKey)
        defaults.synchronize()

        isSDKInitialized = true

        AdSDKManager.shared.initSDK()

        showAlert("初始化成功", message: "SDK初始化完成，现在可以展示广告了") {
            // 切换回SDK管理页面
            self.displayMode = .list
            self.containerView?.removeFromSuperview()
            self.containerView = nil
            self.setupContainerView()
            self.setupListUI()
        }
    }

    @objc private func rejectButtonTapped() {
        // 用户点击拒绝按钮，退出应用
        exit(0)
    }

    private func dismissSDKManagement() {
        presentWindow?.resignKey()
        presentWindow?.isHidden = true
        presentWindow = nil
    }

    private func showAlert(_ title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    // MARK: - Window

    private static func createPresentationWindow() -> UIWindow {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        if let scene = scene {
            return UIWindow(windowScene: scene)
        }
        return UIWindow(frame: UIScreen.main.bounds)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension PPVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SDKManagementCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        cell.selectionStyle = .default
        cell.accessoryView = nil
        cell.accessoryType = .none

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "初始化SDK"
            cell.detailTextLabel?.text = "用户同意隐私协议后，进行SDK初始化"
            cell.accessoryType = .disclosureIndicator
        case 1:
            cell.textLabel?.text = "展示广告"
            cell.detailTextLabel?.text = "需要初始化SDK后才能进行广告展示"
            cell.accessoryType = .disclosureIndicator
        default:
            cell.textLabel?.text = "个性化广告服务开关"
            cell.detailTextLabel?.text = "当前状态：\(isPersonalizedAdEnabled ? "开" : "关")"
            if personalizedAdSwitch == nil {
                let switchView = UISwitch()
                switchView.addTarget(self, action: #selector(personalizedAdSwitchChanged(_:)), for: .valueChanged)
                personalizedAdSwitch = switchView
            }
            personalizedAdSwitch?.isOn = isPersonalizedAdEnabled
            cell.accessoryView = personalizedAdSwitch
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            initializeSDK()
        case 1:
            showAdvertisement()
        default:
            // 个性化广告服务开关 - 点击行也可以切换开关
            guard let switchView = personalizedAdSwitch else { return }
            switchView.setOn(!switchView.isOn, animated: true)
            personalizedAdSwitchChanged(switchView)
        }
    }
}

// MARK: - WKNavigationDelegate

extension PPVC: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // WebView加载完成
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("WebView加载失败: %@", error.localizedDescription)
    }
}
