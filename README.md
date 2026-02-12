# Weather App

A weather app built on the NWS API, since I've found the NWS to be more accurate than other sources like the Apple weather app as of late.

## Platform support

macOS 13/AppKit and Linux/GTK 4 are currently supported. GTK 3 is not supported due to issues with horizontal scroll views, and UIKit is experimental due to issues with NavigationSplitView. Windows is untested.

Use of [swift-bundler](https://github.com/moreSwift/swift-bundler) is encouraged but not required.

## Licensing

[SCUIDependiject](/Sources/SCUIDependiject/) is modified from [Dependiject](https://github.com/Tiny-Home-Consulting/Dependiject).
The specific modifications reside within [Store.swift](/Sources/SCUIDependiject/Store.swift); the XUI folder has been removed, and the remaining files have been taken verbatim from release 1.1.0.

All code in this repository is provided under the [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/) license.
