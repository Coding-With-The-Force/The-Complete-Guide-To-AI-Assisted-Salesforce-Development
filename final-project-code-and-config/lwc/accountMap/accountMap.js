import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitialMarkers from '@salesforce/apex/AccountMapController.getInitialMarkers';
import getMarkersNearAccountName from '@salesforce/apex/AccountMapController.getMarkersNearAccountName';

// Import Custom Labels
import CARD_TITLE from '@salesforce/label/c.AccountMap_Title';
import SEARCH_LABEL from '@salesforce/label/c.AccountMap_SearchLabel';
import SEARCH_PLACEHOLDER from '@salesforce/label/c.AccountMap_SearchPlaceholder';
import ERROR_TITLE from '@salesforce/label/c.AccountMap_ErrorTitle';
import NO_ACCOUNTS_FOUND from '@salesforce/label/c.AccountMap_NoAccountsFound';
import LOADING_MESSAGE from '@salesforce/label/c.AccountMap_LoadingMessage';

/**
 * Account Map Lightning Web Component
 * Displays Account records with geolocation data on an interactive map
 * Allows users to search for accounts within a configurable radius
 */
export default class AccountMap extends LightningElement {
    
    // Public API properties - configurable in App Builder
    @api radiusMiles = 50;
    @api initialLimit = 500;
    
    // Private tracked properties
    @track mapMarkers = [];
    @track searchTerm = '';
    @track errorMessage = '';
    @track isLoading = false;
    
    // Labels for UI text
    cardTitle = CARD_TITLE;
    searchLabel = SEARCH_LABEL;
    searchPlaceholder = SEARCH_PLACEHOLDER;
    errorTitle = ERROR_TITLE;
    noAccountsMessage = NO_ACCOUNTS_FOUND;
    loadingMessage = LOADING_MESSAGE;
    
    /**
     * Wire adapter to load initial account markers on component initialization
     */
    @wire(getInitialMarkers, { limitSize: '$initialLimit' })
    wiredInitialMarkers({ error, data }) {
        if (data) {
            this.mapMarkers = this.transformMarkersForMap(data);
            this.clearError();
        } else if (error) {
            this.handleError('Failed to load initial account locations', error);
            this.mapMarkers = [];
        }
    }
    
    /**
     * Computed property to check if map has markers to display
     */
    get hasMapMarkers() {
        return this.mapMarkers && this.mapMarkers.length > 0;
    }
    
    /**
     * Handles search input changes
     * @param {Event} event - Input change event
     */
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.clearError();
    }
    
    /**
     * Handles keydown events on the search input
     * Triggers search when Enter key is pressed
     * @param {Event} event - Keydown event
     */
    handleKeyDown(event) {
        if (event.keyCode === 13) { // Enter key
            event.preventDefault();
            this.searchNearbyAccounts();
        }
    }
    
    /**
     * Searches for accounts near the specified account name
     * Makes imperative Apex call for nearby account search
     */
    async searchNearbyAccounts() {
        if (!this.searchTerm || this.searchTerm.trim().length === 0) {
            this.showToast('Warning', 'Please enter an account name to search', 'warning');
            return;
        }
        
        this.isLoading = true;
        this.clearError();
        
        try {
            const result = await getMarkersNearAccountName({
                accountName: this.searchTerm.trim(),
                radiusMiles: this.radiusMiles
            });
            
            if (result && result.length > 0) {
                this.mapMarkers = this.transformMarkersForMap(result);
                this.showToast('Success', 
                    `Found ${result.length} account(s) within ${this.radiusMiles} miles`, 
                    'success');
            } else {
                this.mapMarkers = [];
                this.errorMessage = `No accounts found within ${this.radiusMiles} miles of "${this.searchTerm}"`;
            }
        } catch (error) {
            this.handleError('Search failed', error);
            this.mapMarkers = [];
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * Transforms Apex response markers into lightning-map compatible format
     * @param {Array} markers - Array of AccountMapMarker objects from Apex
     * @returns {Array} Array of markers formatted for lightning-map component
     */
    transformMarkersForMap(markers) {
        if (!markers || !Array.isArray(markers)) {
            return [];
        }
        
        return markers.map(marker => ({
            location: {
                Latitude: marker.latitude,
                Longitude: marker.longitude,
                Name: marker.name,
                Street: '', // Not needed as we have description
                City: '',   // Not needed as we have description
                PostalCode: '', // Not needed as we have description
                State: '',  // Not needed as we have description
                Country: '' // Not needed as we have description
            },
            title: marker.name,
            description: marker.description,
            icon: marker.icon || 'standard:account',
            value: marker.accountId
        }));
    }
    
    /**
     * Handles errors and displays user-friendly error messages
     * @param {String} message - User-friendly error message
     * @param {Object} error - Error object from Apex or JavaScript
     */
    handleError(message, error) {
        console.error('AccountMap Error:', error);
        
        // Extract meaningful error message
        let errorDetail = '';
        if (error && error.body) {
            if (error.body.message) {
                errorDetail = error.body.message;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                errorDetail = error.body.pageErrors[0].message;
            }
        } else if (error && error.message) {
            errorDetail = error.message;
        }
        
        this.errorMessage = errorDetail || message;
        this.showToast('Error', this.errorMessage, 'error');
    }
    
    /**
     * Clears any existing error messages
     */
    clearError() {
        this.errorMessage = '';
    }
    
    /**
     * Shows toast notification to user
     * @param {String} title - Toast title
     * @param {String} message - Toast message
     * @param {String} variant - Toast variant (success, error, warning, info)
     */
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }
    
    /**
     * Component lifecycle - called when component is connected to DOM
     * Used for any initialization that requires DOM presence
     */
    connectedCallback() {
        // Initialize component if needed
        this.clearError();
    }
    
    /**
     * Component lifecycle - called when component is disconnected from DOM
     * Used for cleanup if needed
     */
    disconnectedCallback() {
        // Cleanup if needed
    }
}
