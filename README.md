# IBToCode

[![CI Status](http://img.shields.io/travis/xdaleau/IBToCode.svg?style=flat)](https://travis-ci.org/xdaleau/IBToCode)
[![Version](https://img.shields.io/cocoapods/v/IBToCode.svg?style=flat)](http://cocoapods.org/pods/IBToCode)
[![License](https://img.shields.io/cocoapods/l/IBToCode.svg?style=flat)](http://cocoapods.org/pods/IBToCode)
[![Platform](https://img.shields.io/cocoapods/p/IBToCode.svg?style=flat)](http://cocoapods.org/pods/IBToCode)


## Requirements
- iOS 8.0+
- Xcode 8.0+
- Swift 3.0+


## Installation

IBToCode is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'IBToCode'
```

## Usage


```swift
import IBToCode

class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()   
                
        IBToCode.generateCode(viewController: self)
    }

}
```

## Author

Xavier Daleau

## License

IBToCode is available under the GNU AFFERO GENERAL PUBLIC LICENSE version 3. See the LICENSE file for more info.
