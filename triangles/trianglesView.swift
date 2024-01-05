import ScreenSaver
import SwiftUI

let stepDuration: UInt8 = 20
let spawnRelax = 1
let spawnAtOnce = 3

let screenSize: CGRect = NSScreen.main!.frame
let screenWidth: Int = Int(screenSize.width)
let screenHeight: Int = Int(screenSize.height)
let minRadius: Double = sqrt(Double(screenWidth*screenWidth) + Double(screenHeight*screenHeight))/2
let triangleSideLength: CGFloat = 100

let boxFillActivated: Bool = true
let fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.5)
let cornerRadiusProportion: CGFloat = 0.35
let cornerRadius: CGFloat = triangleSideLength * cornerRadiusProportion
let edgeWidthProportion: CGFloat = 0.12
let edgeWidth: CGFloat = triangleSideLength * edgeWidthProportion

let rotationActive: Bool = true
var currentWorldRotation: Double = Double.random(in: 0...2*Double.pi)
//var currentWorldRotation: Double = 0
var currentWorldRotationDegrees: Double = currentWorldRotation / Double.pi * 180
let worldRotationSpeed: Double = 0.001
//let worldRotationSpeed: Double = 0
let worldRotationCenter: CGPoint = CGPoint(x: Int(screenWidth/2), y: Int(screenHeight/2))

let nrHues: Double = 2
var currentHue: Double = Double.random(in: 0...1)
let hueVariation: Double = 0.01
let hueBasicSpeed: Double = 0.0002
let hueSpeed: Double = hueBasicSpeed + 1/nrHues
let sat: Double = 0.9
let satVariation: Double = 0.1
let brt: Double = 0.7
let brtVariation: Double = 0.3

let minAge = 10
let chanceOfDeath = 0.5
let maxAge = 20

let root3: Double = sqrt(3)

func getWorldCoordinate(cellCoordinate: CGPoint) -> CGPoint {
    let origin: CGPoint = CGPoint(x: Int(screenWidth/2), y: Int(screenHeight/2))
    let worldCoordinate: CGPoint = CGPoint(x: origin.x+triangleSideLength*cellCoordinate.x/2, y: origin.y+triangleSideLength*cellCoordinate.y*root3/2)
    return worldCoordinate
}

func getRotatedCoordinate(worldCoordinate: CGPoint) -> CGPoint {
    if rotationActive {
        let worldCoordinateInReferenceToRotationCenter: CGPoint = CGPoint(x: worldCoordinate.x-worldRotationCenter.x, y: worldCoordinate.y-worldRotationCenter.y)
        let sin: Double = sin(currentWorldRotation)
        let cos: Double = cos(currentWorldRotation)
        let x: CGFloat = worldCoordinateInReferenceToRotationCenter.x*cos + worldCoordinateInReferenceToRotationCenter.y*sin
        let y: CGFloat = -worldCoordinateInReferenceToRotationCenter.x*sin + worldCoordinateInReferenceToRotationCenter.y*cos
        return CGPoint(x: x+worldRotationCenter.x, y: y+worldRotationCenter.y)
    }
    else {
        return worldCoordinate
    }
}

func getCellType(cell: CGPoint) -> String {
    if (cell.x+cell.y).truncatingRemainder(dividingBy: 2) == 0 { return "up" }
    else { return "down" }
}

func getTriangleVertices(anchorRotated: CGPoint, angle: Double) -> [NSPoint] {
    //        ^ v2
    //       / \
    //   v0 /___\ v1
    let sin: Double = Double(triangleSideLength)*sin(angle)
    let cos: Double = Double(triangleSideLength)*cos(angle)
    let v0: NSPoint = anchorRotated
    let v1: NSPoint = NSPoint(x: anchorRotated.x+cos,
                              y: anchorRotated.y-sin)
    let v2: NSPoint = NSPoint(x: anchorRotated.x+1/2*cos+root3/2*sin,
                              y: anchorRotated.y-1/2*sin+root3/2*cos)
    return [v0, v1, v2]
}

struct triangleShape: Shape {
    private var anchor: CGPoint
    
    init(anchor: CGPoint) {
        self.anchor = anchor
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: self.anchor.x, y: self.anchor.y))
        path.addLine(to: CGPoint(x: self.anchor.x+triangleSideLength, y: self.anchor.y))
        path.addLine(to: CGPoint(x: self.anchor.x+triangleSideLength/2, y: self.anchor.y+root3/2*triangleSideLength))
        path.addLine(to: CGPoint(x: self.anchor.x, y: self.anchor.y))

        return path
    }
}

