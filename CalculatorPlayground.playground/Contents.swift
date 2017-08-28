//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
var secondLastCharacter = str.index(str.endIndex, offsetBy: -1)
var newDisplayValue = str.substring(to: secondLastCharacter)
