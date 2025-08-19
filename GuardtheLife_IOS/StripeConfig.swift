import Foundation
import Stripe

struct StripeConfig {
    static func setup() {
        // Configure Stripe with your test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51RxiiPL8qxdTvImxtSLycaHvcSeJhKx3ckurU5eQCvfYqK60zifYgt6ofCIUeysY4FqOBLUzTsPdRAEi1sjxk0jQ00k8qCQ3cu"
        
        // Log successful configuration
        print("✅ Stripe configured successfully")
        if let publishableKey = StripeAPI.defaultPublishableKey {
            print("📱 Publishable key: \(String(publishableKey.prefix(20)))...")
        }
        
        // Validate configuration
        if let publishableKey = StripeAPI.defaultPublishableKey {
            if publishableKey.contains("pk_test_") {
                print("🔧 Using Stripe TEST environment")
            } else if publishableKey.contains("pk_live_") {
                print("🚀 Using Stripe PRODUCTION environment")
            } else {
                print("⚠️ WARNING: Invalid Stripe key format")
            }
        }
    }
    
    // Check if Stripe is properly configured
    static var isConfigured: Bool {
        guard let publishableKey = StripeAPI.defaultPublishableKey else {
            return false
        }
        return !publishableKey.isEmpty && !publishableKey.contains("your_")
    }
    
    // Get the current environment
    static var environment: String {
        guard let publishableKey = StripeAPI.defaultPublishableKey else {
            return "unknown"
        }
        if publishableKey.contains("pk_test_") {
            return "test"
        } else if publishableKey.contains("pk_live_") {
            return "production"
        } else {
            return "unknown"
        }
    }
    
    // Validate the current configuration
    static func validateConfiguration() {
        guard isConfigured else {
            print("❌ Stripe is not properly configured!")
            return
        }
        
        print("✅ Stripe configuration is valid")
        print("🌍 Environment: \(environment)")
        if let publishableKey = StripeAPI.defaultPublishableKey {
            print("🔑 Key type: \(publishableKey.contains("pk_test_") ? "Test" : "Production")")
        }
    }
} 