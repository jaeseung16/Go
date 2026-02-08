public protocol GoBoard {
    
    var dimension: Int { get }
    
    func place(stone: Stone, at: Point)
    func isOnGrid(_ point: Point) -> Bool
    func neighbors(of point: Point) -> [Point]
    func corners(of point: Point) -> [Point]
    func stone(at point: Point) -> Stone?
    func goString(at point: Point) -> GoString?
    func isSelfCapture(_ move: Move) -> Bool
    func willCapture(_ move: Move) -> Bool
    func copy() -> GoBoard
    func hashableRepresentation() -> any Hashable
}
