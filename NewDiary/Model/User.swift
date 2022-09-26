import ObjectMapper

public struct User: Mappable {
    public var name: String?
    public var job: String?
    public var id: String?
    public var createdAt: String?
    
    public init?(map: Map) {}
    
    mutating public func mapping(map: Map) {
        name        <- map["name"]
        job         <- map["job"]
        id          <- map["id"]
        createdAt   <- map["createdAt"]
    }
}
