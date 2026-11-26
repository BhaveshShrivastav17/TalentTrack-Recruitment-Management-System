
public with sharing class JobListingController {

    // Fetch all Open Jobs
    @AuraEnabled(cacheable=true)
    public static List<Job__c> getOpenJobs() {
        return [
            SELECT Id,
                   Name,
                   Job_Title__c,
                   Department__c,
                   Location__c,
                   Salary__c,
                   Job_Type__c,
                   Experience_Required__c,
                   Job_Description__c,
                   Application_Deadline__c
            FROM Job__c
            WHERE Job_Status__c = 'Open'
            WITH USER_MODE
            ORDER BY Posted_Date__c DESC
        ];
    }

    // Fetch Candidates who are eligible to apply
    @AuraEnabled(cacheable=true)
    public static List<Candidate__c> getEligibleCandidates() {
        return [
            SELECT Id,
                   First_Name__c,
                   Last_Name__c
            FROM Candidate__c
            WHERE Candidate_Status__c = 'Active'
            WITH USER_MODE
            ORDER BY First_Name__c
        ];
    }

    // Create a new Job Application
    @AuraEnabled
    public static void submitApplication(Id jobId, Id candidateId) {

        if (jobId == null || candidateId == null) {
            throw new AuraHandledException(
                'Please select a Job and Candidate.'
            );
        }

        // Check for an existing application
        List<Application__c> existingApplications = [
            SELECT Id
            FROM Application__c
            WHERE Job__c = :jobId
            AND Candidate__c = :candidateId
            WITH USER_MODE
            LIMIT 1
        ];

        if (!existingApplications.isEmpty()) {
            throw new AuraHandledException(
                'This candidate has already applied for this job.'
            );
        }

        // Create the Application record
        Application__c newApplication = new Application__c();
        newApplication.Job__c = jobId;
        newApplication.Candidate__c = candidateId;
        newApplication.Application_Status__c = 'Applied';

        // Insert using the current user's permissions
        insert as user newApplication;
    }

    // Fetch all applications belonging to a selected candidate
    @AuraEnabled
    public static List<Application__c> getCandidateApplications(Id candidateId) {

        if (candidateId == null) {
            return new List<Application__c>();
        }

        return [
            SELECT Id,
                   Name,
                   Application_Status__c,
                   Application_Date__c,
                   Job__r.Job_Title__c
            FROM Application__c
            WHERE Candidate__c = :candidateId
            WITH USER_MODE
            ORDER BY Application_Date__c DESC
        ];
    }

    // Fetch all Candidates
    @AuraEnabled(cacheable=true)
    public static List<Candidate__c> getAllCandidates() {
        return [
            SELECT Id,
                   First_Name__c,
                   Last_Name__c
            FROM Candidate__c
            WITH USER_MODE
            ORDER BY First_Name__c
        ];
    }
}
