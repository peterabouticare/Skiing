//
//  main.swift
//  Skiing
//
//  Created by Peter on 1/12/16.
//  Copyright © 2016 iCare.4U Pte Ltd. All rights reserved.
//

import Foundation

print("Hello, World!")

/// Representation of each position in the map
struct Position: Hashable, Equatable, CustomStringConvertible {
    let r: Int
    let c: Int
    var hashValue: Int {
        return r.hashValue ^ c.hashValue
    }
    static func == (lhs: Position, rhs: Position) -> Bool {
        return lhs.r == rhs.r && lhs.c == rhs.c
    }
    var description: String {
        return "\(MapArray[r][c])"
    }
}

/// Representation of path to go in the map
struct Path: Comparable, CustomStringConvertible {
    var positions: [Position] = []
    var count: Int {
        return positions.count
    }
    mutating func append(position: Position) -> Bool {
        if containsPosition(position: position) == false {
            self.positions.append(position)
            return true
        } else {
            return false
        }
    }
    func containsPosition(position: Position) -> Bool {
        // only need to check the last element as the rest is not possible as it is traversed in decreasing order
        if positions.count == 0 {
            return false
        } else {
            return positions[count-1] == position
        }
    }
    mutating func append(path: Path) {
        for p in path.positions {
            if self.append(position: p) == false {
                break
            }
        }
    }
    static func > (lhs: Path, rhs: Path) -> Bool {
        if lhs.count == rhs.count {
            if lhs.count > 0 {
                let lhsSteep = MapArray[lhs.positions[0].r][lhs.positions[0].c] - MapArray[lhs.positions[lhs.count-1].r][lhs.positions[lhs.count-1].c]
                let rhsSteep = MapArray[rhs.positions[0].r][rhs.positions[0].c] - MapArray[rhs.positions[rhs.count-1].r][rhs.positions[rhs.count-1].c]
                return lhsSteep > rhsSteep
            }
            return false
        } else {
            return lhs.count > rhs.count
        }
    }
    static func < (lhs: Path, rhs: Path) -> Bool {
        if lhs.count == rhs.count {
            if lhs.count > 0 {
                let lhsSteep = MapArray[lhs.positions[0].r][lhs.positions[0].c] - MapArray[lhs.positions[lhs.count-1].r][lhs.positions[lhs.count-1].c]
                let rhsSteep = MapArray[rhs.positions[0].r][rhs.positions[0].c] - MapArray[rhs.positions[rhs.count-1].r][rhs.positions[rhs.count-1].c]
                return lhsSteep < rhsSteep
            }
            return true
        } else {
            return lhs.count < rhs.count
        }
    }
    static func == (lhs: Path, rhs: Path) -> Bool {
        if lhs.count == rhs.count {
            if lhs.count > 0 {
                let lhsSteep = MapArray[lhs.positions[0].r][lhs.positions[0].c] - MapArray[lhs.positions[lhs.count-1].r][lhs.positions[lhs.count-1].c]
                let rhsSteep = MapArray[rhs.positions[0].r][rhs.positions[0].c] - MapArray[rhs.positions[rhs.count-1].r][rhs.positions[rhs.count-1].c]
                return lhsSteep == rhsSteep
            }
        }
        return true
    }
    var description: String {
        var str = ""
        for p in positions {
            str.append(" \(p)")
        }
        return str
    }
}

/// Store 2D representation of array. Global variable to save memory usage due to recursive usage. 
/// Alternatively, map can be represented as Object so that it can be passed as reference instead of value
var MapArray: [[Int]] = []

/// Store the most optimal for each starting position
var PathsDictionary: [Position: Path] = [:]

/// Read mapping file and parse it into 2D array
///
/// - Parameter fullPath: full path to the mapping file. It only support built-in file
/// - Returns: the 2D array where each outer-indexed array content refer to each row in the mapping file
func readMap(fullPath: String)->[[Int]]? {
    do {
        let fileContentStr = try String(contentsOfFile: fullPath)
        let singleLines = fileContentStr.components(separatedBy: "\n")
        if singleLines.count > 0 {
            let sizeArray = singleLines[0].components(separatedBy: " ")
            if sizeArray.count >= 2 {
                guard let rowSize = Int(sizeArray[0]) else {
                    return nil
                }
                var map: [[Int]] = []
                for i in 1...rowSize {
                    let rowStr = singleLines[i]
                    var potentialRow: [Int] = []
                    let rowStrArray = rowStr.components(separatedBy: " ")
                    for rStr in rowStrArray {
                        if let r = Int(rStr) {
                            potentialRow.append(r)
                        }
                    }
                    map.append(potentialRow)
                }
                return map
            }
        }
    } catch {
        print("Exception \(error)")
    }
    return nil
}

