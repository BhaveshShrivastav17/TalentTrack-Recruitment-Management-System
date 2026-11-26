import getAllCandidates from '@salesforce/apex/JobListingController.getAllCandidates';
// Import LightningElement to create our component
// Import wire to fetch Salesforce records automatically
import { LightningElement, wire } from 'lwc';

// Import Apex method that fetches all Open Jobs
import getOpenJobs from '@salesforce/apex/JobListingController.getOpenJobs';

// Import Apex method to fetch eligible candidates
import getEligibleCandidates from '@salesforce/apex/JobListingController.getEligibleCandidates';

// Import Apex method to create a job application
import submitApplication from '@salesforce/apex/JobListingController.submitApplication';

// Import Salesforce toast notifications
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Apex method to fetch a candidate's application history
import getCandidateApplications from '@salesforce/apex/JobListingController.getCandidateApplications';


export default class JobListing extends LightningElement {

    // Stores all jobs received from Salesforce
    jobs;

    // Stores any error received while fetching jobs
    error;

    // Controls the loading spinner
    isLoading = true;

    // Stores the text entered in the search box
    searchKey = '';

    // Stores the department selected in the dropdown
    selectedDepartment = '';

    // Department options displayed in the dropdown
    departmentOptions = [
        { label: 'All Departments', value: '' },
        { label: 'IT', value: 'IT' },
        { label: 'HR', value: 'HR' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Sales', value: 'Sales' }
    ];

    // Stores candidates available for applying
    candidateOptions = [];

    statusCandidateOptions = [];

    // Stores the candidate selected for checking application status
    selectedStatusCandidateId = '';

    // Stores the applications retrieved from Salesforce
    candidateApplications = [];

    // Controls visibility of application history
    showApplicationStatus = false;

    // Controls the loading spinner for application history
    isLoadingApplications = false;

    // Stores the selected job record ID
    selectedJobId;

    // Stores the selected candidate record ID
    selectedCandidateId = '';

    // Controls visibility of the application form
    showApplyForm = false;

    // Controls the submission loading state
    isSubmitting = false;


    // Fetch eligible candidates from Salesforce
    @wire(getEligibleCandidates)
    wiredCandidates({ data, error }) {

        if (data) {

            // Convert candidate records into dropdown options
            this.candidateOptions = data.map(candidate => ({
                label: candidate.First_Name__c + ' ' + candidate.Last_Name__c,
                value: candidate.Id
            }));

        } else if (error) {

            console.error('Error fetching candidates:', error);
        }
    }

    @wire(getAllCandidates)
    wiredAllCandidates({ data, error }) {
        if (data) {
            this.statusCandidateOptions = data.map(candidate => ({
                label: candidate.First_Name__c + ' ' + candidate.Last_Name__c,
                value: candidate.Id
            }));
        } else if (error) {
            console.error('Error fetching all candidates:', error);
        }
    }

    // Fetch Open Jobs from the Apex controller
    @wire(getOpenJobs)
    wiredJobs({ data, error }) {

        // Stop displaying the loading spinner
        this.isLoading = false;

        if (data) {
            // Store the jobs returned by Salesforce
            this.jobs = data;
            this.error = undefined;

        } else if (error) {
            // Store the error if job fetching fails
            this.error = error;
            this.jobs = undefined;

            console.error('Error fetching jobs:', error);
        }
    }

    // Runs whenever the user types in the search box
    handleSearch(event) {

        // Convert the entered text to lowercase
        // This makes searching case-insensitive
        this.searchKey = event.target.value.toLowerCase();
    }

    // Runs whenever the user selects a department
    handleDepartmentChange(event) {

        // Store the selected department
        this.selectedDepartment = event.detail.value;
    }

    // Returns jobs matching both the search and department filters
    get filteredJobs() {

        // If jobs have not loaded, return an empty list
        if (!this.jobs) {
            return [];
        }

        // Filter the jobs based on the selected conditions
        return this.jobs.filter(job => {

            // Check whether the job title contains the search text
            const matchesTitle = (job.Job_Title__c || '')
                .toLowerCase()
                .includes(this.searchKey);

            // Check whether the job belongs to the selected department
            // If All Departments is selected, show every department
            const matchesDepartment =
                !this.selectedDepartment ||
                job.Department__c === this.selectedDepartment;

            // A job must satisfy BOTH conditions to be displayed
            return matchesTitle && matchesDepartment;
        });
    }


    // Runs when a candidate clicks Apply for Job
    handleApplyClick(event) {

        // Get the ID of the job whose Apply button was clicked
        this.selectedJobId = event.currentTarget.dataset.jobId;

        // Reset previous candidate selection
        this.selectedCandidateId = '';

        // Display the application form
        this.showApplyForm = true;
    }


    // Runs when a candidate is selected from the dropdown
    handleCandidateChange(event) {

        // Store the selected Candidate record ID
        this.selectedCandidateId = event.detail.value;
    }


    // Runs when the candidate submits the application
    async handleSubmitApplication() {

        // Check whether a candidate has been selected
        if (!this.selectedCandidateId) {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Information',
                    message: 'Please select a candidate.',
                    variant: 'warning'
                })
            );