struct flip {
    let currentCell: CGPoint
    let targetCell: CGPoint
    let clockwise: Bool
    let requiredOrientation: UInt8
    let occupiedCells: [CGPoint]
    init(currentCell: CGPoint, targetCell: CGPoint, clockwise: Bool) {
        self.currentCell = currentCell
        self.targetCell = targetCell
        self.clockwise = clockwise
        
        if getCellType(cell: self.currentCell) == "up" {
            if self.targetCell.x > self.currentCell.x {
                // to the right
                if self.clockwise {
                    self.requiredOrientation = 2
                    self.occupiedCells = [CGPoint(x: self.currentCell.x-1, y: self.currentCell.y), CGPoint(x: self.currentCell.x+1, y: self.currentCell.y+1)]
                }
                else {
                    self.requiredOrientation = 4
                    self.occupiedCells = [CGPoint(x: self.currentCell.x, y: self.currentCell.y-1), CGPoint(x: self.currentCell.x+2, y: self.currentCell.y)]
                }
            }
            else if self.targetCell.x < self.currentCell.x {
                // to the left
                if self.clockwise {
                    self.requiredOrientation = 4
                    self.occupiedCells = [CGPoint(x: self.currentCell.x, y: self.currentCell.y-1), CGPoint(x: self.currentCell.x-2, y: self.currentCell.y)]
                }
                else {
                    self.requiredOrientation = 0
                    self.occupiedCells = [CGPoint(x: self.currentCell.x+1, y: self.currentCell.y), CGPoint(x: self.currentCell.x-1, y: self.currentCell.y+1)]
                }
            }
            else {
                // down
                if self.clockwise {
                    self.requiredOrientation = 0
                    self.occupiedCells = [CGPoint(x: self.currentCell.x+1, y: self.currentCell.y), CGPoint(x: self.currentCell.x+1, y: self.currentCell.y-1)]
                }
                else {
                    self.requiredOrientation = 2
                    self.occupiedCells = [CGPoint(x: self.currentCell.x-1, y: self.currentCell.y), CGPoint(x: self.currentCell.x-1, y: self.currentCell.y-1)]
                }
            }
        }
        else {
            if self.targetCell.x > self.currentCell.x {
                // to the right
                if self.clockwise {
                    self.requiredOrientation = 1
                    self.occupiedCells = [CGPoint(x: self.currentCell.x, y: self.currentCell.y+1), CGPoint(x: self.currentCell.x+2, y: self.currentCell.y)]
                }
                else {
                    self.requiredOrientation = 3
                    self.occupiedCells = [CGPoint(x: self.currentCell.x-1, y: self.currentCell.y), CGPoint(x: self.currentCell.x+1, y: self.currentCell.y-1)]
                }
            }
            else if self.targetCell.x < self.currentCell.x {
                // to the left
                if self.clockwise {
                    self.requiredOrientation = 5
                    self.occupiedCells = [CGPoint(x: self.currentCell.x-1, y: self.currentCell.y-1), CGPoint(x: self.currentCell.x+1, y: self.currentCell.y)]
                }
                else {
                    self.requiredOrientation = 1
                    self.occupiedCells = [CGPoint(x: self.currentCell.x-2, y: self.currentCell.y), CGPoint(x: self.currentCell.x, y: self.currentCell.y+1)]
                }
            }
            else  {
                // up
                if self.clockwise {
                    self.requiredOrientation = 3
                    self.occupiedCells = [CGPoint(x: self.currentCell.x-1, y: self.currentCell.y), CGPoint(x: self.currentCell.x-1, y: self.currentCell.y+1)]
                }
                else {
                    self.requiredOrientation = 5
                    self.occupiedCells = [CGPoint(x: self.currentCell.x+1, y: self.currentCell.y), CGPoint(x: self.currentCell.x+1, y: self.currentCell.y+1)]
                }
            }
        }
    }
}

class triangle {
    init() {
        self.currentCell = CGPoint(x: 0, y: 0)
        self.targetCell = self.currentCell
        self.position = CGPoint(x: 0, y: 0)
        self.age = 0
        self.state = "inactive"
    }
    
    private var state: String
    private var orientation: UInt8 = 0
    private var progress: UInt8 = 0
    private var currentCell: CGPoint
    private var targetCell: CGPoint
    private var position: CGPoint
    private var rotation: Double = 0
    private var flippingDirection: Int = 1
    private var flippingPhase: Double = 0
    private var color: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    private var age: UInt8
    private var history: [CGPoint] = []
    private var occupiedCells: [CGPoint] = []
    
