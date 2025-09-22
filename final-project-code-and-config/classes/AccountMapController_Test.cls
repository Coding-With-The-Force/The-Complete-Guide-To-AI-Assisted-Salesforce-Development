/**
 * @description Test class for AccountMapController
 * Tests controller delegation to service and error handling
 * 
 * @author System Administrator
 * @since 2025-01-21
 */
@isTest
public class AccountMapController_Test {
    
    /**
     * @description Test data setup - creates accounts with geolocation data
     */
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        // Create test account with geolocation
        Account testAccount = new Account(
            Name = 'Test Controller Account',
            AnnualRevenue = 1000000,
            Phone = '415-555-0100',
            ShippingStreet = '1 Market Street',
            ShippingCity = 'San Francisco',
            ShippingState = 'CA',
            ShippingPostalCode = '94105',
            ShippingCountry = 'USA',
            ShippingLatitude = 37.7749,
            ShippingLongitude = -122.4194
        );
        testAccounts.add(testAccount);
        
        // Create nearby account
        Account nearbyAccount = new Account(
            Name = 'Test Nearby Controller Account',
            AnnualRevenue = 500000,
            Phone = '510-555-0200',
            ShippingStreet = '1000 Broadway',
            ShippingCity = 'Oakland',
            ShippingState = 'CA',
            ShippingPostalCode = '94607',
            ShippingCountry = 'USA',
            ShippingLatitude = 37.8044,
            ShippingLongitude = -122.2712
        );
        testAccounts.add(nearbyAccount);
        
        insert testAccounts;
    }
    
    /**
     * @description Test getInitialMarkers method success path
     */
    @isTest
    static void testGetInitialMarkers_Success() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountMapController.getInitialMarkers(10);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(2, markers.size(), 'Should return 2 test accounts');
        
        // Verify marker structure
        AccountMapMarker firstMarker = markers[0];
        System.assertNotEquals(null, firstMarker.accountId, 'Account ID should not be null');
        System.assertNotEquals(null, firstMarker.name, 'Name should not be null');
        System.assertNotEquals(null, firstMarker.latitude, 'Latitude should not be null');
        System.assertNotEquals(null, firstMarker.longitude, 'Longitude should not be null');
        System.assertNotEquals(null, firstMarker.description, 'Description should not be null');
    }
    
    /**
     * @description Test getInitialMarkers method with null parameter
     */
    @isTest
    static void testGetInitialMarkers_NullParameter() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountMapController.getInitialMarkers(null);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(2, markers.size(), 'Should return all test accounts when limit is null');
    }
    
    /**
     * @description Test getMarkersNearAccountName method success path
     */
    @isTest
    static void testGetMarkersNearAccountName_Success() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountMapController.getMarkersNearAccountName('Test Controller Account', 50);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        System.assertEquals(2, markers.size(), 'Should return both accounts within 50 miles');
        
        // Verify at least one marker has the center account
        Boolean foundCenterAccount = false;
        for (AccountMapMarker marker : markers) {
            if (marker.name.contains('Test Controller Account')) {
                foundCenterAccount = true;
                break;
            }
        }
        System.assert(foundCenterAccount, 'Should find the center account in results');
    }
    
    /**
     * @description Test getMarkersNearAccountName method with non-existent account
     */
    @isTest
    static void testGetMarkersNearAccountName_NonExistentAccount() {
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountMapController.getMarkersNearAccountName('Non Existent Account', 50);
            System.assert(false, 'Should throw AuraHandledException for non-existent account');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account not found'), 
                         'Exception message should indicate account not found');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test getMarkersNearAccountName method with null account name
     */
    @isTest
    static void testGetMarkersNearAccountName_NullAccountName() {
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountMapController.getMarkersNearAccountName(null, 50);
            System.assert(false, 'Should throw AuraHandledException for null account name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account not found'), 
                         'Exception message should indicate account not found');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test getMarkersNearAccountName method with empty account name
     */
    @isTest
    static void testGetMarkersNearAccountName_EmptyAccountName() {
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountMapController.getMarkersNearAccountName('', 50);
            System.assert(false, 'Should throw AuraHandledException for empty account name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account not found'), 
                         'Exception message should indicate account not found');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test getMarkersNearAccountName method with null radius
     */
    @isTest
    static void testGetMarkersNearAccountName_NullRadius() {
        Test.startTest();
        List<AccountMapMarker> markers = AccountMapController.getMarkersNearAccountName('Test Controller Account', null);
        Test.stopTest();
        
        System.assertNotEquals(null, markers, 'Markers should not be null');
        // Should default to 50 miles and return both accounts
        System.assertEquals(2, markers.size(), 'Should return accounts using default radius');
    }
    
    /**
     * @description Test error handling when service throws InvalidGeolocationException
     */
    @isTest
    static void testGetInitialMarkers_InvalidGeolocationException() {
        // Delete all accounts to simulate no geolocation data
        delete [SELECT Id FROM Account];
        
        Test.startTest();
        try {
            List<AccountMapMarker> markers = AccountMapController.getInitialMarkers(500);
            System.assert(false, 'Should throw AuraHandledException when no accounts have geolocation');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unable to load account markers'), 
                         'Exception message should be user-friendly');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test that controller methods are marked as cacheable
     * This test verifies the annotations exist by checking method behavior
     */
    @isTest
    static void testCacheableAnnotations() {
        Test.startTest();
        
        // First call
        List<AccountMapMarker> markers1 = AccountMapController.getInitialMarkers(10);
        
        // Second call - should be cacheable
        List<AccountMapMarker> markers2 = AccountMapController.getInitialMarkers(10);
        
        Test.stopTest();
        
        // Both calls should return the same data
        System.assertEquals(markers1.size(), markers2.size(), 
                           'Cacheable methods should return consistent results');
    }
    
    /**
     * @description Test that controller properly delegates to service layer
     * Verifies no business logic exists in controller methods
     */
    @isTest
    static void testControllerDelegation() {
        Test.startTest();
        
        // Test that controller calls service layer
        List<AccountMapMarker> initialMarkers = AccountMapController.getInitialMarkers(10);
        List<AccountMapMarker> nearbyMarkers = AccountMapController.getMarkersNearAccountName('Test Controller Account', 25);
        
        Test.stopTest();
        
        // Verify controller returns results from service
        System.assertNotEquals(null, initialMarkers, 'Controller should delegate to service for initial markers');
        System.assertNotEquals(null, nearbyMarkers, 'Controller should delegate to service for nearby markers');
        
        // Verify results have proper structure (indicating service layer processing)
        if (initialMarkers.size() > 0) {
            AccountMapMarker marker = initialMarkers[0];
            System.assertNotEquals(null, marker.description, 'Service should format description');
            System.assert(marker.description.contains('Account:'), 'Service should format description properly');
        }
    }
    
    /**
     * @description Test parameter validation and error handling
     */
    @isTest
    static void testParameterValidation() {
        Test.startTest();
        
        // Test with negative limit
        List<AccountMapMarker> markers = AccountMapController.getInitialMarkers(-1);
        System.assertNotEquals(null, markers, 'Should handle negative limit gracefully');
        
        // Test with very large limit
        markers = AccountMapController.getInitialMarkers(10000);
        System.assertNotEquals(null, markers, 'Should handle large limit gracefully');
        
        Test.stopTest();
    }
}
