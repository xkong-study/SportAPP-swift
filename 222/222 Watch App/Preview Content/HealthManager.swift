//
//  HealthManager.swift
//  222 Watch App
//
//  Created by チョ・ゴケン on 2023/10/22.
//

import Foundation
import HealthKit

class HealthManager {
    let healthStore = HKHealthStore()
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            fatalError("Heart Rate is no longer available in HealthKit")
        }
        
        let typesToShare: Set<HKSampleType> = [heartRateType]
        let typesToRead: Set<HKObjectType> = [heartRateType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            completion(success, error)
        }
    }

    func addMockHeartRateData(heartRateValue: Double, completion: @escaping (Bool, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: heartRateValue)
        
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: Date(), end: Date())
        
        healthStore.save(heartRateSample) { (success, error) in
            completion(success, error)
        }
    }

    
    func fetchLatestHeartRateSample(completion: @escaping (Double, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // Broaden the predicate for troubleshooting purposes
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        let sampleQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            if let error = error {
                completion(0, error)
                return
            }
            guard let sample = samples?.first as? HKQuantitySample else {
                let noDataError = NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No heart rate samples available."])
                completion(0, noDataError)
                return
            }
            
            let heartRateUnit = HKUnit(from: "count/min")
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            completion(heartRate, nil)
        }

        self.healthStore.execute(sampleQuery)
    }

    
    func startHeartRateStreamingQuery(completion: @escaping (Double, Error?) -> Void) {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { (query, completionHandler, error) in
            if let error = error {
                completion(0, error)
                return
            }
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let sampleQuery = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(0, error)
                    return
                }
                
                let heartRateUnit = HKUnit(from: "count/min")
                let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                completion(heartRate, nil)
            }
            
            self.healthStore.execute(sampleQuery)
            completionHandler()
        }
        
        healthStore.execute(query)
    }
}

