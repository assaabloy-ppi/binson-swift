//
//  BinsonError.swift
//  Binson
//
//  Created by Fredrik Littmarck on 2018-10-22.
//  Copyright © 2018 Assa Abloy Shared Technologies. All rights reserved.
//

import Foundation

public enum BinsonError: Error {
    case insufficientData
    case invalidData
    case invalidFieldName
    case trailingGarbage
}
