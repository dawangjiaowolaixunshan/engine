import MediaType

public protocol RequestContentSubscript {}

extension String: RequestContentSubscript { }
extension Int: RequestContentSubscript {}

public extension Request {

    public enum MultiPart: Node {
        case files([(name: String?, type: MediaType?, data: Data)])
        case file(name: String?, type: MediaType?, data: Data)
        case input(String)
        
        public var file: (name: String?, type: MediaType?, data: Data)? {
            if case .file(let name, let media, let data) = self {
                return (name, media, data)
            }

            return nil
        }

        public var files: [(name: String?, type: MediaType?, data: Data)]? {
            if case .files(let files) = self {
                return files
            }

            return nil
        }

        public var input: String? {
            if case .input(let string) = self {
                return string
            }

            return nil
        }
        
        public var isNull: Bool {
            return self.input == "null"
        }
        
        public var bool: Bool? {
            if case .input(let bool) = self {
                return Bool(bool)
            }
            
            return nil
        }
        
        public var int: Int? {
            guard let double = double else { return nil }
            return Int(double)
        }
        
        public var uint: UInt? {
            guard let double = double else { return nil }
            return UInt(double)
        }
        
        public var float: Float? {
            guard let double = double else { return nil }
            return Float(double)
        }
        
        public var double: Double? {
            if case .input(let d) = self {
                return Double(d)
            }
            
            return nil
        }
        
        public var string: String? {
            return self.input
        }
        
        public var array: [Node]? {
            guard case .input(let a) = self else {
                return nil
            }
            
            return [a]
//            return self
//                .split(byString: ",")
//                .map { $0 as Node }
        }
        
        public var object: [String : Node]? {
            return nil
        }
        
        public var json: Json? {
            if case .input(let j) = self {
                return Json(j)
            }
            
            return nil
        }
    }

    /**
        The data received from the request in json body or url query
    */
    public struct Content {
        // MARK: Initialization
        public let query: [String: String]
        public let json: Json?
        public let formEncoded: [String: MultiPart]?

        internal init(query: [String: String], json: Json?, formEncoded: [String: MultiPart]?) {
            self.query = query
            self.json = json
            self.formEncoded = formEncoded
        }

        // MARK: Subscripting
        public subscript(index: Int) -> Node? {
            if let value = query["\(index)"] {
                return value
            } else if let value = json?.array?[index] {
                return value
            } else if let value = formEncoded?["\(index)"] {
                return value
            } else {
                return nil
            }
        }

        public subscript(key: String) -> Node? {
            if let value = query[key] {
                return value
            } else if let value = json?.object?[key] {
                return value
            } else if let value = formEncoded?[key] {
                return value
            } else {
                return nil
            }
        }
    }

}

extension String: Node {
    public var isNull: Bool {
        return self == "null"
    }

    public var bool: Bool? {
        return Bool(self)
    }

    public var int: Int? {
        guard let double = double else { return nil }
        return Int(double)
    }

    public var uint: UInt? {
        guard let double = double else { return nil }
        return UInt(double)
    }

    public var float: Float? {
        guard let double = double else { return nil }
        return Float(double)
    }

    public var double: Double? {
        return Double(self)
    }

    public var string: String? {
        return self
    }

    public var array: [Node]? {
        return self
            .split(byString: ",")
            .map { $0 as Node }
    }

    public var object: [String : Node]? {
        return nil
    }

    public var json: Json? {
        return Json(self)
    }
}


extension String {

    /**
        Query data is information appended to the URL path
        as `key=value` pairs separated by `&` after
        an initial `?`

        - returns: String dictionary of parsed Query data
     */
    internal func queryData() -> [String: String] {
        // First `?` indicates query, subsequent `?` should be included as part of the arguments
        return split(separator: "?", maxSplits: 1)
            .dropFirst()
            .reduce("", combine: +)
            .keyValuePairs()
    }

    /**
        Parses `key=value` pair data separated by `&`.

        - returns: String dictionary of parsed data
     */
    internal func keyValuePairs() -> [String: String] {
        var data: [String: String] = [:]

        for pair in self.split(byString: "&") {
            let tokens = pair.split(separator: "=", maxSplits: 1)

            if
                let name = tokens.first,
                let value = tokens.last,
                let parsedName = try? String(percentEncoded: name) {
                data[parsedName] = try? String(percentEncoded: value)
            }
        }

        return data
    }

}

extension Bool {
    /**
        This function seeks to replicate the expected behavior of `var boolValue: Bool` on `NSString`.  Any variant of `yes`, `y`, `true`, `t`, or any numerical value greater than 0 will be considered `true`
    */
    public init(_ string: String) {
        let cleaned = string
            .lowercased()
            .characters
            .first ?? "n"

        switch cleaned {
        case "t", "y", "1":
            self = true
        default:
            if let int = Int(String(cleaned)) where int > 0 {
                self = true
            } else {
                self = false
            }

        }
    }
}