    public func activate(cell: CGPoint, newColor: NSColor) {
        self.currentCell = cell
        self.targetCell = cell
        self.orientation = getCellType(cell: self.currentCell) == "up" ? 0 : 3
        self.color = newColor
        self.history.append(cell)
        self.updatePosition()
        initGrow()
    }
    
    private func updatePosition() {
        switch self.orientation {
        case 0:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: self.currentCell))
        case 1:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: CGPoint(x: self.currentCell.x+1, y: self.currentCell.y)))
        case 2:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: CGPoint(x: self.currentCell.x+2, y: self.currentCell.y)))
        case 3:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: CGPoint(x: self.currentCell.x+2, y: self.currentCell.y+1)))
        case 4:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: CGPoint(x: self.currentCell.x+1, y: self.currentCell.y+1)))
        case 5:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: CGPoint(x: self.currentCell.x, y: self.currentCell.y+1)))
        default:
            self.position = getRotatedCoordinate(worldCoordinate: getWorldCoordinate(cellCoordinate: self.currentCell))
        }
        self.rotation = -Double(self.orientation)*60/180*Double.pi
        self.rotation += Double(self.flippingDirection) * 60/180*Double.pi * self.flippingPhase
    }
    
    public func initNextMove(nextCell: CGPoint, clockwise: Bool) {
        self.state = "move"
        self.targetCell = nextCell
        let flip: flip = flip(currentCell: self.currentCell, targetCell: self.targetCell, clockwise: clockwise)
        self.orientation = flip.requiredOrientation
        self.occupiedCells = flip.occupiedCells
        self.flippingDirection = clockwise ? 1 : -1

        self.history.append(self.targetCell)
        if self.history.count > 2 {
            self.history.remove(at: 0)
        }

        progress = 0
    }
    
    public func initGrow() {
        self.state = "grow"
        self.progress = 0
        self.updatePosition()
    }

    public func initShrink() {
        self.state = "shrink"
        self.progress = 0
        self.updatePosition()
    }

    public func makeProgress() {
        self.progress += 1
        if self.state == "grow" {
            self.grow()
            if self.progress == stepDuration {
                self.state = "idle"
                self.age = 0
            }
        }
        else if self.state == "move" {
            let phase = Double(self.progress) / Double(stepDuration)
            // movedPhase: [0, 1] --> [0, 1]
//            self.flippingPhase = phase // linear
//            self.flippingPhase = 0.5 - 0.5 * cos(Double.pi * phase) // cosine-ish
//            self.flippingPhase = 0.5 - 0.5 * cbrt(cos(Double.pi * phase)) // accelerated cosine
            self.flippingPhase = -2*pow(phase, 3) + 3*pow(phase, 2) // cubic
//            self.flippingPhase = phase <= 0.5 ? 2*phase*phase : -phase*phase*2 + 4*phase-1 // pseudo-quadratic

            if self.progress == stepDuration {
                self.currentCell = self.targetCell
                self.flippingPhase = 0
                self.orientation = getCellType(cell: self.currentCell) == "up" ? 0 : 3
                self.state = "idle"
                self.age += 1
            }
        }
        else if self.state == "shrink" {
            self.shrink()
            if (self.progress == stepDuration) {
                self.state = "inactive"
                self.age += 1
            }
        }
        self.updatePosition()
    }

    public func getState() -> String {
        return self.state
    }

    public func getAge() -> UInt8 {
        return self.age
    }

    private func grow() {
        self.color = NSColor(red: self.color.redComponent, green: self.color.greenComponent, blue: self.color.blueComponent, alpha: CGFloat(Float(self.progress) / Float(stepDuration)))
    }

    private func shrink() {
        self.color = NSColor(red: self.color.redComponent, green: self.color.greenComponent, blue: self.color.blueComponent, alpha: 1.0 - CGFloat(Float(self.progress) / Float(stepDuration)))
    }
    
    public func draw() {
        let path : NSBezierPath = NSBezierPath()
        let anchorRotated: CGPoint = self.position
        let points: [NSPoint] = getTriangleVertices(anchorRotated: anchorRotated, angle: rotationActive ? currentWorldRotation+self.rotation : self.rotation)
        path.move(to: points[0])
        for point in points {
            path.line(to: NSPoint(x: point.x, y: point.y))
        }
        self.color.setFill()
        path.fill()
    }
    
    public func getOccupiedCells() -> [CGPoint] {
        return self.history
    }
    
    public func getBlockedCells() -> [CGPoint] {
        return [self.currentCell, self.targetCell]
    }

    public func getCurrentCell() -> CGPoint {
        return self.currentCell
    }
}

