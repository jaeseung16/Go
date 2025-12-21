public protocol GoBoard {
    
    var dimension: Int { get }
    
    func place(stone: Stone, at: Point)
    func isOnGrid(_ point: Point) -> Bool
    func neighbors(of point: Point) -> [Point]
    func corners(of point: Point) -> [Point]
    func getStone(at: Point) -> Stone?
}
