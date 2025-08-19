import Foundation
import Stripe

struct StripeConfig {
    static func setup() {
        // Configure Stripe with your test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51RxiiPL8qxdTvImxtSLycaHvcSeJhKx3ckurU5eQCvfYqK60zifYgt6ofCIUeysY4FqOBLUzTsPdRAEi1sjxk0jQ00k8qCQ3cu"
        
        // Log successful configuration
        print("✅ Stripe configured successfully")
        print("📱 Publishable key: \(String(StripeAPI.defaultPublishableKey.prefix(20)))...")
        
        // Validate configuration
        if StripeAPI.defaultPublishableKey.contains("pk_test_") {
            print("🔧 Using Stripe TEST environment")
        } else if StripeAPI.defaultPublishableKey.contains("pk_live_") {
            print("🚀 Using Stripe PRODUCTION environment")
        } else {
            print("⚠️ WARNING: Invalid Stripe key format")
        }
    }
    
    // Check if Stripe is properly configured
    static var isConfigured: Bool {
        return !StripeAPI.defaultPublishableKey.isEmpty && 
               !StripeAPI.defaultPublishableKey.contains("your_")
    }
    
    // Get the current environment
    static var environment: String {
        if StripeAPI.defaultPublishableKey.contains("pk_test_") {
            return "test"
        } else if StripeAPI.defaultPublishableKey.contains("pk_live_") {
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
        print("🔑 Key type: \(StripeAPI.defaultPublishableKey.contains("pk_test_") ? "Test" : "Production")")
    }
} 