class trianglesView: ScreenSaverView {
    
    private var initTimer: UInt64 = 0
    private var triangles: [triangle] = []
    
    private var nrTriesPerCycle = 0

    // MARK: - Initialization
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func draw(_ rect: NSRect) {
        drawBackground(.black)
        //drawGravityVector()
        //drawTries()
        for activeTriangle in triangles {
            activeTriangle.draw()
        }
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        self.nrTriesPerCycle = 0
        
        if triangles.count < 1000 && Int(initTimer)%Int(spawnRelax) == 0 {
            for _ in 1...spawnAtOnce {
                createNewTriangle()
            }
        }
        initTimer += 1
        currentWorldRotation += worldRotationSpeed
        currentWorldRotation = currentWorldRotation.truncatingRemainder(dividingBy: 2*Double.pi)
        currentWorldRotationDegrees = currentWorldRotation / Double.pi * 180

        for activeTriangle in triangles {
            if activeTriangle.getState() == "idle" {
                if (activeTriangle.getAge() > minAge && Double.random(in: 0.0...1) < chanceOfDeath) || activeTriangle.getAge() >= maxAge {
                    activeTriangle.initShrink()
                }
                else {
                    let currentCell = activeTriangle.getCurrentCell()
                    var cellCandidates: [CGPoint] = []
                    var flipCandidates: [flip] = []

                    if getCellType(cell: currentCell) == "up" {
                        if currentWorldRotationDegrees >= 330 || currentWorldRotationDegrees < 30 {
                            // drop triangle to (x, y-1)
                            cellCandidates = [CGPoint(x: currentCell.x, y: currentCell.y-1)]
                        }
                        if currentWorldRotationDegrees >= 30 && currentWorldRotationDegrees < 90 {
                            // choose between (x, y-1) and (x+1, y)
                            cellCandidates = [CGPoint(x: currentCell.x, y: currentCell.y-1), CGPoint(x: currentCell.x+1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 90 && currentWorldRotationDegrees < 150 {
                            // drop triangle to (x+1, y)
                            cellCandidates = [CGPoint(x: currentCell.x+1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 150 && currentWorldRotationDegrees < 210 {
                            // choose between (x+1, y) and (x-1, y)
                            cellCandidates = [CGPoint(x: currentCell.x+1, y: currentCell.y), CGPoint(x: currentCell.x-1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 210 && currentWorldRotationDegrees < 270 {
                            // drop triangle to (x-1, y)
                            cellCandidates = [CGPoint(x: currentCell.x-1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 270 && currentWorldRotationDegrees < 330 {
                            // chosse between (x-1, y) and (x, y-1)
                            cellCandidates = [CGPoint(x: currentCell.x-1, y: currentCell.y), CGPoint(x: currentCell.x, y: currentCell.y-1)]
                        }
                    }
                    else {
                        if currentWorldRotationDegrees >= 330 || currentWorldRotationDegrees < 30 {
                            // choose between (x+1, y) and (x-1, y)
                            cellCandidates = [CGPoint(x: currentCell.x+1, y: currentCell.y), CGPoint(x: currentCell.x-1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 30 && currentWorldRotationDegrees < 90 {
                            // drop triangle to (x+1, y)
                            cellCandidates = [CGPoint(x: currentCell.x+1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 90 && currentWorldRotationDegrees < 150 {
                            // choose between (x, y+1) and (x+1, y)
                            cellCandidates = [CGPoint(x: currentCell.x, y: currentCell.y+1), CGPoint(x: currentCell.x+1, y: currentCell.y)]
                        }
                        if currentWorldRotationDegrees >= 150 && currentWorldRotationDegrees < 210 {
                            // drop triangle to (x, y+1)
                            cellCandidates = [CGPoint(x: currentCell.x, y: currentCell.y+1)]
                        }
                        if currentWorldRotationDegrees >= 210 && currentWorldRotationDegrees < 270 {
                            // chosse between (x-1, y) and (x, y+1)
                            cellCandidates = [CGPoint(x: currentCell.x-1, y: currentCell.y), CGPoint(x: currentCell.x, y: currentCell.y+1)]
                        }
                        if currentWorldRotationDegrees >= 270 && currentWorldRotationDegrees < 330 {
                            // drop triangle to (x-1, y)
                            cellCandidates = [CGPoint(x: currentCell.x-1, y: currentCell.y)]
                        }
                    }
                    
                    for cellCandidate in getOnlyCompletelyFreeCells(cellCandidates: cellCandidates) {
                        for flippingDirection in [false, true] {
                            let flipCandidate: flip = flip(currentCell: currentCell, targetCell: cellCandidate, clockwise: flippingDirection)
                            if !containsBlockedCells(cellCandidates: flipCandidate.occupiedCells) {
                                flipCandidates.append(flipCandidate)
                            }
                        }
                    }
                    if flipCandidates.count > 0 {
                        let flipToPerform: flip = flipCandidates.randomElement()!
                        activeTriangle.initNextMove(nextCell: flipToPerform.targetCell, clockwise: flipToPerform.clockwise)
                        continue
                    }

                    activeTriangle.initShrink()
                }
            }
            else {
                activeTriangle.makeProgress()
            }
        }

        // remove dead triangles
        var removedTriangles = 0
        for i in 0...triangles.count-1 {
            let index = i - removedTriangles
            if triangles[index].getState() == "inactive" {
                triangles.remove(at: index)
                removedTriangles += 1
            }
        }

        currentHue += hueSpeed
        setNeedsDisplay(bounds)
    }

    private func drawBackground(_ color: NSColor) {
        let background = NSBezierPath(rect: bounds)
        color.setFill()
        background.fill()
    }
    
    private func createNewTriangle() {
        let newTriangle = triangle()
        var cellCandidate: CGPoint
        var tries = 0
        let maxX: Int = Int(ceil(2*minRadius/triangleSideLength))
        let maxY: Int = Int(ceil(Double(maxX)/root3))
        repeat {
            cellCandidate = CGPoint(x: Int.random(in: -maxX..<maxX), y: Int.random(in: -maxY..<maxY))
            tries += 1
            self.nrTriesPerCycle += 1
        }
        while !cellIsCompletelyFree(cell: cellCandidate) && tries < triangles.count
        if cellIsCompletelyFree(cell: cellCandidate) {
            let hue: Double = Double.random(in: currentHue-hueVariation...currentHue+hueVariation).truncatingRemainder(dividingBy: 1)
            newTriangle.activate(cell: cellCandidate, newColor: NSColor(hue: hue, saturation: Double.random(in: max(sat-satVariation, 0)...min(sat+satVariation, 1)), brightness: Double.random(in: max(brt-brtVariation, 0)...min(brt+brtVariation, 1)), alpha: 0.0))
            triangles.append(newTriangle)
        }
    }
    
    private func cellIsBlocked(cell: CGPoint) -> Bool {
        for activeTriangle in triangles {
            for blockedCell in activeTriangle.getBlockedCells() {
                if cell == blockedCell {
                    return true
                }
            }
        }
        return false
    }
    
    private func containsBlockedCells(cellCandidates: [CGPoint]) -> Bool {
        for cellCandidate in cellCandidates {
            if cellIsBlocked(cell: cellCandidate) {
                return true
            }
        }
        return false
    }
    
    private func cellIsOccupied(cell: CGPoint) -> Bool {
        for activeTriangle in triangles {
            for occupiedCell in activeTriangle.getBlockedCells() {
                if cell == occupiedCell {
                    return true
                }
            }
        }
        return false
    }
    
    private func cellIsCompletelyFree(cell: CGPoint) -> Bool {
        return !cellIsOccupied(cell: cell) && !cellIsBlocked(cell: cell)
    }
    
    private func getOnlyCompletelyFreeCells(cellCandidates: [CGPoint]) -> [CGPoint] {
        var completelyFreeCells: [CGPoint] = []
        for cellCandidate in cellCandidates {
            if cellIsCompletelyFree(cell: cellCandidate) {
                completelyFreeCells.append(cellCandidate)
            }
        }
        return completelyFreeCells
    }
    
    private func drawGravityVector() {
        let path : NSBezierPath = NSBezierPath()
        path.move(to: CGPoint(x:100, y:100))
        path.line(to: CGPoint(x: 100+50*sin(currentWorldRotation), y: 100+50*cos(currentWorldRotation)))
        NSColor.white.set()
        path.stroke()
    }
    
    private func drawTries() {
        let path : NSBezierPath = NSBezierPath()
        path.move(to: CGPoint(x:0, y:25))
        path.line(to: CGPoint(x: self.nrTriesPerCycle, y: 25))
        NSColor.red.set()
        path.stroke()
    }
}
