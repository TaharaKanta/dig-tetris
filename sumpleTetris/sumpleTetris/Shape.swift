//
//  Shape.swift
//  Tetris_iOS
//
//  Created by Ryan Leung on 2020-08-30.
//  Copyright © 2020 Ryan Leung. All rights reserved.
//

import SpriteKit

let NumOrientations: UInt32 = 4

let NumShapeTypes: UInt32 = 7

let FirstBlockIdx: Int = 0
let SecondBlockIdx: Int = 1
let ThirdBlockIdx: Int = 2
let FourthBlockIdx: Int = 3

enum Orientation: Int, CustomStringConvertible {
    case Zero = 0, Ninety, OneEighty, TwoSeventy
    
    var description: String {
        switch self {
        case .Zero:
            return "0"
        case .Ninety:
            return "Ninety"
        case .OneEighty:
            return "180"
        case .TwoSeventy:
            return "270"
        }
    }
    
    static func random() -> Orientation {
        debugPrint(#function,"shape")
        return Orientation(rawValue: Int(arc4random_uniform(NumOrientations)))!
    }
    
    static func rotate(orientation:Orientation, clockwise: Bool) -> Orientation {
        debugPrint(#function)
        var rotated = orientation.rawValue + (clockwise ? 1 : -1)
        if rotated > Orientation.TwoSeventy.rawValue {
            rotated = Orientation.Zero.rawValue
        } else if rotated < 0 {
            rotated = Orientation.TwoSeventy.rawValue
        }
        return Orientation(rawValue:rotated)!
    }
}

class Shape: Hashable, CustomStringConvertible {
    let color:BlockColor
    
    var blocks = Array<Block>()
    var orientation: Orientation
    var column, row: Int
    
    var blockRowColumnPositions: [Orientation: Array<(columnDiff: Int, rowDiff: Int)>] {
        return[:]
    }
    
    var bottomBlocksForOrientations: [Orientation: Array<Block>] {
        return[:]
    }
    
    var bottomBlocks:Array<Block> {
        guard let bottomBlocks = bottomBlocksForOrientations[orientation] else {
            return []
        }
        return bottomBlocks
    }
    
    // Hashable
    func hash(into hasher: inout Hasher) {
        debugPrint(#function)
        for block in blocks {
            hasher.combine(block)
        }
    }
    
    var hashValue: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }
    
    // CustomStringConvertible
    var description: String {
        return "\(color) block facing \(orientation): \(blocks[FirstBlockIdx]), \(blocks[SecondBlockIdx]), \(blocks[ThirdBlockIdx]), \(blocks[FourthBlockIdx])"
    }
    
    init(column: Int, row: Int, color: BlockColor, orientation: Orientation) {
        self.color = color
        self.column = column
        self.row = row
        self.orientation = orientation
        initializeBlocks()
    }
    
    convenience init(column: Int, row: Int) {
        self.init(column:column, row:row, color:BlockColor.random(), orientation:Orientation.random())
    }
    
    final func initializeBlocks() {
        debugPrint(#function)
        guard let blockRowColumnTranslations = blockRowColumnPositions[orientation] else {
            return
        }
        
        blocks = blockRowColumnTranslations.map { (diff) -> Block in
            return Block(column: column + diff.columnDiff, row: row + diff.rowDiff, color: color)
        }
    }
    
    final func rotateBlocks(orientation: Orientation) {
        debugPrint(#function)
        guard let blockRowColumnTranslation: Array<(columnDiff: Int, rowDiff: Int)> = blockRowColumnPositions[orientation] else {
            return
        }
        
        for (idx, diff) in blockRowColumnTranslation.enumerated() {
            blocks[idx].column = column + diff.columnDiff
            blocks[idx].row = row + diff.rowDiff
        }
    }
    
    final func rotateClockwise() {
        debugPrint(#function)
        let newOrientation = Orientation.rotate(orientation: orientation, clockwise: true)
        rotateBlocks(orientation: newOrientation)
        orientation = newOrientation
    }
    
    final func rotateCounterClockwise() {
        debugPrint(#function)
        let newOrientation = Orientation.rotate(orientation: orientation, clockwise: false)
        rotateBlocks(orientation: newOrientation)
        orientation = newOrientation
    }
    
    final func lowerShapeByOneRow() {
        shiftBy(columns: 0, rows: 1)
    }
    
    final func raiseShapeByOneRow() {
        debugPrint(#function)
        shiftBy(columns: 0, rows: -1)
    }
    
    final func shiftRightByOneColumn() {
        debugPrint(#function)
        shiftBy(columns: 1, rows: 0)
    }
    
    final func shiftLeftByOneColumn() {
        debugPrint(#function)
        shiftBy(columns: -1, rows: 0)
    }
    
    final func shiftBy(columns: Int, rows: Int) {
        self.column += columns
        self.row += rows
        for block in blocks {
            block.column += columns
            block.row += rows
        }
    }
    
    final func moveTo(column: Int, row: Int) {
        debugPrint(#function)
        self.column = column
        self.row = row
        rotateBlocks(orientation: orientation)
    }
    
    final class func randomMock(startingColumn: Int, startingRow: Int) -> Shape {
        debugPrint(#function)
        return BarShape(column: startingColumn, row: startingRow)
    }
    
//    final class func random(startingColumn: Int, startingRow: Int) -> Shape {
//        switch Int(arc4random_uniform(NumShapeTypes)) {
//
//        case 0:
//            return SquareShape(column: startingColumn, row: startingRow)
//        case 1:
//            return BarShape(column: startingColumn, row: startingRow)
//        case 2:
//            return TShape(column: startingColumn, row: startingRow)
//        case 3:
//            return LShape(column: startingColumn, row: startingRow)
//        case 4:
//            return JShape(column: startingColumn, row: startingRow)
//        case 5:
//            return SShape(column: startingColumn, row: startingRow)
//        default:
//            return ZShape(column: startingColumn, row: startingRow)
//        }
//    }
}

func ==(lhs: Shape, rhs: Shape) -> Bool {
    return lhs.row == rhs.row && lhs.column == rhs.column
}
