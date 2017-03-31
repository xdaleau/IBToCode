# IBToCode

[![CI Status](http://img.shields.io/travis/xdaleau/IBToCode.svg?style=flat)](https://travis-ci.org/xdaleau/IBToCode)
[![Version](https://img.shields.io/cocoapods/v/IBToCode.svg?style=flat)](http://cocoapods.org/pods/IBToCode)
[![License](https://img.shields.io/cocoapods/l/IBToCode.svg?style=flat)](http://cocoapods.org/pods/IBToCode)
[![Platform](https://img.shields.io/cocoapods/p/IBToCode.svg?style=flat)](http://cocoapods.org/pods/IBToCode)


##Description

IBToCode helps you build your iOS UI programmatically faster by generating the Swift code needed to recreate programmatically the UI you made with Interface Builder.  
It recreates the view hierarchy, constraints, and a few basic properties like the background colors and buttons titles.

The generated code is printed in the console.

Example of generated code:  

```swift
Hierarchy:

   + view_0 - 4 constraints 
     + button_0_0 - 2 constraints 

Code:

let view_0 = UIView()
view.addSubview(view_0)
view_0.backgroundColor = UIColor(colorLiteralRed: 0.764088273048401, green: 0.917092502117157, blue: 0.971581995487213, alpha: 1.0)
view_0.translatesAutoresizingMaskIntoConstraints = false
let view_0TopConstraint = NSLayoutConstraint(item: view_0, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 65.0)
//let view_0TrailingConstraint = NSLayoutConstraint(item: view_0, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
let view_0LeadingConstraint = NSLayoutConstraint(item: view_0, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0)
let view_0HeightConstraint = NSLayoutConstraint(item: view_0, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 160.0)
view_0.addConstraints([view_0HeightConstraint])
view.addConstraints([view_0TopConstraint, view_0LeadingConstraint])

let button_0_0 = UIButton()
view_0.addSubview(button_0_0)
button_0_0.setTitle("Button", for: .normal)
button_0_0.setTitleColor(UIColor(colorLiteralRed: 0.0, green: 0.47843137254902, blue: 1.0, alpha: 1.0), for: .normal)
button_0_0.translatesAutoresizingMaskIntoConstraints = false
let button_0_0CenterxConstraint = NSLayoutConstraint(item: button_0_0, attribute: .centerX, relatedBy: .equal, toItem: view_0, attribute: .centerX, multiplier: 1.0, constant: 0.0)
let button_0_0CenteryConstraint = NSLayoutConstraint(item: button_0_0, attribute: .centerY, relatedBy: .equal, toItem: view_0, attribute: .centerY, multiplier: 1.0, constant: 0.0)
view.addConstraints([button_0_0CenterxConstraint, button_0_0CenteryConstraint])
```

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

Xavier Daleau (ibtocode@gmail.com)

## License

IBToCode is available under the GNU AFFERO GENERAL PUBLIC LICENSE version 3. See the LICENSE file for more info.