            return;
        }

        // Display loading state
        this.isSubmitting = true;

        try {

            // Call Apex to create the Application record
            await submitApplication({
                jobId: this.selectedJobId,
                candidateId: this.selectedCandidateId
            });

            // Refresh application history if this candidate is selected
            if (this.selectedStatusCandidateId === this.selectedCandidateId) {
                try {
                    const result = await getCandidateApplications({
                        candidateId: this.selectedStatusCandidateId
                    });
                    this.candidateApplications = result;
                } catch (error) {
                    console.error('Error refreshing application history:', error);
                }
            }

            // Show success notification
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Application Submitted',
                    message: 'Your job application was submitted successfully!',
                    variant: 'success'
                })
            );

            // Close the application form
            this.showApplyForm = false;

            // Reset selected candidate
            this.selectedCandidateId = '';

        } catch (error) {

            // Print the complete error in the browser console
            console.error('Application Submission Error:', error);

            // Extract the actual Salesforce error message
            const errorMessage =
                error.body?.message ||
                error.body?.pageErrors?.map(e => e.message).join(', ') ||
                error.message ||
                JSON.stringify(error);

            // Display the actual error to the user
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Application Failed',
                    message: errorMessage,
                    variant: 'error',
                    mode: 'sticky'
                })
            );

        } finally {

            // Stop loading
            this.isSubmitting = false;
        }
    }




    // Runs when a candidate is selected to view application status
    async handleStatusCandidateChange(event) {

        // Store the selected candidate ID
        this.selectedStatusCandidateId = event.detail.value;

        // Clear previously displayed applications
        this.candidateApplications = [];

        // Display the application history section
        this.showApplicationStatus = true;

        // Display loading spinner
        this.isLoadingApplications = true;

        try {

            // Fetch applications belonging to the selected candidate
            const result = await getCandidateApplications({
                candidateId: this.selectedStatusCandidateId
            });

            // Store the retrieved application records
            this.candidateApplications = result;

        } catch (error) {

            // Log the actual error
            console.error('Error fetching applications:', error);

            // Display error notification
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unable to fetch application history.',
                    variant: 'error'
                })
            );

        } finally {

            // Stop the loading spinner
            this.isLoadingApplications = false;
        }
    }


    get hasApplications() {
        return this.candidateApplications && this.candidateApplications.length > 0;
    }

    get hasNoApplications() {
        return !this.isLoadingApplications &&
            this.showApplicationStatus &&
            !this.hasApplications;
    }


    selectedJob;
    showJobDetails = false;

    handleViewDetails(event) {
        const jobId = event.currentTarget.dataset.jobId;

        this.selectedJob = this.jobs.find(job => job.Id === jobId);
        this.showJobDetails = true;
    }

    handleCloseDetails() {
        this.showJobDetails = false;
        this.selectedJob = null;
    }


}