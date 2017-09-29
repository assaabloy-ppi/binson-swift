//  Dictionary+Extension.swift
//
//  Created by Kenneth Pernyer on 2017-05-30.

import Foundation

extension Dictionary {
    func toData() -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: self) as Data?
    }
}
