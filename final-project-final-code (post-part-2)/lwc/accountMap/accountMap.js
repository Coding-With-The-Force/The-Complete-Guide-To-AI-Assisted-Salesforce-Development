import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitialMarkers from '@salesforce/apex/AccountMapController.getInitialMarkers';
import getMarkersNearAccountName from '@salesforce/apex/AccountMapController.getMarkersNearAccountName';
import getMarkersByState from '@salesforce/apex/AccountMapController.getMarkersByState';
import getMarkersByZipCode from '@salesforce/apex/AccountMapController.getMarkersByZipCode';

// Import Custom Labels
import CARD_TITLE from '@salesforce/label/c.AccountMap_Title';
import SEARCH_LABEL from '@salesforce/label/c.AccountMap_SearchLabel';
import SEARCH_PLACEHOLDER from '@salesforce/label/c.AccountMap_SearchPlaceholder';
import ERROR_TITLE from '@salesforce/label/c.AccountMap_ErrorTitle';
import NO_ACCOUNTS_FOUND from '@salesforce/label/c.AccountMap_NoAccountsFound';
import LOADING_MESSAGE from '@salesforce/label/c.AccountMap_LoadingMessage';
import STATE_LABEL from '@salesforce/label/c.AccountMap_StateLabel';
import STATE_PLACEHOLDER from '@salesforce/label/c.AccountMap_StatePlaceholder';
import ZIP_LABEL from '@salesforce/label/c.AccountMap_ZipLabel';
import ZIP_PLACEHOLDER from '@salesforce/label/c.AccountMap_ZipPlaceholder';
import CLEAR_FILTERS_LABEL from '@salesforce/label/c.AccountMap_ClearFiltersLabel';

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
    @track selectedState = '';
    @track zipCode = '';
    @track errorMessage = '';
    @track isLoading = false;
    
    // Labels for UI text
    cardTitle = CARD_TITLE;
    searchLabel = SEARCH_LABEL;
    searchPlaceholder = SEARCH_PLACEHOLDER;
    errorTitle = ERROR_TITLE;
    noAccountsMessage = NO_ACCOUNTS_FOUND;
    loadingMessage = LOADING_MESSAGE;
    stateLabel = STATE_LABEL;
    statePlaceholder = STATE_PLACEHOLDER;
    zipLabel = ZIP_LABEL;
    zipPlaceholder = ZIP_PLACEHOLDER;
    clearFiltersLabel = CLEAR_FILTERS_LABEL;
    
    // US States options for combobox
    stateOptions = [
        { label: 'Alabama', value: 'AL' },
        { label: 'Alaska', value: 'AK' },
        { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' },
        { label: 'California', value: 'CA' },
        { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' },
        { label: 'Delaware', value: 'DE' },
        { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' },
        { label: 'Hawaii', value: 'HI' },
        { label: 'Idaho', value: 'ID' },
        { label: 'Illinois', value: 'IL' },
        { label: 'Indiana', value: 'IN' },
        { label: 'Iowa', value: 'IA' },
        { label: 'Kansas', value: 'KS' },
        { label: 'Kentucky', value: 'KY' },
        { label: 'Louisiana', value: 'LA' },
        { label: 'Maine', value: 'ME' },
        { label: 'Maryland', value: 'MD' },
        { label: 'Massachusetts', value: 'MA' },
        { label: 'Michigan', value: 'MI' },
        { label: 'Minnesota', value: 'MN' },
        { label: 'Mississippi', value: 'MS' },
        { label: 'Missouri', value: 'MO' },
        { label: 'Montana', value: 'MT' },
        { label: 'Nebraska', value: 'NE' },
        { label: 'Nevada', value: 'NV' },
        { label: 'New Hampshire', value: 'NH' },
        { label: 'New Jersey', value: 'NJ' },
        { label: 'New Mexico', value: 'NM' },
        { label: 'New York', value: 'NY' },
        { label: 'North Carolina', value: 'NC' },
        { label: 'North Dakota', value: 'ND' },
        { label: 'Ohio', value: 'OH' },
        { label: 'Oklahoma', value: 'OK' },
        { label: 'Oregon', value: 'OR' },
        { label: 'Pennsylvania', value: 'PA' },
        { label: 'Rhode Island', value: 'RI' },
        { label: 'South Carolina', value: 'SC' },
        { label: 'South Dakota', value: 'SD' },
        { label: 'Tennessee', value: 'TN' },
        { label: 'Texas', value: 'TX' },
        { label: 'Utah', value: 'UT' },
        { label: 'Vermont', value: 'VT' },
        { label: 'Virginia', value: 'VA' },
        { label: 'Washington', value: 'WA' },
        { label: 'West Virginia', value: 'WV' },
        { label: 'Wisconsin', value: 'WI' },
        { label: 'Wyoming', value: 'WY' }
    ];
    
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
     * Handles state selection change
     * @param {Event} event - Change event from lightning-combobox
     */
    handleStateChange(event) {
        this.selectedState = event.detail.value;
        this.clearError();
        this.applyFilters();
    }

    /**
     * Handles zip code input change
     * @param {Event} event - Change event from lightning-input
     */
    handleZipChange(event) {
        this.zipCode = event.detail.value;
        this.clearError();
        
        // Validate zip code format (5 digits)
        const zipPattern = /^\d{5}$/;
        if (this.zipCode && !zipPattern.test(this.zipCode)) {
            this.showToast('Warning', 'Please enter a valid 5-digit zip code', 'warning');
            return;
        }
        
        this.applyFilters();
    }

    /**
     * Clears all filters and reloads initial data
     */
    handleClearFilters() {
        this.selectedState = '';
        this.zipCode = '';
        this.searchTerm = '';
        this.clearError();
        this.loadInitialData();
    }

    /**
     * Applies filters based on current filter precedence (Zip > State > Search > Initial)
     */
    async applyFilters() {
        if (this.zipCode && this.zipCode.length === 5) {
            await this.filterByZipCode();
        } else if (this.selectedState) {
            await this.filterByState();
        } else {
            this.loadInitialData();
        }
    }

    /**
     * Filters accounts by selected state
     */
    async filterByState() {
        if (!this.selectedState) return;
        
        this.isLoading = true;
        this.clearError();
        
        try {
            const result = await getMarkersByState({
                state: this.selectedState,
                limitSize: this.initialLimit
            });
            
            if (result && result.length > 0) {
                this.mapMarkers = this.transformMarkersForMap(result);
                this.showToast('Success', 
                    `Found ${result.length} account(s) in ${this.selectedState}`, 
                    'success');
            } else {
                this.mapMarkers = [];
                this.errorMessage = `No accounts found in state: ${this.selectedState}`;
            }
        } catch (error) {
            this.handleError('State filter failed', error);
            this.mapMarkers = [];
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Filters accounts by zip code
     */
    async filterByZipCode() {
        if (!this.zipCode) return;
        
        this.isLoading = true;
        this.clearError();
        
        try {
            const result = await getMarkersByZipCode({
                zipCode: this.zipCode,
                limitSize: this.initialLimit
            });
            
            if (result && result.length > 0) {
                this.mapMarkers = this.transformMarkersForMap(result);
                this.showToast('Success', 
                    `Found ${result.length} account(s) in zip code ${this.zipCode}`, 
                    'success');
            } else {
                this.mapMarkers = [];
                this.errorMessage = `No accounts found in zip code: ${this.zipCode}`;
            }
        } catch (error) {
            this.handleError('Zip code filter failed', error);
            this.mapMarkers = [];
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Loads initial data (used for clear filters and component initialization)
     */
    loadInitialData() {
        // Trigger wire refresh by setting a tracked property
        this.initialLimit = this.initialLimit || 500;
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