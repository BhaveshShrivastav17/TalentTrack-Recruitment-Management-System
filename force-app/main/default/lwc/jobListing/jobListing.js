import { LightningElement, wire } from 'lwc';

import getAllCandidates from '@salesforce/apex/JobListingController.getAllCandidates';
import getOpenJobs from '@salesforce/apex/JobListingController.getOpenJobs';
import getEligibleCandidates from '@salesforce/apex/JobListingController.getEligibleCandidates';
import submitApplication from '@salesforce/apex/JobListingController.submitApplication';
import getCandidateApplications from '@salesforce/apex/JobListingController.getCandidateApplications';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobListing extends LightningElement {

    // ==========================================
    // JOB DATA
    // ==========================================

    jobs = [];
    error;
    isLoading = true;

    searchKey = '';
    selectedDepartment = '';

    departmentOptions = [
        { label: 'All Departments', value: '' },
        { label: 'IT', value: 'IT' },
        { label: 'HR', value: 'HR' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Sales', value: 'Sales' }
    ];

    // ==========================================
    // CANDIDATE DATA
    // ==========================================

    candidateOptions = [];
    statusCandidateOptions = [];

    selectedCandidateId = '';
    selectedStatusCandidateId = '';

    // ==========================================
    // APPLICATION DATA
    // ==========================================

    candidateApplications = [];

    showApplicationStatus = false;
    isLoadingApplications = false;
    isSubmitting = false;

    // ==========================================
    // JOB DETAILS AND APPLICATION FORM
    // ==========================================

    selectedJob = null;
    selectedJobId = '';

    showJobDetails = false;
    showApplyForm = false;

    // ==========================================
    // FETCH ELIGIBLE CANDIDATES
    // ==========================================

    @wire(getEligibleCandidates)
    wiredCandidates({ data, error }) {

        if (data) {
            this.candidateOptions = data.map(candidate => ({
                label: `${candidate.First_Name__c || ''} ${candidate.Last_Name__c || ''}`.trim(),
                value: candidate.Id
            }));

        } else if (error) {
            console.error('Error fetching eligible candidates:', error);
        }
    }

    // ==========================================
    // FETCH ALL CANDIDATES
    // ==========================================

    @wire(getAllCandidates)
    wiredAllCandidates({ data, error }) {

        if (data) {
            this.statusCandidateOptions = data.map(candidate => ({
                label: `${candidate.First_Name__c || ''} ${candidate.Last_Name__c || ''}`.trim(),
                value: candidate.Id
            }));

        } else if (error) {
            console.error('Error fetching all candidates:', error);
        }
    }

    // ==========================================
    // FETCH OPEN JOBS
    // ==========================================

    @wire(getOpenJobs)
    wiredJobs({ data, error }) {

        this.isLoading = false;

        if (data) {
            this.jobs = data;
            this.error = undefined;

        } else if (error) {
            this.jobs = [];
            this.error = error;

            console.error('Error fetching jobs:', error);
        }
    }

    // ==========================================
    // SEARCH JOBS
    // ==========================================

    handleSearch(event) {
        this.searchKey = (event.target.value || '').trim().toLowerCase();
    }

    // ==========================================
    // FILTER BY DEPARTMENT
    // ==========================================

    handleDepartmentChange(event) {
        this.selectedDepartment = event.detail.value;
    }

    // ==========================================
    // FILTERED JOBS
    // ==========================================

    get filteredJobs() {

        if (!this.jobs) {
            return [];
        }

        return this.jobs.filter(job => {

            const jobTitle = (job.Job_Title__c || '').toLowerCase();

            const matchesTitle = jobTitle.includes(this.searchKey);

            const matchesDepartment =
                !this.selectedDepartment ||
                job.Department__c === this.selectedDepartment;

            return matchesTitle && matchesDepartment;
        });
    }

    get hasJobs() {
        return !this.isLoading &&
            !this.error &&
            this.filteredJobs.length > 0;
    }

    get hasNoOpenJobs() {
        return !this.isLoading &&
            !this.error &&
            this.jobs.length === 0;
    }

    get hasNoMatchingJobs() {
        return !this.isLoading &&
            !this.error &&
            this.jobs.length > 0 &&
            this.filteredJobs.length === 0;
    }

    get hasJobError() {
        return !this.isLoading && !!this.error;
    }

    // ==========================================
    // VIEW JOB DETAILS
    // ==========================================

    handleViewDetails(event) {

        const jobId = event.currentTarget.dataset.jobId;

        this.selectedJob = this.jobs.find(job => job.Id === jobId);

        if (this.selectedJob) {
            this.showJobDetails = true;
            this.showApplyForm = false;
            this.selectedJobId = '';
            this.selectedCandidateId = '';
        }
    }

    handleCloseDetails() {
        this.showJobDetails = false;
        this.selectedJob = null;
    }

    // ==========================================
    // APPLY FOR JOB
    // ==========================================

    handleApplyClick(event) {

        const jobId = event.currentTarget.dataset.jobId;

        const job = this.jobs.find(item => item.Id === jobId);

        if (!job) {
            this.showToast(
                'Job Not Found',
                'The selected job could not be found. Please refresh the page and try again.',
                'error'
            );
            return;
        }

        this.selectedJobId = jobId;
        this.selectedJob = job;
        this.selectedCandidateId = '';

        this.showJobDetails = false;
        this.showApplyForm = true;
    }

    // ==========================================
    // CANCEL APPLICATION FORM
    // ==========================================

    handleCancelApplication() {

        if (this.isSubmitting) {
            return;
        }

        this.showApplyForm = false;
        this.selectedCandidateId = '';
        this.selectedJobId = '';
        this.selectedJob = null;
    }

    // ==========================================
    // SELECT CANDIDATE
    // ==========================================

    handleCandidateChange(event) {
        this.selectedCandidateId = event.detail.value;
    }

    // ==========================================
    // SUBMIT JOB APPLICATION
    // ==========================================

    async handleSubmitApplication() {

        if (!this.selectedJobId) {
            this.showToast(
                'Missing Information',
                'Please select a job before applying.',
                'warning'
            );
            return;
        }

        if (!this.selectedCandidateId) {
            this.showToast(
                'Missing Information',
                'Please select a candidate.',
                'warning'
            );
            return;
        }

        this.isSubmitting = true;

        const candidateId = this.selectedCandidateId;

        try {

            // Existing Apex operation and parameter names are unchanged.
            await submitApplication({
                jobId: this.selectedJobId,
                candidateId: candidateId
            });

            // Refresh application history if this candidate
            // is already selected in the tracker.
            if (this.selectedStatusCandidateId === candidateId) {
                await this.loadCandidateApplications(
                    candidateId,
                    false
                );
            }

            this.showToast(
                'Application Submitted',
                'Your job application was submitted successfully!',
                'success'
            );

            this.showApplyForm = false;
            this.selectedCandidateId = '';
            this.selectedJobId = '';
            this.selectedJob = null;

        } catch (error) {

            console.error('Application submission error:', error);

            this.showToast(
                'Application Failed',
                this.getErrorMessage(error),
                'error'
            );

        } finally {
            this.isSubmitting = false;
        }
    }

    // ==========================================
    // SELECT CANDIDATE TO TRACK APPLICATIONS
    // ==========================================

    async handleStatusCandidateChange(event) {

        this.selectedStatusCandidateId = event.detail.value;

        this.candidateApplications = [];

        if (!this.selectedStatusCandidateId) {
            this.showApplicationStatus = false;
            return;
        }

        this.showApplicationStatus = true;

        await this.loadCandidateApplications(
            this.selectedStatusCandidateId
        );
    }

    // ==========================================
    // LOAD APPLICATION HISTORY
    // ==========================================

    async loadCandidateApplications(candidateId, showErrorToast = true) {

        this.isLoadingApplications = true;

        try {

            // Existing Apex operation and parameter name are unchanged.
            const result = await getCandidateApplications({
                candidateId: candidateId
            });

            this.candidateApplications = result || [];

        } catch (error) {

            console.error('Error fetching application history:', error);

            this.candidateApplications = [];

            if (showErrorToast) {
                this.showToast(
                    'Unable to Load Applications',
                    this.getErrorMessage(error),
                    'error'
                );
            }

        } finally {
            this.isLoadingApplications = false;
        }
    }

    // ==========================================
    // APPLICATION HISTORY GETTERS
    // ==========================================

    get hasApplications() {
        return this.candidateApplications.length > 0;
    }

    get hasNoApplications() {
        return !this.isLoadingApplications &&
            this.showApplicationStatus &&
            !this.hasApplications;
    }

    // ==========================================
    // TOAST NOTIFICATIONS
    // ==========================================

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissible'
            })
        );
    }

    // ==========================================
    // ERROR MESSAGE HANDLING
    // ==========================================

    getErrorMessage(error) {

        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.body?.pageErrors?.length) {
            return error.body.pageErrors
                .map(item => item.message)
                .join(', ');
        }

        if (error?.message) {
            return error.message;
        }

        return 'An unexpected error occurred. Please try again.';
    }
}