# ALogin 登录管理系统

一个高度可扩展、低耦合的第三方登录管理系统，支持Google登录、Apple ID登录，并可轻松扩展更多登录方式。

## 特性

- ✅ **类型安全**: 通过枚举定义登录类型，编译时检查
- ✅ **低耦合**: 各登录提供者相互独立，互不影响
- ✅ **可扩展**: 易于添加新的登录方式
- ✅ **即插即用**: 简单的API，快速集成
- ✅ **完整回调**: 成功、失败、取消等所有状态都有回调
- ✅ **统一管理**: 单例模式统一管理所有登录状态

## 架构设计

```text
ALoginManager (单例)
├── ALoginType (登录类型枚举)
├── ALoginProviderProtocol (登录提供者协议)
├── ALoginFactory (登录工厂)
├── Providers/
│   ├── AGoogleLoginProvider (Google登录)
│   └── AAppleLoginProvider (Apple ID登录)
└── ALoginResult (登录结果模型)
```

## 快速开始

### 1. 配置登录提供者

在 `AppDelegate` 中配置：

```swift
import UIKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 配置Google登录
        ALoginFactory.shared.configureGoogleLogin(clientID: "YOUR_GOOGLE_CLIENT_ID")
        
        // 配置Apple登录
        ALoginFactory.shared.configureAppleLogin()
        
        return true
    }
    
    // 处理Google登录回调
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return AGoogleLoginProvider.handleURL(url)
    }
}
```

### 2. 使用登录功能

```swift
import UIKit

class LoginViewController: UIViewController {
    
    @IBAction func googleLoginTapped(_ sender: UIButton) {
        ALoginManager.shared.googleLogin(from: self) { result in
            DispatchQueue.main.async {
                self.handleLoginResult(result)
            }
        }
    }
    
    @IBAction func appleLoginTapped(_ sender: UIButton) {
        ALoginManager.shared.appleLogin(from: self) { result in
            DispatchQueue.main.async {
                self.handleLoginResult(result)
            }
        }
    }
    
    private func handleLoginResult(_ result: ALoginResult) {
        switch result.status {
        case .success:
            print("登录成功！")
            print("用户ID: \(result.userID ?? "无")")
            print("用户邮箱: \(result.userEmail ?? "无")")
            print("用户姓名: \(result.userName ?? "无")")
            
        case .failed(let error):
            print("登录失败: \(error.localizedDescription)")
            
        case .cancelled:
            print("用户取消登录")
            
        case .inProgress:
            print("登录进行中...")
        }
    }
}
```

### 3. 使用便捷扩展

```swift
// 使用UIViewController扩展
self.performGoogleLogin { result in
    // 处理结果
}

self.performAppleLogin { result in
    // 处理结果
}

self.performLogin(type: .google) { result in
    // 处理结果
}
```

## API 参考

### ALoginManager

主要的登录管理类，提供统一的登录接口。

```swift
// 单例访问
ALoginManager.shared

// 执行登录
func login(type: ALoginType, from: UIViewController, callback: @escaping ALoginCallback)

// 登出
func logout(type: ALoginType, callback: @escaping (Bool) -> Void)

// 检查登录状态
func isLoggedIn(type: ALoginType) -> Bool

// 获取用户信息
func getCurrentUserInfo(type: ALoginType) -> [String: Any]?

// 便捷方法
func googleLogin(from: UIViewController, callback: @escaping ALoginCallback)
func appleLogin(from: UIViewController, callback: @escaping ALoginCallback)
```

### ALoginType

支持的登录类型枚举。

```swift
enum ALoginType: String, CaseIterable {
    case google = "google"
    case apple = "apple"
    
    var displayName: String  // 显示名称
    var iconName: String     // 图标名称
}
```

### ALoginResult

登录结果模型，包含所有登录信息。

```swift
struct ALoginResult {
    let type: ALoginType           // 登录类型
    let status: ALoginStatus       // 登录状态
    let userInfo: [String: Any]?   // 用户信息
    let token: String?             // 访问令牌
    let error: ALoginError?        // 错误信息
}

// 便捷属性
var isSuccess: Bool        // 是否成功
var isFailure: Bool        // 是否失败
var isCancelled: Bool      // 是否取消
var userID: String?        // 用户ID
var userEmail: String?     // 用户邮箱
var userName: String?      // 用户姓名
```

## 扩展新的登录方式

### 1. 创建登录提供者

```swift
class AWeChatLoginProvider: ALoginProviderBase {
    
    override init(loginType: ALoginType = .wechat) {
        super.init(loginType: loginType)
    }
    
    override func configure(with configuration: [String: Any]) {
        super.configure(with: configuration)
        // 配置微信登录
    }
    
    override func login(from viewController: UIViewController, callback: @escaping ALoginCallback) {
        // 实现微信登录逻辑
    }
    
    override func logout(callback: @escaping (Bool) -> Void) {
        // 实现微信登出逻辑
    }
    
    override func isLoggedIn() -> Bool {
        // 检查微信登录状态
        return false
    }
    
    override func getCurrentUserInfo() -> [String: Any]? {
        // 获取微信用户信息
        return nil
    }
}
```

### 2. 添加新的登录类型

```swift
extension ALoginType {
    case wechat = "wechat"
    
    var displayName: String {
        switch self {
        case .wechat:
            return "微信"
        // ... 其他类型
        }
    }
}
```

### 3. 注册新的提供者

```swift
let wechatProvider = AWeChatLoginProvider()
ALoginManager.shared.registerProvider(wechatProvider, configuration: [:])
```

## 注意事项

1. **Google登录**: 需要在Google Cloud Console创建项目并获取Client ID
2. **Apple登录**: 需要iOS 13.0+，并在Apple Developer配置Sign in with Apple
3. **线程安全**: 所有回调都在主线程执行
4. **内存管理**: 使用weak self避免循环引用
5. **错误处理**: 所有错误都有详细的错误描述

## 依赖

- GoogleSignIn (Google登录)
- AuthenticationServices (Apple登录，iOS 13.0+)
- SnapKit (约束布局)
- CryptoKit (Apple登录加密，iOS 13.0+)

## 许可证

MIT License