func updateMostOptimalPath(path: Path) {
    guard path.count > 0 else {
        return
    }
    let startingPos = path.positions[0]
    if let curOptimalPath = PathsDictionary[startingPos] {
        if path > curOptimalPath {
            PathsDictionary[startingPos] = path
        }
    } else {
        PathsDictionary[startingPos] = path
    }
}

func findNextSkiingPath(currentPosition curPos: Position, currentPath curPath: Path) {
    
    var stillHasPotentialPath = false
    
    let beforeR = curPos.r - 1
    let afterR = curPos.r + 1
    let beforeC = curPos.c - 1
    let afterC = curPos.c + 1
    let curHeight = MapArray[curPos.r][curPos.c]
    // up
    if beforeR >= 0 {
        let nextPos = Position(r:beforeR, c:curPos.c)
        let nextHeight = MapArray[nextPos.r][nextPos.c]
        if curHeight > nextHeight {
            stillHasPotentialPath = true
            goTo(nextPosition: nextPos, curPosition: curPos, currentPath: curPath)
        }
    }
    
    // down
    if afterR < MapArray.count {
        let nextPos = Position(r:afterR, c:curPos.c)
        let nextHeight = MapArray[nextPos.r][nextPos.c]
        if curHeight > nextHeight {
            stillHasPotentialPath = true
            goTo(nextPosition: nextPos, curPosition: curPos, currentPath: curPath)
        }
    }
    
    // left
    if beforeC >= 0 {
        let nextPos = Position(r:curPos.r, c:beforeC)
        let nextHeight = MapArray[nextPos.r][nextPos.c]
        if curHeight > nextHeight {
            stillHasPotentialPath = true
            goTo(nextPosition: nextPos, curPosition: curPos, currentPath: curPath)
        }
    }
    
    // Right
    if afterC < MapArray.count {
        let nextPos = Position(r:curPos.r, c:afterC)
        let nextHeight = MapArray[nextPos.r][nextPos.c]
        if curHeight > nextHeight {
            stillHasPotentialPath = true
            goTo(nextPosition: nextPos, curPosition: curPos, currentPath: curPath)
        }
    }
    
    if stillHasPotentialPath == false {
        updateMostOptimalPath(path: curPath)
    }
}

func goTo(nextPosition nextPos: Position, curPosition curPos: Position, currentPath curPath: Path) {
    var curPath = curPath
    
    if let existingPath = PathsDictionary[nextPos] {
        curPath.append(path: existingPath)
        updateMostOptimalPath(path: curPath)
    } else {
        if curPath.append(position: nextPos) {
            findNextSkiingPath(currentPosition: nextPos, currentPath: curPath)
        }
    }
}

func findMostOptimalSkiingPath(mapFile: String) -> Path?{
    if let map = readMap(fullPath: mapFile) {
        MapArray = map
        for r in 0..<map.count {
            for c in 0..<map[r].count {
                let startingPos = Position(r: r, c: c)
                var newPath = Path()
                if newPath.append(position: startingPos) {
                    findNextSkiingPath(currentPosition: startingPos, currentPath: newPath)
                }
            }
        }
        // for each position
        // 1. go to potential next point, whether it is left, right, up, down
        // 2. if there is no more path, it is finish line
        // 3. check the hash table whether it exists
        // 4. if it exists, create new log entry in the hash table for the original starting position
        // 5. if it does not exist, go to point 1,
    }
    var optimalPath:Path? = nil
    for r in 0..<MapArray.count {
        for c in 0..<MapArray[r].count {
            if let path = PathsDictionary[Position(r:r, c:c)] {
                if optimalPath == nil {
                    optimalPath = path
                } else {
                    if path > optimalPath! {
                        optimalPath = path
                    }
                }
            }
        }
    }
    return optimalPath
}

if let path = findMostOptimalSkiingPath(mapFile: "/Users/peter/Desktop/Skiing/Skiing/map_2.txt") {
    print(path)
}
