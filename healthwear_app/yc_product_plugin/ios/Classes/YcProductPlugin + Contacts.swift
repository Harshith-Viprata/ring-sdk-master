//
//  YcProductPlugin + Contacts.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/12/30.
//

import UIKit
import Flutter
import YCProductSDK


/// 发送通讯录下标
private var sendContactIndex = 0

/// 通讯录列表
private var contactList = [[String : String]]()


// MARK: - 普通通讯录
extension YcProductPlugin {
    
    
    /// 发送通讯录信息
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func updateDeviceContacts(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [[String: String]] else {
            result(["code": PluginState.failed, "data": ""])
            return
        }
        
        contactList = list
        
        // 启动通讯录
        YCProduct.startSendAddressBook { [weak self] state, response in
            
            guard state == .succeed else {
                result(["code": PluginState.failed, "data": ""])
                return
            }
            
            sendContactIndex = 0
            self?.sendContactDetailInfo(result)
        }
    
    }
    
    
    /// 发送详细信息
    private func sendContactDetailInfo(_ result: @escaping FlutterResult) {
    
        if sendContactIndex >= contactList.count {
            
            sendContactIndex = 0
            
            YCProduct.stopSendAddressBook { state, response in
                
                guard state == .succeed,
                      let flag = response as? YCSyncAddressBookState,
                      flag == YCSyncAddressBookState.end else {
                    
                    result(["code": PluginState.failed, "data": ""])
                    return
                }
                
                result(["code": PluginState.succeed, "data": ""])
            }
            
            return
        }
        
        // 详细发送数据
        let item = contactList[sendContactIndex]
        
        // 开始发送
        YCProduct.sendAddressBook(
            phone: (item["phone"] ?? ""),
            name: (item["name"] ?? "")
        ) { state, response in

            guard state == .succeed,
                  let flag = response as? YCSyncAddressBookState,
                  flag == .synchronizing else {

                result(["code": PluginState.failed, "data": ""])
                return
            }

            // 开始下一个
            sendContactIndex += 1
            self.sendContactDetailInfo(result)
        }
    }
    
}

// MARK: - 杰理通讯录
extension YcProductPlugin {
    
    /// 查询杰理通讯录
    public func queryJieLiDeviceContacts(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        var items = [[String: Any]]()
        
        YCProduct.queryJLDeviceContactData { datas in
            
            for data in datas {
                
                items.append([
                    "name": data.name,
                    "phone": data.phone
                ])
            }
            
            result(["code": PluginState.succeed, "data": items])
        }
         
        
    }
    
    
    /// 更新杰理通讯录
    public func updateJieLiDeviceContacts(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        var datas = [YCDeviceContactItem]()
 
        if let list = arguments as? [[String: String]] {
            
            for item in list {
                
                if let name = item["name"],
                   let phone = item["phone"] {
                    
                    let data =
                        YCDeviceContactItem(
                            name: name,
                            phone: phone,
                            isExist: false
                        )
                    
                    datas.append(data)
                }
            
            }
        }
         
    
        YCProduct.syncJLContactInfoToDevice(datas) { isSuccess, progress in
            
            if isSuccess == false {
                result(["code": PluginState.failed, "data": ""])
                return
            }
            
            if progress >= 1.0 {
                
                result(
                    [
                        "code": isSuccess ?
                        PluginState.succeed : PluginState.failed,
                        "data": ""
                    ]
                )
            }
        }
    }
}
