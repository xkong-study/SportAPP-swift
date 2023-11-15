import CoreMotion
import Foundation

class WorkoutSessionManager {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var liftCount = 0
    private var lastAcceleration: Double = 0.0
    var onRepsCounted: ((Int) -> Void)?
    private var repsThisMinute = 0
    private var secondsElapsed = 0
    var useMockData: Bool = false // Flag to determine whether to use mock data

    init() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = 0.1
    }
    
    func startSession() {
        // Initialize counter and seconds elapsed
        repsThisMinute = 0
        secondsElapsed = 0
        liftCount = 0

        if useMockData {
            // Start generating mock data
            generateMockData()
        } else {
            // Start real accelerometer updates
            motionManager.startAccelerometerUpdates()
            motionManager.startGyroUpdates()
        }
        
        // Start the timer to check motion data every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.secondsElapsed += 1

            if self?.useMockData == true {
                // Process mock motion data
                let mockData = self?.generateMockAccelerometerData()
                self?.processMockMotion(mockData)
            } else if let accelerometerData = self?.motionManager.accelerometerData {
                // Process real motion data
                self?.processMotion(accelerometerData: accelerometerData)
            }

            // Check if a minute has passed
            if self?.secondsElapsed ?? 0 >= 60 {
                // One minute has passed, call the closure with the data
                self?.onRepsCounted?(self?.repsThisMinute ?? 0)
                print(self?.repsThisMinute ?? 0)
                // Reset the counter and timer
                self?.repsThisMinute = 0
                self?.secondsElapsed = 0
            }
        }
    }
    
    private func processMotion(accelerometerData: CMAccelerometerData) {
        let acceleration = accelerometerData.acceleration
        let accelerationTuple = (x: acceleration.x, y: acceleration.y, z: acceleration.z)
        processAcceleration(accelerationTuple)
    }

    private func processMockMotion(_ mockData: (x: Double, y: Double, z: Double)?) {
        if let mockData = mockData {
            processAcceleration(mockData)
        }
    }
    
    private func processAcceleration(_ acceleration: (x: Double, y: Double, z: Double)) {
        let totalAcceleration = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))

        let liftingThreshold: Double = 1.2
        if totalAcceleration > liftingThreshold && abs(totalAcceleration - lastAcceleration) > 0.5 {
            liftCount += 1
            repsThisMinute += 1
        }
        lastAcceleration = totalAcceleration
    }
    
    private func generateMockAccelerometerData() -> (x: Double, y: Double, z: Double) {
        let x = 1 + Double.random(in: -0.5...0.5) + Double.random(in: 0...2)
        let y = 1 + Double.random(in: -0.5...0.5) + Double.random(in: 0...2)
        let z = 1 + Double.random(in: -0.5...0.5) + Double.random(in: 0...2)
        return (x, y, z)
    }
    
    private func generateMockData() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if self?.secondsElapsed ?? 0 >= 60 {
                self?.timer?.invalidate()
                self?.timer = nil
                if let repsThisMinute = self?.repsThisMinute, repsThisMinute > 0 {
                    self?.onRepsCounted?(repsThisMinute)
                    print(repsThisMinute)
                }
                self?.repsThisMinute = 0
                self?.secondsElapsed = 0
                return
            }
            
            let mockData = self?.generateMockAccelerometerData()
            self?.processMockMotion(mockData)
            self?.secondsElapsed += 1
        }
    }
    
    func stopSession() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        timer?.invalidate()
    }
}
