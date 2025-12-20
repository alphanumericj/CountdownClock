import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private var hrvQuery: HKAnchoredObjectQuery?

    // HRV type (SDNN)
    private var hrvType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
    }

    // Request HealthKit authorization for HRV
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let hrvType else { completion(false); return }
        let toRead: Set = [hrvType]
        healthStore.requestAuthorization(toShare: [], read: toRead) { success, _ in
            completion(success)
        }
    }

    // Start observing HRV updates via background delivery and anchored query
    func startObservingHRV(thresholdInMilliseconds: Double, onUpdate: @escaping (_ latestHRVms: Double?) -> Void) {
        guard let hrvType else { onUpdate(nil); return }

        // Set up observer query for background delivery
        let observerQuery = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completionHandler, error in
            // Optionally handle the error
            if let error {
                // You could log this, or just proceed to fetch the latest HRV anyway
                // print("Observer error: \(error.localizedDescription)")
            }

            self?.fetchLatestHRV { value in
                onUpdate(value)
                completionHandler()
            }
        }

        healthStore.execute(observerQuery)
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { _, _ in }

        // Also perform an initial fetch so we have a value right away
        fetchLatestHRV { value in
            onUpdate(value)
        }
    }

    // Fetch the most recent HRV sample value (in milliseconds)
    func fetchLatestHRV(completion: @escaping (Double?) -> Void) {
        guard let hrvType else { completion(nil); return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let unit = HKUnit.secondUnit(with: .milli)
            let value = sample.quantity.doubleValue(for: unit)
            completion(value)
        }
        healthStore.execute(query)
    }
}

