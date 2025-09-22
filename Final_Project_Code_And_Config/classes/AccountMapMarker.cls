/**
 * @description Data Transfer Object for Account map markers used by the Account Map Lightning Web Component
 * Contains the essential account information needed to display interactive markers on a map
 * 
 * @author System Administrator
 * @since 2025-01-21
 */
public with sharing class AccountMapMarker {
    
    /**
     * @description Unique identifier for the Account record
     */
    @AuraEnabled
    public String accountId { get; set; }
    
    /**
     * @description Account name to display on the marker
     */
    @AuraEnabled
    public String name { get; set; }
    
    /**
     * @description Latitude coordinate for map positioning
     */
    @AuraEnabled
    public Decimal latitude { get; set; }
    
    /**
     * @description Longitude coordinate for map positioning
     */
    @AuraEnabled
    public Decimal longitude { get; set; }
    
    /**
     * @description Rich description text displayed when hovering over the marker
     * Contains account name, annual revenue, phone, and full address
     */
    @AuraEnabled
    public String description { get; set; }
    
    /**
     * @description Icon name for the map marker (optional)
     */
    @AuraEnabled
    public String icon { get; set; }
    
    /**
     * @description Default constructor
     */
    public AccountMapMarker() {
        this.icon = 'custom:custom26'; // Default to building/office icon
    }
    
    /**
     * @description Constructor with essential parameters
     * @param accountId The Account record Id
     * @param name The Account name
     * @param latitude The shipping latitude
     * @param longitude The shipping longitude
     * @param description The formatted description for the marker
     */
    public AccountMapMarker(String accountId, String name, Decimal latitude, Decimal longitude, String description) {
        this.accountId = accountId;
        this.name = name;
        this.latitude = latitude;
        this.longitude = longitude;
        this.description = description;
        this.icon = 'custom:custom26';
    }
}
