
public with sharing class JobListingController {

    // Fetch open jobs using the current user's permissions
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

    // Fetch eligible candidates
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

    // Submit a new job application
    @AuraEnabled
    public static void submitApplication(Id jobId, Id candidateId) {

        if (jobId == null || candidateId == null) {
            throw new AuraHandledException(
                'Please select a Job and Candidate.'
            );
        }

        Application__c newApplication = new Application__c(
            Job__c = jobId,
            Candidate__c = candidateId,
            Application_Status__c = 'Applied'
        );

        try {
            insert as user newApplication;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Unable to submit application. Please check your access and the selected records.'
            );
        }
    }

    // Fetch applications belonging to a selected candidate
    @AuraEnabled
    public static List<Application__c> getCandidateApplications(
        Id candidateId
    ) {

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

    // Fetch all candidates visible to the current user
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
